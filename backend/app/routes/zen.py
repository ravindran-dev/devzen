from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.routes.auth import get_current_user
from app.services.zen_score_engine import ZenScoreEngine
import datetime

router = APIRouter()

@router.get("/score", response_model=schemas.ZenScoreResponse)
def get_zen_score(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get the current user's Zen Score with full breakdown."""
    profile = db.query(models.Profile).filter(models.Profile.user_id == current_user.id).first()
    if not profile:
        return schemas.ZenScoreResponse(
            total_score=0.0,
            rank="Beginner",
            trend="stable",
            breakdown=schemas.ZenScoreBreakdown()
        )

    breakdown_data = profile.zen_breakdown or {}
    breakdown = schemas.ZenScoreBreakdown(
        profile_completeness=breakdown_data.get("profile_completeness", 0.0),
        github_activity=breakdown_data.get("github_activity", 0.0),
        repository_quality=breakdown_data.get("repository_quality", 0.0),
        skill_diversity=breakdown_data.get("skill_diversity", 0.0),
        resume_completeness=breakdown_data.get("resume_completeness", 0.0),
        achievement_count=breakdown_data.get("achievement_count", 0.0),
        contribution_frequency=breakdown_data.get("contribution_frequency", 0.0),
    )

    return schemas.ZenScoreResponse(
        total_score=profile.zen_score or 0.0,
        rank=profile.zen_rank or "Beginner",
        trend=profile.zen_trend or "stable",
        breakdown=breakdown,
        last_calculated=profile.updated_at
    )

@router.post("/recalculate", response_model=schemas.ZenScoreResponse)
def recalculate_zen_score(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Force recalculate the Zen Score for the current user."""
    profile = db.query(models.Profile).filter(models.Profile.user_id == current_user.id).first()
    if not profile:
        return schemas.ZenScoreResponse(
            total_score=0.0,
            rank="Beginner",
            trend="stable",
            breakdown=schemas.ZenScoreBreakdown()
        )

    result = ZenScoreEngine(db).calculate_and_save(profile.id)

    breakdown_data = result.get("breakdown", {})
    breakdown = schemas.ZenScoreBreakdown(
        profile_completeness=breakdown_data.get("profile_completeness", 0.0),
        github_activity=breakdown_data.get("github_activity", 0.0),
        repository_quality=breakdown_data.get("repository_quality", 0.0),
        skill_diversity=breakdown_data.get("skill_diversity", 0.0),
        resume_completeness=breakdown_data.get("resume_completeness", 0.0),
        achievement_count=breakdown_data.get("achievement_count", 0.0),
        contribution_frequency=breakdown_data.get("contribution_frequency", 0.0),
    )

    return schemas.ZenScoreResponse(
        total_score=result.get("total_score", 0.0),
        rank=result.get("rank", "Beginner"),
        trend=result.get("trend", "stable"),
        breakdown=breakdown,
        last_calculated=datetime.datetime.utcnow()
    )
