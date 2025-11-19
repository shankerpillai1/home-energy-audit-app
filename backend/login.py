from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests

# Import your updated db functions (UserData)
from services import db  

app = FastAPI(title="User Login Service")


# ---------- Request Model ----------
class LoginRequest(BaseModel):
    id_token: str
    uid: str   # Google userID (email or Google UID)


# ---------- Routes ----------
@app.post("/login")
async def login_user(data: LoginRequest):
    """
    Validate Google Sign-In token and ensure the user exists in the database.
    """
    try:
        # --- Verify Google ID token ---
        idinfo = id_token.verify_oauth2_token(data.id_token, requests.Request())
        if not idinfo:
            raise HTTPException(status_code=401, detail="Invalid Google ID token")

        # NOTE:
        # You no longer require the Google token email to match the uid.
        # The only identity for your backend is "uid".

        # --- Fetch or create user in UserData table ---
        user = db.get_user(data.uid)
        if not user:
            # user does not exist → create with blank optional data
            db.create_user(
                user_id=data.uid,
                zip_code=None,
                energy_company=None,
                suggested_budget=None
            )
            action = "created"
        else:
            action = "exists"

        print(f"[LOGIN] User {action}: {data.uid}")

        return {
            "status": "success",
            "user_id": data.uid,
            "action": action
        }

    except ValueError as e:
        # Token is invalid
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server error: {e}")


@app.get("/")
def root():
    return {"status": "login service running"}