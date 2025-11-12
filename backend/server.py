import json
from typing import List
from fastapi import FastAPI, UploadFile, File, Form, BackgroundTasks, HTTPException, Request
import os
import uuid

from config.server_config import SessionLocal
from models.sqlalchemy_models import LeakageTask, Suggestion 
from services.mock_analysis import run_analysis, JobStatus, JOBS

#API
app = FastAPI(title="Home Energy Audit API")

UPLOAD_DIR = "uploaded_media"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/detect_leak") 
async def detect_leak(
    request: Request,
    background_tasks: BackgroundTasks,
    uid: str = Form(...),
    task_json: str = Form(...),
    media: List[UploadFile] = File(default=[])
):
    form = await request.form()

    task = json.loads(task_json)
    task_id = task.get("taskID") or task.get("taskId") or task.get("id") 
    if not task_id:
        raise HTTPException(400, "Missing taskID/taskId/id in task_json")
 
    job_id = str(uuid.uuid4())

    media_files: List[UploadFile] = [
        file for key, file in form.items() if key.startswith("media")
    ]

    saved_files = []
    for file in media_files:
        filename = f"{uuid.uuid4()}_{file.filename}"
        filepath = os.path.join(UPLOAD_DIR, filename) 

        with open(filepath, "wb") as f:
            f.write(await file.read())

        saved_files.append(filepath)
 
    JOBS[job_id] = {"status": JobStatus.queued, "task": task, "files": saved_files, "report": None}

    session = SessionLocal()
    try:
        existing = session.query(LeakageTask).filter_by(taskID=task_id).first()

        if not existing:
            normalized_task = {
                "taskID": task_id,
                "userID": uid, 
                "title": task.get("title") or "",
            }

            raw_type = task.get("type")
            normalized_task["type"] = raw_type if raw_type in ("window", "door", "wall") else None

            raw_state = task.get("state")
            normalized_task["state"] = raw_state if raw_state in ("open", "closed", "draft") else "draft" 

            normalized_task["decision"] = task.get("decision") or "no_decision"
            normalized_task["closedResult"] = task.get("closedResult")
            normalized_task["insideTemp"] = task.get("insideTemp")
            normalized_task["outsideTemp"] = task.get("outsideTemp") 
            normalized_task["RGBphotoIDs"] = task.get("RGBphotoIDs") or []
            normalized_task["thermalPhotoIDs"] = task.get("thermalPhotoIDs") or []
            normalized_task["leakSeverity"] = task.get("leakSeverity") 
            normalized_task["energyLossValue"] = task.get("energyLossValue")
            normalized_task["energyLossCost"] = task.get("energyLossCost") 
            normalized_task["savingsPercent"] = task.get("savingsPercent")
            normalized_task["savingsCost"] = task.get("savingsCost") 
            normalized_task["reportPhotoID"] = task.get("reportPhotoID")

            new_task = LeakageTask(**normalized_task)
            session.add(new_task)
            session.commit()

    finally:
        session.close()

    background_tasks.add_task(run_analysis, job_id)

    return {"jobId": job_id, "status": "queued"}


@app.get("/detect_leak/{job_id}")
def poll_job(job_id: str):
    if job_id not in JOBS:
        raise HTTPException(status_code=404, detail="Job not found")

    job = JOBS[job_id]

    if job["status"] == JobStatus.done:
        return {"status": "done", "report": job["report"]}
    elif job["status"] == JobStatus.error:
        return {"status": "error", "error": job.get("error", "Unknown")}
    else:
        return {"status": job["status"]}


@app.get("/")
def root():
    return {"status": "server running"}
