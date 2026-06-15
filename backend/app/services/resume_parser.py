"""
Resume Parser Service — AI-powered resume intelligence for DevZen.

Flow:
  1. Extract raw text from PDF/DOCX
  2. Send to Gemini AI with structured JSON extraction prompt
  3. Fallback to heuristic regex parsing if no API key
  4. Populate profile in database
  5. Trigger Zen Score recalculation
"""

import io
import os
import re
import json
import logging
import PyPDF2
import docx2txt
from sqlalchemy.orm import Session
from app import models

logger = logging.getLogger(__name__)


class ResumeParserService:
    def __init__(self, db: Session):
        self.db = db
        self.gemini_key = os.getenv("GEMINI_API_KEY", "")

    def parse_and_initialize_profile(self, user_id: int, filename: str, file_bytes: bytes) -> dict:
        """Main entry: extract text, parse with AI, populate profile, return summary."""
        raw_text = self._extract_text(filename, file_bytes)
        if not raw_text or len(raw_text.strip()) < 50:
            return {"status": "error", "message": "Could not extract readable text from the file."}

        # Parse with AI or fallback
        if self.gemini_key:
            extracted_data = self._parse_with_gemini(raw_text)
        else:
            extracted_data = self._parse_with_heuristics(raw_text)

        # Populate database
        result = self._populate_profile(user_id, filename, raw_text, extracted_data)

        # Trigger Zen Score recalculation
        profile = self.db.query(models.Profile).filter(models.Profile.user_id == user_id).first()
        if profile:
            from app.services.zen_score_engine import ZenScoreEngine
            zen = ZenScoreEngine(self.db).calculate_and_save(profile.id)
            result["zen_score_after"] = zen.get("total_score", 0.0)

        return result

    # ─── Text Extraction ──────────────────────────────────────────────────

    def _extract_text(self, filename: str, file_bytes: bytes) -> str:
        text = ""
        try:
            if filename.lower().endswith(".pdf"):
                pdf_reader = PyPDF2.PdfReader(io.BytesIO(file_bytes))
                for page in pdf_reader.pages:
                    page_text = page.extract_text()
                    if page_text:
                        text += page_text + "\n"
            elif filename.lower().endswith(".docx"):
                text = docx2txt.process(io.BytesIO(file_bytes))
            elif filename.lower().endswith(".txt"):
                text = file_bytes.decode("utf-8", errors="ignore")
        except Exception as e:
            logger.error(f"Text extraction failed for {filename}: {e}")
        return text

    # ─── Gemini AI Parsing ────────────────────────────────────────────────

    def _parse_with_gemini(self, raw_text: str) -> dict:
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.gemini_key)
            model = genai.GenerativeModel("gemini-1.5-flash")

            prompt = f"""
You are a resume parsing assistant. Extract structured information from the following resume text and return ONLY a valid JSON object with NO markdown formatting, NO code blocks, just raw JSON.

Extract these fields exactly:
{{
  "fullName": "person's full name",
  "headline": "professional headline (job title + specialization)",
  "bio": "2-3 sentence professional summary",
  "skills": [
    {{"name": "skill name", "category": "Languages|Frameworks|DevOps|Databases|Methodologies|Tools", "proficiency_level": "Beginner|Intermediate|Expert"}}
  ],
  "educations": [
    {{"institution": "university name", "degree": "degree type and field", "department": "department", "cgpa": "GPA if present", "duration": "start-end years", "coursework": ["course1"], "academic_projects": ["project1"]}}
  ],
  "experiences": [
    {{"company": "company name", "title": "job title", "description": "role description", "start_date": "YYYY-MM", "end_date": "YYYY-MM or Present", "key_achievements": ["achievement1"]}}
  ],
  "certifications": [
    {{"title": "cert name", "issuer": "organization", "issue_date": "YYYY-MM", "credential_id": "ID if present"}}
  ],
  "achievements": [
    {{"title": "achievement title", "description": "description", "date": "year", "points": 10}}
  ]
}}

Resume text:
{raw_text[:4000]}

Return ONLY the JSON object, nothing else.
"""
            response = model.generate_content(prompt)
            response_text = response.text.strip()

            # Clean potential markdown code blocks
            if response_text.startswith("```"):
                response_text = re.sub(r"```(?:json)?\n?", "", response_text).strip("`").strip()

            parsed = json.loads(response_text)
            logger.info("Resume parsed successfully with Gemini AI")
            return parsed

        except Exception as e:
            logger.error(f"Gemini parsing failed: {e}. Falling back to heuristics.")
            return self._parse_with_heuristics(raw_text)

    # ─── Heuristic Fallback ───────────────────────────────────────────────

    def _parse_with_heuristics(self, raw_text: str) -> dict:
        """Basic regex/keyword-based extraction when no AI key is available."""
        logger.info("Parsing resume with heuristic fallback")
        lines = [l.strip() for l in raw_text.split("\n") if l.strip()]

        # Name heuristic: usually first non-empty line
        full_name = lines[0] if lines else "Unknown"
        if len(full_name) > 50 or "@" in full_name:
            full_name = "Developer"

        # Extract email
        email_match = re.search(r"[\w.+-]+@[\w-]+\.[\w.]+", raw_text)
        email = email_match.group(0) if email_match else ""

        # Extract skills by common keyword patterns
        tech_keywords = [
            "Python", "JavaScript", "TypeScript", "Java", "C++", "C#", "Go", "Rust", "Swift",
            "Kotlin", "Dart", "Flutter", "React", "Angular", "Vue", "Node.js", "FastAPI",
            "Django", "Spring", "Docker", "Kubernetes", "AWS", "GCP", "Azure", "PostgreSQL",
            "MongoDB", "Redis", "Git", "Linux", "TensorFlow", "PyTorch", "Machine Learning",
            "Deep Learning", "REST", "GraphQL", "Microservices", "SQL", "HTML", "CSS",
            "Firebase", "Supabase", "Next.js", "Express", "Flask", "Celery", "RabbitMQ"
        ]
        found_skills = []
        for kw in tech_keywords:
            if kw.lower() in raw_text.lower():
                category = self._categorize_skill(kw)
                found_skills.append({
                    "name": kw,
                    "category": category,
                    "proficiency_level": "Intermediate"
                })

        # Extract education keywords
        educations = []
        edu_patterns = [
            r"(B\.?S\.?|B\.?Tech|M\.?S\.?|M\.?Tech|Ph\.?D|Bachelor|Master|Doctor)[^\n]+",
            r"(University|College|Institute|School)\s+of\s+[\w\s]+",
        ]
        for pattern in edu_patterns:
            matches = re.findall(pattern, raw_text, re.IGNORECASE)
            for match in matches[:2]:
                if isinstance(match, tuple):
                    match = " ".join(match)
                educations.append({
                    "institution": "University",
                    "degree": match.strip()[:100],
                    "department": "",
                    "cgpa": "",
                    "duration": "",
                    "coursework": [],
                    "academic_projects": []
                })
            break

        # Generate a bio from the first few lines
        bio_lines = [l for l in lines[1:6] if len(l) > 20 and "@" not in l and "http" not in l]
        bio = " ".join(bio_lines[:2])[:300] if bio_lines else f"Experienced {full_name} with expertise in software development."

        return {
            "fullName": full_name,
            "headline": "Software Engineer",
            "bio": bio,
            "skills": found_skills[:20],
            "educations": educations[:2],
            "experiences": [],
            "certifications": [],
            "achievements": []
        }

    def _categorize_skill(self, skill: str) -> str:
        languages = ["Python", "JavaScript", "TypeScript", "Java", "C++", "C#", "Go", "Rust", "Swift", "Kotlin", "Dart", "SQL", "HTML", "CSS"]
        frameworks = ["Flutter", "React", "Angular", "Vue", "Node.js", "FastAPI", "Django", "Spring", "Flask", "Express", "Next.js"]
        devops = ["Docker", "Kubernetes", "AWS", "GCP", "Azure", "Linux", "Git", "Firebase", "Supabase"]
        databases = ["PostgreSQL", "MongoDB", "Redis", "MySQL", "SQLite"]
        if skill in languages:
            return "Languages"
        if skill in frameworks:
            return "Frameworks"
        if skill in devops:
            return "DevOps"
        if skill in databases:
            return "Databases"
        return "Methodologies"

    # ─── Database Population ──────────────────────────────────────────────

    def _populate_profile(self, user_id: int, filename: str, raw_text: str, data: dict) -> dict:
        profile = self.db.query(models.Profile).filter(models.Profile.user_id == user_id).first()
        if not profile:
            profile = models.Profile(user_id=user_id, fullName=data.get("fullName", "Developer"))
            self.db.add(profile)
            self.db.commit()
            self.db.refresh(profile)

        # Core profile fields
        profile.fullName = data.get("fullName", profile.fullName)
        profile.headline = data.get("headline", profile.headline)
        profile.bio = data.get("bio", profile.bio)
        profile.resume_raw_text = raw_text
        self.db.commit()

        # Skills (merge: keep GitHub-sourced, replace Resume-sourced)
        self.db.query(models.Skill).filter(
            models.Skill.profile_id == profile.id,
            models.Skill.source == "Resume"
        ).delete()
        for sk in (data.get("skills") or []):
            self.db.add(models.Skill(
                profile_id=profile.id,
                name=sk.get("name", ""),
                category=sk.get("category", "Methodologies"),
                proficiency_level=sk.get("proficiency_level", "Intermediate"),
                source="Resume"
            ))

        # Education
        self.db.query(models.Education).filter(models.Education.profile_id == profile.id).delete()
        for edu in (data.get("educations") or []):
            self.db.add(models.Education(
                profile_id=profile.id,
                institution=edu.get("institution", ""),
                degree=edu.get("degree", ""),
                department=edu.get("department", ""),
                cgpa=edu.get("cgpa", ""),
                duration=edu.get("duration", ""),
                coursework=edu.get("coursework", []),
                academic_projects=edu.get("academic_projects", [])
            ))

        # Experience
        self.db.query(models.Experience).filter(models.Experience.profile_id == profile.id).delete()
        for exp in (data.get("experiences") or []):
            self.db.add(models.Experience(
                profile_id=profile.id,
                company=exp.get("company", ""),
                title=exp.get("title", ""),
                description=exp.get("description", ""),
                start_date=exp.get("start_date", ""),
                end_date=exp.get("end_date", ""),
                key_achievements=exp.get("key_achievements", [])
            ))

        # Certifications
        self.db.query(models.Certification).filter(models.Certification.profile_id == profile.id).delete()
        for cert in (data.get("certifications") or []):
            self.db.add(models.Certification(
                profile_id=profile.id,
                title=cert.get("title", ""),
                issuer=cert.get("issuer", ""),
                issue_date=cert.get("issue_date", ""),
                credential_id=cert.get("credential_id", "")
            ))

        # Achievements
        self.db.query(models.Achievement).filter(models.Achievement.profile_id == profile.id).delete()
        for ach in (data.get("achievements") or []):
            self.db.add(models.Achievement(
                profile_id=profile.id,
                title=ach.get("title", ""),
                description=ach.get("description", ""),
                date=ach.get("date", ""),
                source="Resume",
                points=ach.get("points", 10)
            ))

        # Timeline event for resume upload
        event = models.TimelineEvent(
            profile_id=profile.id,
            event_type="ResumeUploaded",
            title="Resume uploaded and analyzed",
            description=f"Extracted profile data from '{filename}'."
        )
        self.db.add(event)

        # AI Summary
        summary = self.db.query(models.AISummary).filter(
            models.AISummary.profile_id == profile.id
        ).first()
        if not summary:
            summary = models.AISummary(profile_id=profile.id)
            self.db.add(summary)
        summary.total_skills_detected = len(data.get("skills") or [])
        summary.total_projects_detected = len(data.get("experiences") or [])
        summary.total_certifications_detected = len(data.get("certifications") or [])
        summary.last_briefing = (
            f"Resume analysis complete. "
            f"Detected {summary.total_skills_detected} skills, "
            f"{summary.total_projects_detected} experiences, "
            f"{summary.total_certifications_detected} certifications."
        )
        self.db.commit()

        return {
            "status": "success",
            "filename": filename,
            "parsed_name": profile.fullName,
            "parsed_skills_count": summary.total_skills_detected,
            "parsed_experience_count": summary.total_projects_detected,
            "parsed_education_count": len(data.get("educations") or []),
            "zen_score_after": 0.0,
            "message": summary.last_briefing
        }
