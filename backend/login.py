from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests
import db  # Import our new db helper

app = FastAPI()

# Initialize DB on startup
db.init_db()

class LoginRequest(BaseModel):
    id_token: str
    uid: str  # Google email


@app.post("/login")
async def login_user(data: LoginRequest):
    try:
        # Verify the Google ID token
        idinfo = id_token.verify_oauth2_token(data.id_token, requests.Request())

        # Check that the token's email matches the provided UID
        token_email = idinfo.get("email")
        if not token_email or token_email != data.uid:
            raise HTTPException(status_code=401, detail="Email mismatch or invalid token")

        # Check if user exists, otherwise create
        user = db.get_user(data.uid)
        if not user:
            db.create_user(data.uid)
            action = "created"
        else:
            action = "exists"

        print(f"User {action}: {data.uid}")
        return {"status": "success", "user_id": data.uid, "action": action}

    except ValueError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server error: {e}")