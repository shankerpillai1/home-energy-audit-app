from fastapi import FastAPI, Request, HTTPException
from google.oauth2 import id_token
from google.auth.transport import requests

from backend.APIs.login_api import app as login_app
from backend.APIs.leakage_task_api import app as leakage_app
from backend.models.sqlalchemy_models import Base
from backend.config.server_config import engine   

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Combined Home Energy API")



@app.middleware("http")
async def verify_google_token_middleware(request: Request, call_next):
    """
    Verifies Google ID token for ALL routes except /auth/login
    """
   
    if request.url.path.startswith("/auth/login"):
        return await call_next(request)

    auth_header = request.headers.get("Authorization")

    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")

    token = auth_header.replace("Bearer ", "")

    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request())

  
        request.state.user = {
            "uid": idinfo.get("sub"),
            "email": idinfo.get("email")
        }

    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired Google ID token")

    return await call_next(request)


app.mount("/auth", login_app)
app.mount("/leakage", leakage_app)


@app.get("/")
def root(request: Request):
    return {
        "status": "running combined secure server",
        "user": request.state.user["uid"]
    }