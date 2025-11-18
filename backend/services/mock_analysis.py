import time
import random
import uuid

from config.server_config import SessionLocal
from models.sqlalchemy_models import LeakageTask, Suggestion

JOBS = {}

class JobStatus(str):
    queued = "queued"
    processing = "processing"
    done = "done"
    error = "error"

def run_analysis(job_id: str):
    session = SessionLocal()
    try:
        JOBS[job_id]["status"] = JobStatus.processing

        time.sleep(3)

        analysis_result = {
            "leakSeverity": "Moderate",
            "energyLossValue": 15.8, 
            "energyLossCost": 142.0,
            "savingsPercent": 19,
            "savingsCost": 31.0,
            "suggestions": [
                {
                    "suggestionID": str(uuid.uuid4()),
                    "title": "Weatherstripping",
                    "subtitle": "Seal around window frame",
                    "difficulty": "Easy",
                    "costRange": "$10–20",
                    "estimatedReduction": "50–70%",
                    "lifetime": "3–5 years" 
                }
                for i in range(random.randint(1, 5))
            ]
        }

        task = session.query(LeakageTask).filter_by(taskID=JOBS[job_id]["task"]).first()
        if task:
            reportPhotoID = None
            if len(task.RGBphotoIDs) != 0:
                reportPhotoID = task.RGBphotoIDs[0]
            elif len(task.thermalPhotoIDs) != 0:
                reportPhotoID = task.thermalPhotoIDs[0]

            task.state = "open"
            task.leakSeverity = analysis_result["leakSeverity"]
            task.energyLossValue = analysis_result["energyLossValue"]
            task.energyLossCost = analysis_result["energyLossCost"]
            task.savingsPercent = analysis_result["savingsPercent"]
            task.savingsCost = analysis_result["savingsCost"] 
            task.reportPhotoID = reportPhotoID

            for s in analysis_result["suggestions"]:
                suggestion = Suggestion(taskID=task.taskID, **s) 
                task.suggestions.append(suggestion)

            session.commit()

        JOBS[job_id]["status"] = JobStatus.done

    except Exception as e:
        session.rollback()
        JOBS[job_id]["status"] = JobStatus.error
        JOBS[job_id]["error"] = str(e) 

    finally:
        session.close()
