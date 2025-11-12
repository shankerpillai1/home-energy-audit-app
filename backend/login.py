from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests
from services import db  

app = FastAPI(title="User Login Service")

# ---------- Models ----------
class LoginRequest(BaseModel):
    id_token: str
    uid: str  # Google email


# ---------- Routes ----------
@app.post("/login")
async def login_user(data: LoginRequest):
    """
    Validate a Google ID token, verify the email, and create/retrieve user in the database.
    """
    try:
        # Verify the Google ID token
        idinfo = id_token.verify_oauth2_token(data.id_token, requests.Request())

        # Ensure token email matches provided UID
        token_email = idinfo.get("email")
        if not token_email or token_email != data.uid:
            raise HTTPException(status_code=401, detail="Email mismatch or invalid token")

        # Fetch or create user
        user = db.get_user(data.uid)
        if not user:
            db.create_user(data.uid)
            action = "created"
        else:
            action = "exists"

        print(f"[LOGIN] User {action}: {data.uid}")
        return {"status": "success", "user_id": data.uid, "action": action}

    except ValueError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server error: {e}")


@app.get("/")
def root():
    return {"status": "login service running"}