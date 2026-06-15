from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app import models, schemas
from app.routes.auth import get_current_user
from app.services.zen_score_engine import ZenScoreEngine

router = APIRouter()

# ─── Theme ────────────────────────────────────────────────────────────────────

@router.get("/theme", response_model=schemas.ThemePreferencesResponse)
def get_theme_preferences(current_user: models.User = Depends(get_current_user)):
    return current_user.theme_preferences

@router.put("/theme", response_model=schemas.ThemePreferencesResponse)
def update_theme_preferences(
    theme_in: schemas.ThemePreferencesUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    t = current_user.theme_preferences
    t.theme_mode = theme_in.theme_mode
    t.accent_color = theme_in.accent_color
    t.glassmorphism_enabled = theme_in.glassmorphism_enabled
    t.typography_preference = theme_in.typography_preference
    db.commit()
    db.refresh(t)
    return t

# ─── Profile ──────────────────────────────────────────────────────────────────

@router.get("/me", response_model=schemas.ProfileResponse)
def get_profile(current_user: models.User = Depends(get_current_user)):
    if not current_user.profile:
        raise HTTPException(status_code=404, detail="Profile not initialized")
    return current_user.profile

@router.put("/me", response_model=schemas.ProfileResponse)
def update_profile(
    profile_in: schemas.ProfileUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    p = current_user.profile
    if profile_in.fullName is not None:
        p.fullName = profile_in.fullName
    if profile_in.headline is not None:
        p.headline = profile_in.headline
    if profile_in.bio is not None:
        p.bio = profile_in.bio
    if profile_in.technical_summary is not None:
        p.technical_summary = profile_in.technical_summary
    if profile_in.career_overview is not None:
        p.career_overview = profile_in.career_overview
    if profile_in.portfolio_summary is not None:
        p.portfolio_summary = profile_in.portfolio_summary
    p.profile_visibility = profile_in.profile_visibility
    db.commit()
    db.refresh(p)
    # Recalculate Zen Score on every profile update
    ZenScoreEngine(db).calculate_and_save(p.id)
    db.refresh(p)
    return p

# ─── Resume Upload ────────────────────────────────────────────────────────────

@router.post("/resume/upload", response_model=schemas.ResumeUploadResponse)
async def upload_resume(
    resume: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload/replace resume — triggers AI parsing and Zen Score recalculation."""
    allowed_ext = [".pdf", ".docx", ".txt"]
    if not any(resume.filename.lower().endswith(ext) for ext in allowed_ext):
        raise HTTPException(status_code=400, detail="Only PDF, DOCX, or TXT files are accepted.")

    file_bytes = await resume.read()
    if len(file_bytes) > 10 * 1024 * 1024:  # 10MB limit
        raise HTTPException(status_code=400, detail="File size exceeds 10MB limit.")

    from app.services.resume_parser import ResumeParserService
    result = ResumeParserService(db).parse_and_initialize_profile(
        current_user.id, resume.filename, file_bytes
    )
    return schemas.ResumeUploadResponse(**result)

# ─── Skills ───────────────────────────────────────────────────────────────────

@router.get("/skills", response_model=List[schemas.SkillResponse])
def get_skills(current_user: models.User = Depends(get_current_user)):
    return current_user.profile.skills

@router.post("/skills", response_model=schemas.SkillResponse)
def create_skill(
    skill_in: schemas.SkillCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_skill = models.Skill(**skill_in.dict(), profile_id=current_user.profile.id)
    db.add(db_skill)
    db.commit()
    db.refresh(db_skill)
    ZenScoreEngine(db).calculate_and_save(current_user.profile.id)
    return db_skill

@router.put("/skills/{skill_id}", response_model=schemas.SkillResponse)
def update_skill(
    skill_id: int,
    skill_in: schemas.SkillUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_skill = db.query(models.Skill).filter(
        models.Skill.id == skill_id,
        models.Skill.profile_id == current_user.profile.id
    ).first()
    if not db_skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    for key, value in skill_in.dict(exclude_unset=True).items():
        setattr(db_skill, key, value)
    db.commit()
    db.refresh(db_skill)
    return db_skill

@router.delete("/skills/{skill_id}")
def delete_skill(
    skill_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_skill = db.query(models.Skill).filter(
        models.Skill.id == skill_id,
        models.Skill.profile_id == current_user.profile.id
    ).first()
    if not db_skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    db.delete(db_skill)
    db.commit()
    return {"status": "skill deleted"}

# ─── Education ────────────────────────────────────────────────────────────────

@router.get("/education", response_model=List[schemas.EducationResponse])
def get_education(current_user: models.User = Depends(get_current_user)):
    return current_user.profile.educations

@router.post("/education", response_model=schemas.EducationResponse)
def create_education(
    edu_in: schemas.EducationCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_edu = models.Education(**edu_in.dict(), profile_id=current_user.profile.id)
    db.add(db_edu)
    db.commit()
    db.refresh(db_edu)
    ZenScoreEngine(db).calculate_and_save(current_user.profile.id)
    return db_edu

@router.put("/education/{edu_id}", response_model=schemas.EducationResponse)
def update_education(
    edu_id: int,
    edu_in: schemas.EducationUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_edu = db.query(models.Education).filter(
        models.Education.id == edu_id,
        models.Education.profile_id == current_user.profile.id
    ).first()
    if not db_edu:
        raise HTTPException(status_code=404, detail="Education record not found")
    for key, value in edu_in.dict(exclude_unset=True).items():
        setattr(db_edu, key, value)
    db.commit()
    db.refresh(db_edu)
    return db_edu

@router.delete("/education/{edu_id}")
def delete_education(
    edu_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_edu = db.query(models.Education).filter(
        models.Education.id == edu_id,
        models.Education.profile_id == current_user.profile.id
    ).first()
    if not db_edu:
        raise HTTPException(status_code=404, detail="Education record not found")
    db.delete(db_edu)
    db.commit()
    return {"status": "education record deleted"}

# ─── Experience ───────────────────────────────────────────────────────────────

@router.get("/experience", response_model=List[schemas.ExperienceResponse])
def get_experiences(current_user: models.User = Depends(get_current_user)):
    return current_user.profile.experiences

@router.post("/experience", response_model=schemas.ExperienceResponse)
def create_experience(
    exp_in: schemas.ExperienceCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_exp = models.Experience(**exp_in.dict(), profile_id=current_user.profile.id)
    db.add(db_exp)
    db.commit()
    db.refresh(db_exp)
    ZenScoreEngine(db).calculate_and_save(current_user.profile.id)
    return db_exp

@router.put("/experience/{exp_id}", response_model=schemas.ExperienceResponse)
def update_experience(
    exp_id: int,
    exp_in: schemas.ExperienceUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_exp = db.query(models.Experience).filter(
        models.Experience.id == exp_id,
        models.Experience.profile_id == current_user.profile.id
    ).first()
    if not db_exp:
        raise HTTPException(status_code=404, detail="Experience record not found")
    for key, value in exp_in.dict(exclude_unset=True).items():
        setattr(db_exp, key, value)
    db.commit()
    db.refresh(db_exp)
    return db_exp

@router.delete("/experience/{exp_id}")
def delete_experience(
    exp_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_exp = db.query(models.Experience).filter(
        models.Experience.id == exp_id,
        models.Experience.profile_id == current_user.profile.id
    ).first()
    if not db_exp:
        raise HTTPException(status_code=404, detail="Experience record not found")
    db.delete(db_exp)
    db.commit()
    return {"status": "experience record deleted"}

# ─── Achievements ─────────────────────────────────────────────────────────────

@router.get("/achievements", response_model=List[schemas.AchievementResponse])
def get_achievements(current_user: models.User = Depends(get_current_user)):
    return current_user.profile.achievements

@router.post("/achievements", response_model=schemas.AchievementResponse)
def create_achievement(
    ach_in: schemas.AchievementCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_ach = models.Achievement(**ach_in.dict(), profile_id=current_user.profile.id)
    db.add(db_ach)
    db.commit()
    db.refresh(db_ach)
    ZenScoreEngine(db).calculate_and_save(current_user.profile.id)
    return db_ach

# ─── Certifications ───────────────────────────────────────────────────────────

@router.get("/certifications", response_model=List[schemas.CertificationResponse])
def get_certifications(current_user: models.User = Depends(get_current_user)):
    return current_user.profile.certifications

@router.post("/certifications", response_model=schemas.CertificationResponse)
def create_certification(
    cert_in: schemas.CertificationCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_cert = models.Certification(**cert_in.dict(), profile_id=current_user.profile.id)
    db.add(db_cert)
    db.commit()
    db.refresh(db_cert)
    return db_cert

# ─── Projects ─────────────────────────────────────────────────────────────────

@router.get("/projects", response_model=List[schemas.ProjectResponse])
def get_projects(current_user: models.User = Depends(get_current_user)):
    return current_user.profile.projects

@router.post("/projects", response_model=schemas.ProjectResponse)
def create_project(
    proj_in: schemas.ProjectCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_proj = models.Project(**proj_in.dict(), profile_id=current_user.profile.id)
    db.add(db_proj)
    db.commit()
    db.refresh(db_proj)
    return db_proj

@router.put("/projects/{proj_id}", response_model=schemas.ProjectResponse)
def update_project(
    proj_id: int,
    proj_in: schemas.ProjectUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_proj = db.query(models.Project).filter(
        models.Project.id == proj_id,
        models.Project.profile_id == current_user.profile.id
    ).first()
    if not db_proj:
        raise HTTPException(status_code=404, detail="Project not found")
    for key, value in proj_in.dict(exclude_unset=True).items():
        setattr(db_proj, key, value)
    db.commit()
    db.refresh(db_proj)
    return db_proj

@router.delete("/projects/{proj_id}")
def delete_project(
    proj_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_proj = db.query(models.Project).filter(
        models.Project.id == proj_id,
        models.Project.profile_id == current_user.profile.id
    ).first()
    if not db_proj:
        raise HTTPException(status_code=404, detail="Project not found")
    db.delete(db_proj)
    db.commit()
    return {"status": "project deleted"}
