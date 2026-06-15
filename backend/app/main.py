from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base

# Import models to register them before schema creation
from app import models

# Auto-create all tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import routes
from app.routes import auth, profile, github, timeline, ai, zen

app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["Authentication"])
app.include_router(profile.router, prefix=f"{settings.API_V1_STR}/profile", tags=["Profile Management"])
app.include_router(github.router, prefix=f"{settings.API_V1_STR}/github", tags=["GitHub Engine"])
app.include_router(timeline.router, prefix=f"{settings.API_V1_STR}/timeline", tags=["Developer Timeline"])
app.include_router(ai.router, prefix=f"{settings.API_V1_STR}/ai", tags=["AI Operations"])
app.include_router(zen.router, prefix=f"{settings.API_V1_STR}/zen", tags=["Zen Score Engine"])

@app.get("/")
def read_root():
    return {
        "status": "online",
        "app": settings.APP_NAME,
        "version": "2.0.0",
        "description": "AI-powered Developer Identity Workspace",
        "api_docs": "/docs"
    }
