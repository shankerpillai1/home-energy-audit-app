# Backend Developer Deep Dive (Addendum)

This addendum complements the main developer deep dive. It focuses on the python API server as well as the structure of the MySQL and MongoDB databases. 

## Directory Tree (`backend/`)

```
lib/
├─ main.py
├─ APIs/
│  ├─ leakage_task_api.py
│  └─ login_api.py
├─ config/
│  ├─ server_config.py
│  ├─ sql_database_config.py
│  └─ home_energy_audit_app_database.sql
├─ models/
│  └─ sqlalchemy_models.py
└─ services/
   ├─ db.py
   └─ mock_analysis.py
```

## Key Dependencies

*   **`uuid`**: For generating unique IDs for new data models like `TodoItem`.
*   **`sqlalchemy`**: For mapping data structures between MySQL database and task jsons.
*   **`pymongo`**: For Python interfacing with MongoDB.
*   **`gridfs`**: For chunking images such that they can be stored in MongoDB database.
*   **`fastapi`**: For servers API methods.
*   **`uvicorn`**: For servers HTTP requests and response handling.

## API Requests

*   **`post("/login")`**: Authenciates user via GoogleAuth upon login.
*   **`post("/update_profile")`**: Updates MySQL database with profile settings.
*   **`post("/detect_leak")`**: Uploads leakage_task json to MySQL database using sqlalchemy and uploads leakage_task images to MongoDB database using Gridfs. Then calls mock_analysis.py on uploaded leakage_task.
*   **`get("/detect_leak/{job_id}")`**: Returns job status for given job_id. It also returns leakage_task report with report image if job status is done.

## Server Setup

*   MySQL Workbench Installed
*   MongoDB Compass Installed
*   Update MONGO_URL and SQL_URL in backend/config/server_config.py to match local setup

### Build & Launch Server 

*   **Navigate to** \backend
*   **Run:** `python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000`

## MySQL Database





## MongoDB Database

*   Stores all images using GridFS to chunk images into storable units.
*   Images can then be obtained by the image name as such `mongofs.get(ObjectId(task.reportPhotoID))`. This returns the image in chunks which can the be converted to base64 and returned to the app as is done in `leakage_task_api.py`.
*   `server_config.py` initalizes the communication between this database and the server using pymongo.

### MongoDB Setup

*   Once MongoDB Compass is installed create a new connection that can be named anything.
*   Obtain this connections connection string by right clicking on it and update MONGO_URL in backend/config/server_config.py to match it
*   Create database on MongoDB Compass within this connection named LeakageImages
*   Once app is running create leakage task and submit it for analysis. You should see two new collections called fs.chunks and fs.files if this database is working properly.

## GoogleAuth Setup

