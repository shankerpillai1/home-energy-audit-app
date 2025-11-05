from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from pymongo import MongoClient
import gridfs

# ---------- Database setup ----------
MONGO_URI = "mongodb://localhost:27017"
DB_NAME = "user_images_db"

client = MongoClient(MONGO_URI)
db = client[DB_NAME]
fs = gridfs.GridFS(db)

app = FastAPI()

# ---------- Routes ----------
@app.post("/upload-image")
async def upload_image(file: UploadFile = File(...)):
    try:
        # Read file content into memory
        contents = await file.read()

        # Save to GridFS
        file_id = fs.put(contents, filename=file.filename, content_type=file.content_type)
        print(f"Saved file {file.filename} with ID {file_id}")

        return JSONResponse({
            "status": "success",
            "file_id": str(file_id),
            "filename": file.filename,
            "content_type": file.content_type
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/get-image/{file_id}")
async def get_image(file_id: str):
    try:
        # Retrieve file from GridFS
        file_obj = fs.get(file_id)
        return JSONResponse({
            "filename": file_obj.filename,
            "length": file_obj.length,
            "content_type": file_obj.content_type
        })
    except Exception as e:
        raise HTTPException(status_code=404, detail="Image not found")