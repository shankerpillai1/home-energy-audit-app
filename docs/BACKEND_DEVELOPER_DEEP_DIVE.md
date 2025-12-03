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

*   Install MySQL Workbench
*   Install MongoDB Compass
*   Update MONGO_URL and SQL_URL in backend/config/server_config.py to match local setup

### Build & Launch Server 

*   **Run:** `python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000`

## MySQL Database

The MySQL database serves as the **primary structured data store** for the Home Energy Audit app. It stores all persistent application data related to users, leakage detection tasks, and future tasks/data. The database is initialized and accessed using **SQLAlchemy ORM**, which provides a Python-based abstraction over raw SQL.

All database configuration and initialization is handled in: backend/config/server_config.py
This file defines:
- The MySQL connection URL (`SQL_URL`)
- The database name (`SQL_DATABASE_NAME`)
- The SQLAlchemy `engine`
- The `SessionLocal` factory
- The declarative `Base` used by all models

On server startup, the SQL schema is automatically created using:

```python
run_sql_script(SQL_URL, SQL_DATABASE_NAME, "config/home_energy_audit_app_database.sql")
```

#### Database Tables & Data Models

The database consists of two core tables:

---

##### 1. `UserData` — User Profiles

Stores user-specific information collected during onboarding and profile updates.

**Table Purpose:**
- Stores profile information tied to a unique `userID`
- Updated through the `/update_profile` endpoint
- Created automatically on first login through `/login`

**Key Columns:**
- `userID` (Primary Key)
- `zipCode`
- `energyCompany`
- `retrofitBudget`
- `ownership`
- `appliances` (JSON)
- `createdAt`, `updatedAt` (Automatic timestamps)

##### 2. `LeakageTask`

Stores all leakage detection job submissions and related data fields

**Table Purpose:**
- Linked to a LeakageTask via taskID
- Stores recommended fix information and energy reduction estimates

**SQLAlchemy Model:**
```python
class LeakageTask(Base):
    __tablename__ = "LeakageTask"

    taskID = Column(String(64), primary_key=True)
    userID = Column(String(64))
    title = Column(String(255))
    type = Column(Enum(TaskType))
    state = Column(Enum(TaskState))
    decision = Column(Enum(TaskDecision), default=TaskDecision.no_decision, nullable=False)
    insideTemp = Column(Float)
    outsideTemp = Column(Float)
    RGBphotoIDs = Column(JSON)
    thermalPhotoIDs = Column(JSON)
    reportPhotoID = Column(String(64))

    suggestions = relationship("Suggestion", backref="task", cascade="all, delete-orphan")
```




## MongoDB Database

*   Stores all images using GridFS to chunk images into storable units.
*   Images can then be obtained by the image name as such `mongofs.get(ObjectId(task.reportPhotoID))`. This returns the image in chunks which can the be converted to base64 and returned to the app as is done in `leakage_task_api.py`.
*   `server_config.py` initalizes the communication between this database and the server using pymongo.

### MongoDB Setup

*   Once MongoDB Compass is installed create a new connection that can be named anything.
*   Obtain this connections connection string by right clicking on it and update MONGO_URL in backend/config/server_config.py to match it
*   Create database on MongoDB Compass within this connection named LeakageImages
*   Once app is running create leakage task and submit it for analysis. You should see two new collections called fs.chunks and fs.files if this database is working properly.








