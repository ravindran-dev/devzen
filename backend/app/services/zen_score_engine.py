"""
ZenScoreEngine — Dynamic developer scoring engine for DevZen.

Scoring Dimensions (Total: 100 points):
  - Profile Completeness:    0–20 pts
  - GitHub Activity:         0–25 pts
  - Repository Quality:      0–20 pts
  - Skill Diversity:         0–15 pts
  - Resume Completeness:     0–10 pts
  - Achievement Count:        0–5 pts
  - Contribution Frequency:   0–5 pts

Ranks:
  0–20:   Beginner
  21–40:  Rising
  41–60:  Proficient
  61–80:  Expert
  81–100: Master
"""

import datetime
from sqlalchemy.orm import Session
from app import models


class ZenScoreEngine:
    RANK_THRESHOLDS = [
        (81, "Master"),
        (61, "Expert"),
        (41, "Proficient"),
        (21, "Rising"),
        (0,  "Beginner"),
    ]

    def __init__(self, db: Session):
        self.db = db

    def calculate_and_save(self, profile_id: int) -> dict:
        """Calculate Zen Score for a profile and persist results. Returns breakdown dict."""
        profile = self.db.query(models.Profile).filter(models.Profile.id == profile_id).first()
        if not profile:
            return {"total": 0.0, "rank": "Beginner", "breakdown": {}}

        github = profile.user.github_account if profile.user else None

        breakdown = {
            "profile_completeness":   self._score_profile_completeness(profile),
            "github_activity":        self._score_github_activity(github),
            "repository_quality":     self._score_repository_quality(github),
            "skill_diversity":        self._score_skill_diversity(profile, github),
            "resume_completeness":    self._score_resume_completeness(profile),
            "achievement_count":      self._score_achievements(profile),
            "contribution_frequency": self._score_contribution_frequency(github),
        }

        total = round(sum(breakdown.values()), 1)
        rank = self._get_rank(total)

        # Determine trend
        old_score = profile.zen_score or 0.0
        if total > old_score + 0.5:
            trend = "up"
        elif total < old_score - 0.5:
            trend = "down"
        else:
            trend = "stable"

        # Persist
        profile.zen_score = total
        profile.zen_rank = rank
        profile.zen_breakdown = breakdown
        profile.zen_trend = trend
        self.db.commit()

        return {
            "total_score": total,
            "rank": rank,
            "trend": trend,
            "breakdown": breakdown,
            "last_calculated": datetime.datetime.utcnow().isoformat()
        }

    # ─── Individual Scorers ────────────────────────────────────────────────

    def _score_profile_completeness(self, profile: models.Profile) -> float:
        """Max 20 points — based on profile fields filled in."""
        score = 0.0
        if profile.fullName and len(profile.fullName.strip()) > 2:
            score += 4.0
        if profile.headline and len(profile.headline.strip()) > 5:
            score += 4.0
        if profile.bio and len(profile.bio.strip()) > 20:
            score += 4.0
        if profile.avatar_url:
            score += 4.0
        if profile.technical_summary and len(profile.technical_summary.strip()) > 20:
            score += 2.0
        if profile.career_overview and len(profile.career_overview.strip()) > 20:
            score += 2.0
        return min(20.0, score)

    def _score_github_activity(self, github: models.GitHubAccount) -> float:
        """Max 25 points — based on GitHub follower/repo/commit counts."""
        if not github:
            return 0.0
        score = 0.0
        # Followers (max 8 pts)
        if github.followers_count >= 500:
            score += 8.0
        elif github.followers_count >= 100:
            score += 6.0
        elif github.followers_count >= 25:
            score += 4.0
        elif github.followers_count >= 5:
            score += 2.0
        # Total commits (max 9 pts)
        if github.total_commits >= 1000:
            score += 9.0
        elif github.total_commits >= 500:
            score += 7.0
        elif github.total_commits >= 200:
            score += 5.0
        elif github.total_commits >= 50:
            score += 3.0
        elif github.total_commits >= 10:
            score += 1.0
        # Recent events presence (max 8 pts)
        events = github.events_data or []
        unique_event_days = len(set(
            e.get("created_at", "")[:10] for e in events if e.get("created_at")
        ))
        if unique_event_days >= 14:
            score += 8.0
        elif unique_event_days >= 7:
            score += 6.0
        elif unique_event_days >= 3:
            score += 4.0
        elif unique_event_days >= 1:
            score += 2.0
        return min(25.0, score)

    def _score_repository_quality(self, github: models.GitHubAccount) -> float:
        """Max 20 points — based on stars, topics, README, languages."""
        if not github or not github.repositories:
            return 0.0
        score = 0.0
        total_stars = sum(r.stars_count or 0 for r in github.repositories)
        repos_with_topics = sum(1 for r in github.repositories if r.topics)
        repos_with_readme = sum(1 for r in github.repositories if r.readme_content and len(r.readme_content) > 50)
        repo_count = len(github.repositories)

        # Stars (max 8 pts)
        if total_stars >= 500:
            score += 8.0
        elif total_stars >= 100:
            score += 6.0
        elif total_stars >= 25:
            score += 4.0
        elif total_stars >= 5:
            score += 2.0

        # Topics coverage (max 6 pts) — indicates good repo metadata
        topic_ratio = repos_with_topics / max(repo_count, 1)
        score += topic_ratio * 6.0

        # README quality (max 6 pts)
        readme_ratio = repos_with_readme / max(repo_count, 1)
        score += readme_ratio * 6.0

        return min(20.0, score)

    def _score_skill_diversity(self, profile: models.Profile, github: models.GitHubAccount) -> float:
        """Max 15 points — unique languages and technologies."""
        skill_set = set(s.name.lower() for s in profile.skills) if profile.skills else set()

        # Add GitHub languages
        if github:
            for repo in github.repositories:
                for lang in (repo.languages or {}).keys():
                    skill_set.add(lang.lower())

        count = len(skill_set)
        if count >= 15:
            return 15.0
        elif count >= 10:
            return 12.0
        elif count >= 7:
            return 9.0
        elif count >= 4:
            return 6.0
        elif count >= 2:
            return 3.0
        return 0.0

    def _score_resume_completeness(self, profile: models.Profile) -> float:
        """Max 10 points — resume sections present."""
        score = 0.0
        if profile.educations:
            score += 3.0
        if profile.experiences:
            score += 3.0
        if profile.certifications:
            score += 2.0
        if profile.resume_raw_text and len(profile.resume_raw_text) > 100:
            score += 2.0
        return min(10.0, score)

    def _score_achievements(self, profile: models.Profile) -> float:
        """Max 5 points — number of achievements."""
        count = len(profile.achievements) if profile.achievements else 0
        if count >= 5:
            return 5.0
        elif count >= 3:
            return 3.5
        elif count >= 1:
            return 2.0
        return 0.0

    def _score_contribution_frequency(self, github: models.GitHubAccount) -> float:
        """Max 5 points — unique active days in last 90 events."""
        if not github:
            return 0.0
        events = github.events_data or []
        unique_days = len(set(
            e.get("created_at", "")[:10] for e in events if e.get("created_at")
        ))
        if unique_days >= 30:
            return 5.0
        elif unique_days >= 15:
            return 4.0
        elif unique_days >= 7:
            return 3.0
        elif unique_days >= 3:
            return 2.0
        elif unique_days >= 1:
            return 1.0
        return 0.0

    def _get_rank(self, score: float) -> str:
        for threshold, rank in self.RANK_THRESHOLDS:
            if score >= threshold:
                return rank
        return "Beginner"
