"""
AI Assistant Service — Personalized developer context for DevZen AI.

Builds a rich system prompt from the user's actual profile data:
  - Name, headline, bio
  - Skills list
  - Education
  - Experiences
  - Projects + GitHub repo descriptions
  - Certifications
  - GitHub stats

Every AI response is personalized to the specific user's developer identity.
"""

import os
import logging
from sqlalchemy.orm import Session
from app import models

logger = logging.getLogger(__name__)


class AIAssistantService:
    def __init__(self, db: Session):
        self.db = db
        self.gemini_key = os.getenv("GEMINI_API_KEY", "")

    def chat(self, user_id: int, message: str) -> str:
        """Process a chat message with personalized user context."""
        profile = self._get_profile(user_id)
        context = self._build_context(profile, user_id)

        if self.gemini_key:
            return self._call_gemini(context, message)
        else:
            return self._rule_based_response(message, profile)

    def get_suggestions(self, user_id: int) -> list:
        """Generate personalized AI improvement suggestions."""
        profile = self._get_profile(user_id)
        if not profile:
            return []

        suggestions = []

        # Check GitHub skills not in resume
        if profile.user and profile.user.github_account:
            github = profile.user.github_account
            resume_skills = {s.name.lower() for s in profile.skills if s.source == "Resume"}
            for repo in github.repositories:
                for lang in (repo.languages or {}).keys():
                    if lang.lower() not in resume_skills and lang not in ["", "unknown"]:
                        suggestions.append({
                            "type": "skill_gap",
                            "title": f"Add {lang} to your profile",
                            "description": f"Detected in {repo.name} but not in your resume skills.",
                            "action": f"add_skill:{lang}"
                        })

        # Check missing profile fields
        if not profile.headline:
            suggestions.append({
                "type": "profile",
                "title": "Add a professional headline",
                "description": "A headline helps recruiters understand your specialization.",
                "action": "edit_headline"
            })

        if not profile.bio or len(profile.bio) < 50:
            suggestions.append({
                "type": "profile",
                "title": "Expand your About Me section",
                "description": "A detailed bio increases profile visibility and Zen Score.",
                "action": "edit_bio"
            })

        # Limit to top 5
        return suggestions[:5]

    def generate_portfolio_content(self, user_id: int) -> dict:
        """Generate portfolio-ready content sections from the user's profile."""
        profile = self._get_profile(user_id)
        if not profile:
            return {}

        github = profile.user.github_account if profile.user else None

        top_projects = profile.projects[:3] if profile.projects else []
        skills_by_cat: dict = {}
        for sk in profile.skills:
            cat = sk.category or "Other"
            skills_by_cat.setdefault(cat, []).append(sk.name)

        return {
            "headline": profile.headline or f"{profile.fullName} — Software Engineer",
            "bio": profile.bio or "",
            "top_skills": skills_by_cat,
            "featured_projects": [
                {
                    "name": p.title,
                    "description": p.description or p.objective,
                    "technologies": p.technologies,
                    "github": p.repository_link
                }
                for p in top_projects
            ],
            "github_stats": {
                "repos": github.public_repos if github else 0,
                "stars": github.total_stars if github else 0,
                "followers": github.followers_count if github else 0,
            } if github else {}
        }

    # ─── Context Builder ──────────────────────────────────────────────────

    def _build_context(self, profile: models.Profile, user_id: int) -> str:
        if not profile:
            return "You are DevZen AI, an AI-powered developer identity assistant."

        github = profile.user.github_account if profile.user else None

        # Skills summary
        skills_str = ", ".join(s.name for s in profile.skills[:20]) if profile.skills else "Not specified"

        # Top projects
        projects_str = ""
        for p in (profile.projects or [])[:5]:
            techs = ", ".join(p.technologies[:5]) if p.technologies else "N/A"
            projects_str += f"\n  - {p.title}: {p.description or p.objective or ''} (Tech: {techs})"
        if not projects_str:
            projects_str = "\n  - No projects yet"

        # Education
        edu_str = ""
        for e in (profile.educations or [])[:2]:
            edu_str += f"\n  - {e.degree} at {e.institution} ({e.duration or 'N/A'})"
        if not edu_str:
            edu_str = "\n  - Not specified"

        # Experience
        exp_str = ""
        for e in (profile.experiences or [])[:3]:
            exp_str += f"\n  - {e.title} at {e.company} ({e.start_date or ''} - {e.end_date or 'Present'})"
        if not exp_str:
            exp_str = "\n  - Not specified"

        # GitHub stats
        github_str = "Not connected"
        if github:
            github_str = (
                f"@{github.username} | "
                f"{github.public_repos} repos | "
                f"{github.followers_count} followers | "
                f"{github.total_stars} stars total"
            )

        # README snippets from repos (for code explanation context)
        repo_context = ""
        if github:
            for repo in (github.repositories or [])[:3]:
                if repo.readme_content:
                    snippet = repo.readme_content[:200].replace("\n", " ")
                    repo_context += f"\n  - {repo.name}: {snippet}"

        context = f"""You are DevZen AI — the personal AI assistant for {profile.fullName}.

You have deep knowledge of this developer's professional profile. Always respond in a personalized, helpful, and encouraging tone.

=== DEVELOPER PROFILE ===
Name: {profile.fullName}
Headline: {profile.headline or 'Software Engineer'}
Bio: {profile.bio or 'Not provided'}
Zen Score: {profile.zen_score:.1f}/100 (Rank: {profile.zen_rank})
GitHub: {github_str}

=== SKILLS ===
{skills_str}

=== EDUCATION ==={edu_str}

=== EXPERIENCE ==={exp_str}

=== PROJECTS ==={projects_str}

=== GITHUB REPOSITORIES ==={repo_context if repo_context else chr(10) + '  - No repositories yet'}

=== YOUR ROLE ===
You can help {profile.fullName} with:
1. Explaining their projects (you know all their repos)
2. Summarizing their profile for LinkedIn/portfolio
3. Generating resume updates
4. Identifying skill gaps vs market trends
5. Writing documentation for their projects
6. Explaining code snippets they paste
7. Suggesting next projects based on their stack
8. Generating a compelling LinkedIn bio
9. Creating portfolio content
10. Answering any developer-related questions

Always refer to the user's actual projects and skills when relevant.
Keep responses concise, practical, and specific to this developer's profile.
"""
        return context

    # ─── AI Call ──────────────────────────────────────────────────────────

    def _call_gemini(self, context: str, message: str) -> str:
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.gemini_key)
            model = genai.GenerativeModel(
                model_name="gemini-1.5-flash",
                system_instruction=context
            )
            response = model.generate_content(message)
            return response.text
        except Exception as e:
            logger.error(f"Gemini chat failed: {e}")
            return self._rule_based_response(message, None)

    # ─── Rule-Based Fallback ──────────────────────────────────────────────

    def _rule_based_response(self, message: str, profile: models.Profile) -> str:
        name = profile.fullName if profile else "Developer"
        cmd = message.lower()

        if any(w in cmd for w in ["explain", "what is", "how does"]):
            if profile and profile.projects:
                proj = profile.projects[0]
                return f"### {proj.title}\n\n{proj.description or proj.objective}\n\n**Technologies**: {', '.join(proj.technologies[:5])}\n\n**GitHub**: {proj.repository_link or 'N/A'}"
            return "### Code Explanation\n\nPlease paste the code or describe the project you'd like me to explain."

        if any(w in cmd for w in ["linkedin", "bio", "summary", "about me"]):
            skills_str = ", ".join(s.name for s in (profile.skills or [])[:6]) if profile else "various technologies"
            return f"### LinkedIn Bio for {name}\n\n🚀 {profile.headline if profile else 'Software Engineer'} passionate about building impactful software solutions.\n\nSpecializing in {skills_str}.\n\nOpen to exciting opportunities in software development and engineering leadership."

        if any(w in cmd for w in ["skill gap", "missing", "improve", "suggest"]):
            return f"### Skill Gap Analysis for {name}\n\nBased on your current profile:\n\n1. **Cloud Certifications** — Consider AWS or GCP certifications to boost your Zen Score\n2. **Open Source Contributions** — Contributing to popular repos increases your GitHub activity score\n3. **Documentation** — Adding READMEs to all repos improves repository quality points\n4. **Profile Completeness** — Ensure all profile sections are filled to maximize your score"

        if any(w in cmd for w in ["project", "portfolio", "showcase"]):
            if profile and profile.projects:
                proj_list = "\n".join(f"- **{p.title}**: {p.description or p.objective or ''}" for p in profile.projects[:3])
                return f"### Your Top Projects\n\n{proj_list}\n\nAll projects are auto-generated from your GitHub repositories. You can edit any details in the Projects tab."
            return "### Projects\n\nConnect your GitHub account to auto-generate project cards from your repositories."

        if any(w in cmd for w in ["zen score", "score", "rank"]):
            score = f"{profile.zen_score:.1f}" if profile else "N/A"
            rank = profile.zen_rank if profile else "N/A"
            return f"### Your Zen Score\n\n**{score}/100** — Rank: **{rank}**\n\nIncrease your score by:\n- Uploading/updating your resume\n- Adding topics to your GitHub repos\n- Contributing more consistently\n- Completing all profile sections"

        if any(w in cmd for w in ["readme", "documentation", "docs"]):
            if profile and profile.projects:
                p = profile.projects[0]
                return f"# {p.title}\n\n{p.description or p.objective or 'A software project.'}\n\n## Technologies\n{', '.join(p.technologies[:5])}\n\n## Getting Started\n\n```bash\ngit clone {p.repository_link or 'https://github.com/your-repo'}\n```\n\n## License\nMIT"
            return "### README Generator\n\nPlease specify which project you'd like me to generate a README for."

        # Default
        skills_preview = ", ".join(s.name for s in (profile.skills or [])[:4]) if profile else "your technologies"
        return f"### DevZen AI\n\nHi {name}! 👋 I'm your personal DevZen AI, fully aware of your profile, projects, and GitHub activity.\n\nHere's what I can help you with:\n- **Explain your projects** — I know all your repos\n- **Generate LinkedIn bio** — Personalized to your stack ({skills_preview})\n- **Identify skill gaps** — Compare your skills to market trends\n- **Write documentation** — READMEs, API docs, portfolio content\n- **Answer code questions** — Paste any code snippet\n\nWhat would you like to do today?"

    def _get_profile(self, user_id: int):
        return self.db.query(models.Profile).filter(
            models.Profile.user_id == user_id
        ).first()
