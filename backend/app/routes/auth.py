from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from jose import jwt, JWTError
import bcrypt
from datetime import datetime, timedelta
from typing import Optional
from app.database import get_db
from app import models, schemas
from app.config import settings

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

# ─── Password & JWT Helpers ───────────────────────────────────────────────────

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> models.User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        sub = payload.get("sub")
        if sub is None:
            raise credentials_exception
        user_id = int(sub)
    except (JWTError, ValueError):
        raise credentials_exception

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise credentials_exception
    return user

# ─── Login ────────────────────────────────────────────────────────────────────

@router.post("/login", response_model=schemas.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect email or password")

    access_token = create_access_token(data={"sub": str(user.id)})

    db_session = models.Session(
        user_id=user.id,
        token=access_token,
        expires_at=datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    db.add(db_session)
    db.commit()

    return {"access_token": access_token, "token_type": "bearer"}

# ─── Register (multipart: name + email + password + github_username + resume) ──

@router.post("/register", response_model=schemas.RegisterResponse)
async def register(
    full_name: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    confirm_password: str = Form(...),
    github_username: str = Form(...),
    resume: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # Validation
    if password != confirm_password:
        raise HTTPException(status_code=400, detail="Passwords do not match")

    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    if db.query(models.User).filter(models.User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    if not github_username.strip():
        raise HTTPException(status_code=400, detail="GitHub username is required")

    allowed_types = ["application/pdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "text/plain"]
    if resume.content_type not in allowed_types and not resume.filename.endswith((".pdf", ".docx", ".txt")):
        raise HTTPException(status_code=400, detail="Resume must be PDF, DOCX, or TXT")

    # Create user
    hashed_pwd = get_password_hash(password)
    db_user = models.User(
        email=email,
        hashed_password=hashed_pwd,
        full_name=full_name,
        github_username=github_username.strip().lstrip("@")
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Initialize settings, preferences, and profile
    db.add(models.ThemePreferences(user_id=db_user.id))
    db.add(models.SecuritySettings(user_id=db_user.id))
    db_profile = models.Profile(user_id=db_user.id, fullName=full_name)
    db.add(db_profile)
    db.commit()

    # Generate JWT token
    access_token = create_access_token(data={"sub": str(db_user.id)})
    db_session = models.Session(
        user_id=db_user.id,
        token=access_token,
        expires_at=datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    db.add(db_session)
    db.commit()

    # Trigger Profile Intelligence Pipeline (resume + GitHub) in background
    try:
        resume_bytes = await resume.read()
        from app.services.resume_parser import ResumeParserService
        ResumeParserService(db).parse_and_initialize_profile(db_user.id, resume.filename, resume_bytes)
    except Exception as e:
        import logging
        logging.getLogger(__name__).error(f"Resume parsing failed during registration: {e}")

    # Trigger GitHub sync
    try:
        from app.services.github_sync import GitHubSyncService
        GitHubSyncService(db).connect_github(db_user.id, github_username.strip().lstrip("@"))
    except Exception as e:
        import logging
        logging.getLogger(__name__).error(f"GitHub sync failed during registration: {e}")

    return schemas.RegisterResponse(
        access_token=access_token,
        token_type="bearer",
        user=schemas.UserResponse(
            id=db_user.id,
            email=db_user.email,
            full_name=db_user.full_name,
            github_username=db_user.github_username,
            is_active=db_user.is_active
        ),
        profile_status="ready"
    )

# ─── Current User ─────────────────────────────────────────────────────────────

@router.get("/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user

# ─── Simple Register (JSON, no file — for testing) ────────────────────────────

@router.post("/register-simple", response_model=schemas.Token)
def register_simple(user_in: schemas.UserCreate, db: Session = Depends(get_db)):
    """Simple registration without resume — for testing only."""
    if db.query(models.User).filter(models.User.email == user_in.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pwd = get_password_hash(user_in.password)
    db_user = models.User(
        email=user_in.email,
        hashed_password=hashed_pwd,
        full_name=user_in.full_name or user_in.email.split("@")[0],
        github_username=user_in.github_username or ""
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    db.add(models.ThemePreferences(user_id=db_user.id))
    db.add(models.SecuritySettings(user_id=db_user.id))
    db.add(models.Profile(user_id=db_user.id, fullName=db_user.full_name))
    db.commit()

    access_token = create_access_token(data={"sub": str(db_user.id)})
    return {"access_token": access_token, "token_type": "bearer"}

# ─── Password & Security ──────────────────────────────────────────────────────

@router.post("/change-password")
def change_password(
    old_password: str,
    new_password: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not verify_password(old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Invalid old password")
    current_user.hashed_password = get_password_hash(new_password)
    db.commit()
    return {"status": "password updated"}

@router.get("/security-settings", response_model=schemas.SecuritySettingsResponse)
def get_security_settings(current_user: models.User = Depends(get_current_user)):
    return current_user.security_settings

@router.put("/security-settings", response_model=schemas.SecuritySettingsResponse)
def update_security_settings(
    settings_in: schemas.SecuritySettingsUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_settings = current_user.security_settings
    db_settings.two_factor_enabled = settings_in.two_factor_enabled
    db_settings.privacy_controls = settings_in.privacy_controls
    db.commit()
    db.refresh(db_settings)
    return db_settings

@router.get("/sessions")
def get_active_sessions(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(models.Session).filter(
        models.Session.user_id == current_user.id,
        models.Session.is_active == True,
        models.Session.expires_at > datetime.utcnow()
    ).all()

@router.post("/sessions/terminate/{session_id}")
def terminate_session(
    session_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    sess = db.query(models.Session).filter(
        models.Session.id == session_id,
        models.Session.user_id == current_user.id
    ).first()
    if not sess:
        raise HTTPException(status_code=404, detail="Session not found")
    sess.is_active = False
    db.commit()
    return {"status": "session terminated"}

@router.delete("/delete-account")
def delete_account(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    db.delete(current_user)
    db.commit()
    return {"status": "account deleted"}
