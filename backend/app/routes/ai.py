from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from app.database import get_db
from app import models, schemas
from app.routes.auth import get_current_user
from app.services.ai_assistant import AIAssistantService

router = APIRouter()

# ─── Main Chat Endpoint ───────────────────────────────────────────────────────

@router.post("/chat", response_model=schemas.AIChatResponse)
def ai_chat(
    req: schemas.AIChatRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Chat with DevZen AI — context-aware based on your profile & GitHub data."""
    assistant = AIAssistantService(db)
    reply = assistant.chat(current_user.id, req.message)
    return schemas.AIChatResponse(reply=reply)

# ─── AI Suggestions ───────────────────────────────────────────────────────────

@router.get("/suggestions", response_model=List[Dict[str, Any]])
def get_ai_suggestions(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get personalized AI-generated improvement suggestions for the user's profile."""
    assistant = AIAssistantService(db)
    return assistant.get_suggestions(current_user.id)

# ─── Portfolio Generator ──────────────────────────────────────────────────────

@router.post("/generate-portfolio", response_model=Dict[str, Any])
def generate_portfolio(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generate portfolio-ready content from the user's profile data."""
    assistant = AIAssistantService(db)
    return assistant.generate_portfolio_content(current_user.id)

# ─── Resume Parse (alternate endpoint) ───────────────────────────────────────

@router.post("/parse-resume", response_model=schemas.ResumeUploadResponse)
async def parse_resume_upload(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Parse resume — also accessible via /profile/resume/upload"""
    if not any(file.filename.endswith(ext) for ext in [".pdf", ".docx", ".txt"]):
        raise HTTPException(status_code=400, detail="Only PDF, DOCX, and TXT files are supported")

    contents = await file.read()
    from app.services.resume_parser import ResumeParserService
    result = ResumeParserService(db).parse_and_initialize_profile(
        user_id=current_user.id,
        filename=file.filename,
        file_bytes=contents
    )
    return schemas.ResumeUploadResponse(**result)

# ─── AI Briefing ──────────────────────────────────────────────────────────────

@router.get("/briefing", response_model=schemas.AISummaryResponse)
def get_latest_briefing(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get the latest AI profile briefing/summary."""
    briefing = db.query(models.AISummary).filter(
        models.AISummary.profile_id == current_user.profile.id
    ).order_by(models.AISummary.created_at.desc()).first()

    if not briefing:
        briefing = models.AISummary(
            profile_id=current_user.profile.id,
            last_briefing="Upload your resume and connect GitHub to get your first AI briefing."
        )
        db.add(briefing)
        db.commit()
        db.refresh(briefing)

    return briefing

# ─── Legacy endpoint alias (for backward compatibility) ───────────────────────

@router.post("/assistant/chat", response_model=schemas.AIChatResponse)
def ai_assistant_chat_legacy(
    req: schemas.AIChatRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Legacy endpoint — use /ai/chat instead."""
    assistant = AIAssistantService(db)
    reply = assistant.chat(current_user.id, req.message)
    return schemas.AIChatResponse(reply=reply)
