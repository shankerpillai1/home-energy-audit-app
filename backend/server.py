import json
from typing import List
from fastapi import FastAPI, UploadFile, File, Form, BackgroundTasks, HTTPException, Request
import os
import uuid
from bson import ObjectId
import base64

from config.server_config import SessionLocal, mongofs
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
    task_id = task.get("id")
    if not task_id:
        raise HTTPException(400, "Missing taskID/taskId/id in task_json")
 
    job_id = str(uuid.uuid4())

    media_files: List[UploadFile] = [
        file for key, file in form.items() if key.startswith("media")
    ]

    saved_rgb_files = []
    saved_thermal_files = []
    for file in media_files:
        filename = f"{job_id}_{file.filename}"

        file_bytes = await file.read()

        file_id = mongofs.put(
            file_bytes,
            filename=filename,
            content_type=file.content_type
        )

        if "_rgb." in filename:
            saved_rgb_files.append(str(file_id))

        if "_thermal." in filename:
            saved_thermal_files.append(str(file_id))

    JOBS[job_id] = {"status": JobStatus.queued, "task": task_id, "report": None}

    session = SessionLocal()
    try:
        existing = session.query(LeakageTask).filter_by(taskID=task_id).first()

        if existing:
            session.delete(existing)
            session.commit()

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
        normalized_task["RGBphotoIDs"] = saved_rgb_files
        normalized_task["thermalPhotoIDs"] = saved_thermal_files
        normalized_task["leakSeverity"] = None
        normalized_task["energyLossValue"] = None
        normalized_task["energyLossCost"] = None
        normalized_task["savingsPercent"] = None
        normalized_task["savingsCost"] = None
        normalized_task["reportPhotoID"] = None

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
        session = SessionLocal()
        try:
            task = session.query(LeakageTask).filter_by(taskID=JOBS[job_id]["task"]).first()
            if not task:
                raise HTTPException(status_code=404, detail="Task not found")
           
            report = {
                "taskID": task.taskID,
                "leakSeverity": task.leakSeverity,
                "energyLossValue": task.energyLossValue,
                "energyLossCost": task.energyLossCost,
                "savingsPercent": task.savingsPercent,
                "savingsCost": task.savingsCost,
                "imagePath": f"{task.taskID}_analysis_image.jpg",
                "thumbPath": f"{task.taskID}_analysis_image.jpg",
                "suggestions": [
                    {
                        "suggestionID": s.suggestionID,
                        "title": s.title,
                        "subtitle": s.subtitle,
                        "difficulty": s.difficulty,
                        "costRange": s.costRange,
                        "estimatedReduction": s.estimatedReduction,
                        "lifetime": s.lifetime
                    }
                    for s in task.suggestions]}

            if not task.reportPhotoID:
                return {"status": "done", "report": report, "image": None}
            
            try:
                grid_file = mongofs.get(ObjectId(task.reportPhotoID))
                image_bytes = grid_file.read()

                print(grid_file.filename)

                b64_image = base64.b64encode(image_bytes).decode("utf-8")

                return {"status": "done", 
                        "report": report, 
                        "image": {"filename": f"{task.taskID}_analysis_image.jpg", "data": b64_image}
                        }

            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Failed to load image {e}")
           
        finally:
            session.close()

    elif job["status"] == JobStatus.error:
        return {"status": "error", "error": job.get("error", "Unknown")}
    else:
        return {"status": job["status"]}

@app.get("/")
def root():
    return {"status": "server running"}
