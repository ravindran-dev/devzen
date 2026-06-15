from sqlalchemy.orm import Session
from app import models

class AIFusionService:
    def __init__(self, db: Session):
        self.db = db

    def generate_fusion_suggestions(self, profile_id: int) -> list:
        profile = self.db.query(models.Profile).filter(models.Profile.id == profile_id).first()
        if not profile or not profile.user.github_account:
            return []

        # Get current profile skills
        existing_skills = {sk.name.lower() for sk in profile.skills}

        # Analyze connected GitHub repositories
        github_skills = set()
        for repo in profile.user.github_account.repositories:
            # Add languages
            for lang in repo.languages.keys():
                github_skills.add(lang)
            # Add topics
            for topic in repo.topics:
                # Capitalize or normalize topic name
                github_skills.add(topic.title())

        # Discrepancy check: languages/skills in GitHub but not in profile
        suggestions = []
        for skill in github_skills:
            if skill.lower() not in existing_skills:
                # Determine occurrences in repos
                count = 0
                for repo in profile.user.github_account.repositories:
                    if skill in repo.languages.keys() or any(t.lower() == skill.lower() for t in repo.topics):
                        count += 1
                
                suggestions.append({
                    "suggestion_id": f"add_{skill.lower()}",
                    "skill_name": skill,
                    "reason": f"Detected in {count} repositories but missing from your profile resume list. Click to sync.",
                    "source": "GitHub Audit",
                    "repo_count": count
                })

        # Save these suggestions into AI Summary database
        summary = self.db.query(models.AISummary).filter(models.AISummary.profile_id == profile_id).first()
        if summary:
            summary.merge_suggestions = suggestions
            self.db.commit()

        return suggestions

    def apply_suggestion(self, profile_id: int, suggestion_id: str) -> bool:
        profile = self.db.query(models.Profile).filter(models.Profile.id == profile_id).first()
        if not profile:
            return False

        # Parse skill name from ID (e.g., add_flutter -> Flutter)
        skill_name = suggestion_id.replace("add_", "").title()
        if skill_name.lower() == "js":
            skill_name = "JavaScript"
        elif skill_name.lower() == "ts":
            skill_name = "TypeScript"

        # Check if already added
        exists = self.db.query(models.Skill).filter(
            models.Skill.profile_id == profile_id,
            models.Skill.name.ilike(skill_name)
        ).first()

        if not exists:
            # Determine appropriate category
            category = "Languages"
            if skill_name.lower() in ["flutter", "react", "fastapi", "express", "django"]:
                category = "Frameworks"
            elif skill_name.lower() in ["docker", "kubernetes", "aws", "gcp"]:
                category = "DevOps"

            db_skill = models.Skill(
                profile_id=profile_id,
                name=skill_name,
                category=category,
                proficiency_level="Intermediate",
                source="GitHub Fusion"
            )
            self.db.add(db_skill)

            # Add Timeline log
            event = models.TimelineEvent(
                profile_id=profile_id,
                event_type="Skill Added",
                title=f"Added skill: {skill_name}",
                description=f"Skill merged automatically from GitHub integration audits."
            )
            self.db.add(event)
            self.db.commit()
            
            # Recalculate suggestions list
            self.generate_fusion_suggestions(profile_id)
            return True

        return False
