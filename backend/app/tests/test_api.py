import sys
import os
import unittest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure the backend directory is in the sys.path to run tests properly
backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if backend_dir not in sys.path:
    sys.path.append(backend_dir)

# Override database and redis settings for isolation
os.environ["DATABASE_URL"] = "sqlite:///./test.db"
os.environ["REDIS_URL"] = "redis://localhost:6379/9"  # Use separate redis db if running local mock

from app.main import app
from app.database import Base, get_db

# Setup SQLite test database session
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

# Apply the SQLAlchemy override dependency injection to FastAPI
app.dependency_overrides[get_db] = override_get_db

class TestDevZenAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Initialize SQLite database and tables
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    @classmethod
    def tearDownClass(cls):
        # Drop test database and tables
        Base.metadata.drop_all(bind=engine)
        if os.path.exists("./test.db"):
            try:
                os.remove("./test.db")
            except OSError:
                pass

    def test_01_read_root(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "online")
        self.assertEqual(response.json()["app"], "DevZen Backend")

    def test_02_auth_and_profile_flow(self):
        # 1. Register User
        import io
        resume_file = io.BytesIO(b"Mock resume content for DevZen profile")
        response = self.client.post(
            "/api/v1/auth/register",
            data={
                "full_name": "developer",
                "email": "developer@devzen.io",
                "password": "securepassword123",
                "confirm_password": "securepassword123",
                "github_username": "developer",
            },
            files={"resume": ("resume.txt", resume_file, "text/plain")}
        )
        self.assertEqual(response.status_code, 200)
        user_data = response.json()["user"]
        self.assertEqual(user_data["email"], "developer@devzen.io")
        self.assertTrue(user_data["is_active"])

        # 2. Login User
        login_data = {
            "username": "developer@devzen.io",
            "password": "securepassword123"
        }
        response = self.client.post("/api/v1/auth/login", data=login_data)
        self.assertEqual(response.status_code, 200)
        token_data = response.json()
        self.assertIn("access_token", token_data)
        self.assertEqual(token_data["token_type"], "bearer")
        
        token = token_data["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 3. Read Current User Profile Info
        response = self.client.get("/api/v1/auth/me", headers=headers)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["email"], "developer@devzen.io")

        # 4. Get Profile Details
        response = self.client.get("/api/v1/profile/me", headers=headers)
        self.assertEqual(response.status_code, 200)
        profile_data = response.json()
        self.assertEqual(profile_data["fullName"], "developer")
        self.assertTrue(profile_data["profile_visibility"])

        # 5. Update Profile Details
        profile_update = {
            "fullName": "Alex Rivera",
            "headline": "Lead AI Engineer",
            "bio": "Building an AI-powered email security platform",
            "technical_summary": "Python, PyTorch, FastAPI, Docker, AWS",
            "career_overview": "Senior AI engineer at DevZen",
            "portfolio_summary": "PhishGuard, mobile client",
            "profile_visibility": True
        }
        response = self.client.put("/api/v1/profile/me", json=profile_update, headers=headers)
        self.assertEqual(response.status_code, 200)
        updated_data = response.json()
        self.assertEqual(updated_data["fullName"], "Alex Rivera")
        self.assertEqual(updated_data["headline"], "Lead AI Engineer")
        self.assertEqual(updated_data["bio"], "Building an AI-powered email security platform")

        # 6. Check developer timeline event log
        response = self.client.get("/api/v1/timeline/", headers=headers)
        self.assertEqual(response.status_code, 200)
        self.assertIsInstance(response.json(), list)

        # 7. AI Chat assistant command
        ai_chat_payload = {
            "message": "Explain what is glassmorphism in modern designs"
        }
        response = self.client.post("/api/v1/ai/assistant/chat", json=ai_chat_payload, headers=headers)
        self.assertEqual(response.status_code, 200)
        self.assertIn("reply", response.json())
        self.assertTrue(len(response.json()["reply"]) > 0)

    def test_03_unauthorized_access(self):
        # Verify checking endpoints without token returns 401
        response = self.client.get("/api/v1/auth/me")
        self.assertEqual(response.status_code, 401)
        
        response = self.client.get("/api/v1/profile/me")
        self.assertEqual(response.status_code, 401)
