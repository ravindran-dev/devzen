from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "DevZen Backend"
    API_V1_STR: str = "/api/v1"
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/devzen"
    REDIS_URL: str = "redis://localhost:6379/0"
    JWT_SECRET: str = "devzen_super_secret_key_12345"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # GitHub OAuth configurations
    GITHUB_CLIENT_ID: str = "mock_client_id"
    GITHUB_CLIENT_SECRET: str = "mock_client_secret"
    GITHUB_REDIRECT_URI: str = "http://localhost:8000/api/v1/auth/github/callback"
    
    # AI models keys
    GEMINI_API_KEY: str = "mock_gemini_key"
    OPENAI_API_KEY: str = "mock_openai_key"

    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
