from pydantic import BaseModel, EmailStr
from typing import List, Dict, Optional, Any
from datetime import datetime

# ----------------- JWT & Auth Schemas -----------------
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenPayload(BaseModel):
    sub: Optional[int] = None

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    github_username: Optional[str] = None

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    confirm_password: str
    full_name: str
    github_username: str

class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: Optional[str] = None
    github_username: Optional[str] = None
    is_active: bool

    class Config:
        from_attributes = True

class RegisterResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse
    profile_status: str  # "generating" | "ready"

# ----------------- Theme Preferences -----------------
class ThemePreferencesBase(BaseModel):
    theme_mode: str = "dark"
    accent_color: str = "#3A86FF"
    glassmorphism_enabled: bool = True
    typography_preference: str = "Outfit"

class ThemePreferencesUpdate(ThemePreferencesBase):
    pass

class ThemePreferencesResponse(ThemePreferencesBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True

# ----------------- Security Settings -----------------
class SecuritySettingsBase(BaseModel):
    two_factor_enabled: bool = False
    privacy_controls: Dict[str, Any] = {"show_email": True, "show_phone": False, "public_profile": True}

class SecuritySettingsUpdate(SecuritySettingsBase):
    pass

class SecuritySettingsResponse(SecuritySettingsBase):
    id: int
    user_id: int
    data_export_requested: bool

    class Config:
        from_attributes = True

# ----------------- Skill Schemas -----------------
class SkillBase(BaseModel):
    name: str
    category: Optional[str] = None
    proficiency_level: str = "Intermediate"
    source: str = "Manual"
    is_visible: bool = True
    order: int = 0

class SkillCreate(SkillBase):
    pass

class SkillUpdate(SkillBase):
    name: Optional[str] = None

class SkillResponse(SkillBase):
    id: int
    profile_id: int

    class Config:
        from_attributes = True

# ----------------- Education Schemas -----------------
class EducationBase(BaseModel):
    institution: str
    degree: str
    department: Optional[str] = None
    cgpa: Optional[str] = None
    duration: Optional[str] = None
    coursework: List[str] = []
    academic_projects: List[str] = []
    is_visible: bool = True
    order: int = 0

class EducationCreate(EducationBase):
    pass

class EducationUpdate(EducationBase):
    institution: Optional[str] = None
    degree: Optional[str] = None

class EducationResponse(EducationBase):
    id: int
    profile_id: int

    class Config:
        from_attributes = True

# ----------------- Experience Schemas -----------------
class ExperienceBase(BaseModel):
    company: str
    title: str
    description: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    key_achievements: List[str] = []
    is_visible: bool = True
    order: int = 0

class ExperienceCreate(ExperienceBase):
    pass

class ExperienceUpdate(ExperienceBase):
    company: Optional[str] = None
    title: Optional[str] = None

class ExperienceResponse(ExperienceBase):
    id: int
    profile_id: int

    class Config:
        from_attributes = True

# ----------------- Achievement Schemas -----------------
class AchievementBase(BaseModel):
    title: str
    description: Optional[str] = None
    date: Optional[str] = None
    source: str = "Manual"
    points: int = 0
    is_visible: bool = True
    order: int = 0

class AchievementCreate(AchievementBase):
    pass

class AchievementResponse(AchievementBase):
    id: int
    profile_id: int

    class Config:
        from_attributes = True

# ----------------- Certification Schemas -----------------
class CertificationBase(BaseModel):
    title: str
    issuer: str
    issue_date: Optional[str] = None
    credential_id: Optional[str] = None
    link: Optional[str] = None
    is_visible: bool = True
    order: int = 0

class CertificationCreate(CertificationBase):
    pass

class CertificationResponse(CertificationBase):
    id: int
    profile_id: int

    class Config:
        from_attributes = True

# ----------------- Project Schemas -----------------
class ProjectBase(BaseModel):
    title: str
    objective: Optional[str] = None
    description: Optional[str] = None
    technologies: List[str] = []
    role: str = "Contributor"
    repository_link: Optional[str] = None
    readme_summary: Optional[str] = None
    progress: float = 1.0
    commits_count: int = 0
    stars_count: int = 0
    forks_count: int = 0
    contributors: List[str] = []
    ai_summary: Optional[str] = None
    is_visible: bool = True
    order: int = 0

class ProjectCreate(ProjectBase):
    pass

class ProjectUpdate(ProjectBase):
    title: Optional[str] = None

class ProjectResponse(ProjectBase):
    id: int
    profile_id: int
    last_activity: Optional[datetime] = None

    class Config:
        from_attributes = True

# ----------------- Profile Schemas -----------------
class ProfileBase(BaseModel):
    fullName: str
    headline: Optional[str] = None
    bio: Optional[str] = None
    technical_summary: Optional[str] = None
    career_overview: Optional[str] = None
    portfolio_summary: Optional[str] = None
    profile_visibility: bool = True

class ProfileCreate(ProfileBase):
    pass

class ProfileUpdate(ProfileBase):
    fullName: Optional[str] = None

class ProfileResponse(ProfileBase):
    id: int
    user_id: int
    avatar_url: Optional[str] = None
    zen_score: float = 0.0
    zen_rank: str = "Beginner"
    zen_breakdown: Dict[str, Any] = {}
    zen_trend: str = "stable"
    created_at: datetime
    updated_at: datetime
    skills: List[SkillResponse] = []
    educations: List[EducationResponse] = []
    experiences: List[ExperienceResponse] = []
    achievements: List[AchievementResponse] = []
    certifications: List[CertificationResponse] = []
    projects: List[ProjectResponse] = []

    class Config:
        from_attributes = True

# ----------------- GitHub Account Schemas -----------------
class RepositoryResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    languages: Dict[str, int] = {}
    commit_activity: List[int] = []
    stars_count: int = 0
    forks_count: int = 0
    open_issues: int = 0
    html_url: Optional[str] = None
    topics: List[str] = []
    contributors: List[str] = []
    last_updated: Optional[datetime] = None
    complexity_score: float = 1.0

    class Config:
        from_attributes = True

class GitHubAccountResponse(BaseModel):
    id: int
    username: str
    email: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    location: Optional[str] = None
    company: Optional[str] = None
    website: Optional[str] = None
    followers_count: int
    following_count: int
    public_repos: int
    total_commits: int
    total_stars: int
    total_forks: int
    contribution_calendar: Dict[str, Any] = {}
    languages_aggregate: Dict[str, int] = {}
    last_sync: Optional[datetime] = None
    repositories: List[RepositoryResponse] = []

    class Config:
        from_attributes = True

# ----------------- GitHub Public Profile (Direct API) -----------------
class GitHubPublicProfile(BaseModel):
    username: str
    name: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    location: Optional[str] = None
    company: Optional[str] = None
    blog: Optional[str] = None
    public_repos: int = 0
    followers: int = 0
    following: int = 0

# ----------------- Timeline Events -----------------
class TimelineEventResponse(BaseModel):
    id: int
    profile_id: int
    event_type: str
    title: str
    description: Optional[str] = None
    repo_name: Optional[str] = None
    metadata_json: Dict[str, Any] = {}
    created_at: datetime

    class Config:
        from_attributes = True

# ----------------- AI Summaries -----------------
class AISummaryResponse(BaseModel):
    id: int
    profile_id: int
    total_skills_detected: int
    total_projects_detected: int
    total_certifications_detected: int
    last_briefing: Optional[str] = None
    merge_suggestions: List[Dict[str, Any]] = []

    class Config:
        from_attributes = True

class AIChatRequest(BaseModel):
    message: str

class AIChatResponse(BaseModel):
    reply: str

# ----------------- Zen Score -----------------
class ZenScoreBreakdown(BaseModel):
    profile_completeness: float = 0.0   # max 20
    github_activity: float = 0.0         # max 25
    repository_quality: float = 0.0      # max 20
    skill_diversity: float = 0.0         # max 15
    resume_completeness: float = 0.0     # max 10
    achievement_count: float = 0.0       # max 5
    contribution_frequency: float = 0.0  # max 5

class ZenScoreResponse(BaseModel):
    total_score: float
    rank: str         # Beginner, Rising, Proficient, Expert, Master
    trend: str        # up, down, stable
    breakdown: ZenScoreBreakdown
    last_calculated: Optional[datetime] = None

# ----------------- Resume Upload -----------------
class ResumeUploadResponse(BaseModel):
    status: str
    filename: str
    parsed_name: Optional[str] = None
    parsed_skills_count: int = 0
    parsed_experience_count: int = 0
    parsed_education_count: int = 0
    zen_score_after: float = 0.0
    message: str
