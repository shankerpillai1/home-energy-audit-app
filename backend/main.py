from fastapi import FastAPI
from backend.APIs.login_api import app as login_app
from backend.APIs.leakage_task_api import app as leakage_app
from backend.models.sqlalchemy_models import Base
from backend.config.server_config import engine   

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Combined Home Energy API")

app.mount("/auth", login_app)
app.mount("/leakage", leakage_app)

@app.get("/")
def root():
    return {"status": "running combined server"}
