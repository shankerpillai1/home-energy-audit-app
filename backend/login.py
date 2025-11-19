from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests
from config.server_config import SessionLocal
from models.sqlalchemy_models import UserData
from sqlalchemy import func

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


class ProfileUpdate(BaseModel):
    userID: str
    zip: str | None = None
    ownership: str | None = None
    electricCompany: str | None = None
    budget: str | None = None
    appliances: list[str] | None = None


@app.post("/update_profile")
async def update_profile(data: ProfileUpdate):
    """
    Update a user's profile with IntroPage data.
    """
    session = SessionLocal()
    try:
        user = session.query(UserData).filter_by(userID=data.userID).first()
        if not user:
            raise HTTPException(404, "User not found")

        # Update fields only if present
        if data.zip is not None:
            user.zipCode = data.zip
        if data.electricCompany is not None:
            user.energyCompany = data.electricCompany
        if data.budget is not None:
            user.retrofitBudget = data.budget
        if data.ownership is not None:
            user.ownership = data.ownership
        if data.appliances is not None:
            user.appliances = data.appliances

        user.updatedAt = func.current_timestamp()

        session.commit()
        return {"status": "profile updated", "userID": user.userID}

    except Exception as e:
        session.rollback()
        raise HTTPException(500, f"Profile update failed: {e}")
    finally:
        session.close()


@app.get("/")
def root():
    return {"status": "login service running"}