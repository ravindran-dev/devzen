from app.workers.celery_app import celery
from app.database import SessionLocal
from app.services.github_sync import GitHubSyncService
from app.services.ai_fusion import AIFusionService
from app import models
import logging

logger = logging.getLogger(__name__)

@celery.task(name="app.workers.tasks.sync_github_data_task")
def sync_github_data_task(github_account_id: int):
    logger.info(f"Starting background GitHub sync for account ID: {github_account_id}")
    db = SessionLocal()
    try:
        sync_service = GitHubSyncService(db)
        sync_service.sync_user_repositories(github_account_id)
        
        # Once sync is complete, automatically trigger the AI Fusion auditor
        account = db.query(models.GitHubAccount).filter(models.GitHubAccount.id == github_account_id).first()
        if account and account.user.profile:
            audit_profile_fusion_task.delay(account.user.profile.id)
            
        logger.info(f"Successfully synced GitHub data for account ID: {github_account_id}")
    except Exception as e:
        logger.error(f"Error syncing GitHub details: {str(e)}")
    finally:
        db.close()

@celery.task(name="app.workers.tasks.audit_profile_fusion_task")
def audit_profile_fusion_task(profile_id: int):
    logger.info(f"Starting AI Fusion profiling for profile ID: {profile_id}")
    db = SessionLocal()
    try:
        fusion_service = AIFusionService(db)
        suggestions = fusion_service.generate_fusion_suggestions(profile_id)
        logger.info(f"Completed profiling for profile ID {profile_id}. Detected {len(suggestions)} sync recommendations.")
    except Exception as e:
        logger.error(f"Error auditing AI fusion: {str(e)}")
    finally:
        db.close()

@celery.task(name="app.workers.tasks.periodic_sync_all_accounts_task")
def periodic_sync_all_accounts_task():
    logger.info("Executing periodic background synchronization check for all accounts...")
    db = SessionLocal()
    try:
        accounts = db.query(models.GitHubAccount).all()
        for account in accounts:
            sync_github_data_task.delay(account.id)
        logger.info(f"Queued sync tasks for {len(accounts)} developer accounts.")
    except Exception as e:
        logger.error(f"Error running periodic syncs: {str(e)}")
    finally:
        db.close()
