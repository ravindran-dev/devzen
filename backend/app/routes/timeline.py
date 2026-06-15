from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app import models, schemas
from app.routes.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[schemas.TimelineEventResponse])
def get_timeline_events(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    events = db.query(models.TimelineEvent).filter(
        models.TimelineEvent.profile_id == current_user.profile.id
    ).order_by(models.TimelineEvent.created_at.desc()).all()
    return events

@router.post("/event", response_model=schemas.TimelineEventResponse)
def create_manual_event(event_type: str, title: str, description: Optional[str] = None, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_event = models.TimelineEvent(
        profile_id=current_user.profile.id,
        event_type=event_type,
        title=title,
        description=description
    )
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return db_event
