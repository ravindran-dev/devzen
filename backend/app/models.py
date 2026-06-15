import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, ForeignKey, JSON, Text
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    github_username = Column(String, nullable=True, index=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    profile = relationship("Profile", uselist=False, back_populates="user", cascade="all, delete-orphan")
    sessions = relationship("Session", back_populates="user", cascade="all, delete-orphan")
    security_settings = relationship("SecuritySettings", uselist=False, back_populates="user", cascade="all, delete-orphan")
    theme_preferences = relationship("ThemePreferences", uselist=False, back_populates="user", cascade="all, delete-orphan")
    github_account = relationship("GitHubAccount", uselist=False, back_populates="user", cascade="all, delete-orphan")

class Session(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token = Column(String, unique=True, index=True, nullable=False)
    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)

    user = relationship("User", back_populates="sessions")

class SecuritySettings(Base):
    __tablename__ = "security_settings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    two_factor_enabled = Column(Boolean, default=False)
    two_factor_secret = Column(String, nullable=True)
    privacy_controls = Column(JSON, default=lambda: {"show_email": True, "show_phone": False, "public_profile": True})
    data_export_requested = Column(Boolean, default=False)
    backup_codes = Column(JSON, default=list)

    user = relationship("User", back_populates="security_settings")

class ThemePreferences(Base):
    __tablename__ = "theme_preferences"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    theme_mode = Column(String, default="dark")  # light, dark, system
    accent_color = Column(String, default="#3A86FF")
    glassmorphism_enabled = Column(Boolean, default=True)
    typography_preference = Column(String, default="Outfit")

    user = relationship("User", back_populates="theme_preferences")

class Profile(Base):
    __tablename__ = "profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    fullName = Column(String, nullable=False)
    headline = Column(String, nullable=True)
    bio = Column(String, nullable=True)
    technical_summary = Column(String, nullable=True)
    career_overview = Column(String, nullable=True)
    portfolio_summary = Column(String, nullable=True)
    profile_visibility = Column(Boolean, default=True)

    # Avatar from GitHub or uploaded
    avatar_url = Column(String, nullable=True)

    # Raw resume text for AI context
    resume_raw_text = Column(Text, nullable=True)

    # GitHub raw data snapshot for AI context
    github_raw_data = Column(JSON, default=dict)

    # Dynamic Zen Score
    zen_score = Column(Float, default=0.0)
    zen_rank = Column(String, default="Beginner")   # Beginner, Rising, Proficient, Expert, Master
    zen_breakdown = Column(JSON, default=dict)        # Score breakdown by category
    zen_trend = Column(String, default="stable")     # up, down, stable

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="profile")
    skills = relationship("Skill", back_populates="profile", cascade="all, delete-orphan")
    educations = relationship("Education", back_populates="profile", cascade="all, delete-orphan")
    experiences = relationship("Experience", back_populates="profile", cascade="all, delete-orphan")
    achievements = relationship("Achievement", back_populates="profile", cascade="all, delete-orphan")
    certifications = relationship("Certification", back_populates="profile", cascade="all, delete-orphan")
    projects = relationship("Project", back_populates="profile", cascade="all, delete-orphan")
    timeline_events = relationship("TimelineEvent", back_populates="profile", cascade="all, delete-orphan")
    ai_summaries = relationship("AISummary", back_populates="profile", cascade="all, delete-orphan")

class Skill(Base):
    __tablename__ = "skills"

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(Integer, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    name = Column(String, nullable=False)
    category = Column(String, nullable=True)  # e.g., Languages, Frameworks, Cloud
    proficiency_level = Column(String, default="Intermediate")  # Beginner, Intermediate, Expert
    source = Column(String, default="Manual")  # Resume, GitHub, Manual, AI-Suggested
    is_visible = Column(Boolean, default=True)
    order = Column(Integer, default=0)

    profile = relationship("Profile", back_populates="skills")

class Education(Base):
    __tablename__ = "educations"

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(Integer, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    institution = Column(String, nullable=False)
    degree = Column(String, nullable=False)
    department = Column(String, nullable=True)
    cgpa = Column(String, nullable=True)
    duration = Column(String, nullable=True)
    coursework = Column(JSON, default=list)
    academic_projects = Column(JSON, default=list)
    is_visible = Column(Boolean, default=True)
    order = Column(Integer, default=0)

    profile = relationship("Profile", back_populates="educations")

class Experience(Base):
    __tablename__ = "experiences"

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(Integer, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    company = Column(String, nullable=False)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    start_date = Column(String, nullable=True)
    end_date = Column(String, nullable=True)
    key_achievements = Column(JSON, default=list)
    is_visible = Column(Boolean, default=True)
    order = Column(Integer, default=0)

    profile = relationship("Profile", back_populates="experiences")

class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(Integer, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    date = Column(String, nullable=True)
    source = Column(String, default="Manual")  # Resume, GitHub, Manual
    points = Column(Integer, default=0)
    is_visible = Column(Boolean, default=True)
    order = Column(Integer, default=0)

    profile = relationship("Profile", back_populates="achievements")

class Certification(Base):
    __tablename__ = "certifications"

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(Integer, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    issuer = Column(String, nullable=False)
    issue_date = Column(String, nullable=True)
    credential_id = Column(String, nullable=True)
    link = Column(String, nullable=True)
    is_visible = Column(Boolean, default=True)
    order = Column(Integer, default=0)

    profile = relationship("Profile", back_populates="certifications")

class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(Integer, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    objective = Column(String, nullable=True)
    description = Column(String, nullable=True)
    technologies = Column(JSON, default=list)
    role = Column(String, default="Contributor")
    repository_link = Column(String, nullable=True)
    readme_summary = Column(String, nullable=True)
    progress = Column(Float, default=1.0)
    commits_count = Column(Integer, default=0)
    stars_count = Column(Integer, default=0)
    forks_count = Column(Integer, default=0)
    contributors = Column(JSON, default=list)
    ai_summary = Column(String, nullable=True)
    last_activity = Column(DateTime, nullable=True)
    is_visible = Column(Boolean, default=True)
    order = Column(Integer, default=0)

    profile = relationship("Profile", back_populates="projects")

class GitHubAccount(Base):
    __tablename__ = "github_accounts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    github_id = Column(String, nullable=True)
    username = Column(String, nullable=False)
    email = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)
    bio = Column(String, nullable=True)
    location = Column(String, nullable=True)
    company = Column(String, nullable=True)
    website = Column(String, nullable=True)
    access_token = Column(String, nullable=True)  # Optional PAT
    followers_count = Column(Integer, default=0)
    following_count = Column(Integer, default=0)
    public_repos = Column(Integer, default=0)
    total_commits = Column(Integer, default=0)
    total_stars = Column(Integer, default=0)
    total_forks = Column(Integer, default=0)
    contribution_calendar = Column(JSON, default=dict)
    events_data = Column(JSON, default=list)   # Recent public events for timeline
    languages_aggregate = Column(JSON, default=dict)  # e.g. {"Python": 45000, "Dart": 32000}
    last_sync = Column(DateTime, default=datetime.datetime.utcnow)
    rate_limit_remaining = Column(Integer, default=60)

    user = relationship("User", back_populates="github_account")
    repositories = relationship("Repository", back_populates="github_account", cascade="all, delete-orphan")

class Repository(Base):
    __tablename__ = "repositories"

    id = Column(Integer, primary_key=True, index=True)
    github_account_id = Column(Integer, ForeignKey("github_accounts.id", ondelete="CASCADE"), nullable=False)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    readme_content = Column(Text, nullable=True)
    languages = Column(JSON, default=dict)
    commit_activity = Column(JSON, default=list)
    stars_count = Column(Integer, default=0)
    forks_count = Column(Integer, default=0)
    open_issues = Column(Integer, default=0)
    html_url = Column(String, nullable=True)
    topics = Column(JSON, default=list)
    contributors = Column(JSON, default=list)
    is_fork = Column(Boolean, default=False)
    is_private = Column(Boolean, default=False)
    created_at_github = Column(DateTime, nullable=True)
    last_updated = Column(DateTime, nullable=True)
    complexity_score = Column(Float, default=1.0)

    github_account = relationship("GitHubAccount", back_populates="repositories")

class TimelineEvent(Base):
    __tablename__ = "timeline_events"

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(Integer, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    event_type = Column(String, nullable=False)  # PushEvent, CreateEvent, PullRequestEvent, etc.
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    repo_name = Column(String, nullable=True)
    metadata_json = Column(JSON, default=dict)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    github_event_id = Column(String, nullable=True, unique=True)  # Prevent duplicates

    profile = relationship("Profile", back_populates="timeline_events")

class AISummary(Base):
    __tablename__ = "ai_summaries"

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(Integer, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    total_skills_detected = Column(Integer, default=0)
    total_projects_detected = Column(Integer, default=0)
    total_certifications_detected = Column(Integer, default=0)
    last_briefing = Column(String, nullable=True)
    merge_suggestions = Column(JSON, default=list)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    profile = relationship("Profile", back_populates="ai_summaries")
