from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app import models, schemas
from app.routes.auth import get_current_user
# We will import the sync service which triggers background jobs
from app.services.github_sync import GitHubSyncService

router = APIRouter()

@router.post("/connect", response_model=schemas.GitHubAccountResponse)
def connect_github_account(username: str, access_token: str = "mock_oauth_token", current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Connect and initialize GitHubAccount in DB
    sync_service = GitHubSyncService(db)
    account = sync_service.connect_github(
        user_id=current_user.id,
        username=username,
        access_token=access_token
    )
    return account

@router.get("/account", response_model=schemas.GitHubAccountResponse)
def get_connected_account(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    account = db.query(models.GitHubAccount).filter(models.GitHubAccount.user_id == current_user.id).first()
    if not account:
        raise HTTPException(status_code=404, detail="GitHub account not connected")
    return account

@router.post("/sync")
def trigger_github_sync(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    account = db.query(models.GitHubAccount).filter(models.GitHubAccount.user_id == current_user.id).first()
    if not account:
        raise HTTPException(status_code=404, detail="GitHub account not connected. Register with a GitHub username first.")

    sync_service = GitHubSyncService(db)
    sync_service.full_sync(account.id)

    return {
        "status": "sync_complete",
        "username": account.username,
        "repos_count": len(account.repositories),
        "last_sync": account.last_sync.isoformat() if account.last_sync else None
    }

@router.get("/repositories", response_model=List[schemas.RepositoryResponse])
def get_repositories(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    account = db.query(models.GitHubAccount).filter(models.GitHubAccount.user_id == current_user.id).first()
    if not account:
        raise HTTPException(status_code=404, detail="GitHub account not connected")
    return account.repositories

@router.post("/disconnect")
def disconnect_github(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    account = db.query(models.GitHubAccount).filter(models.GitHubAccount.user_id == current_user.id).first()
    if not account:
        raise HTTPException(status_code=404, detail="GitHub account not connected")
    
    # Clean up connected details
    db.delete(account)
    db.commit()
    return {"status": "GitHub account disconnected and repository cards purged"}
