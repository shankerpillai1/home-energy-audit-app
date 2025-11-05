from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests
import mysql.connector
from mysql.connector import Error

app = FastAPI()

# ---------- Database Config ----------
DB_CONFIG = {
    "host": "localhost",      # or your MySQL host
    "user": "root",           # your MySQL username
    "password": "yourpassword",
    "database": "user_auth",  # database to store userIDs
}

def init_db():
    """Create the database and users table if they don't exist."""
    try:
        conn = mysql.connector.connect(
            host=DB_CONFIG["host"],
            user=DB_CONFIG["user"],
            password=DB_CONFIG["password"],
        )
        cur = conn.cursor()
        cur.execute("CREATE DATABASE IF NOT EXISTS user_auth")
        conn.commit()
        cur.close()
        conn.close()

        conn = mysql.connector.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id VARCHAR(255) UNIQUE NOT NULL
            )
        """)
        conn.commit()
        cur.close()
        conn.close()
    except Error as e:
        print(f"MySQL init error: {e}")

init_db()

# ---------- Models ----------
class LoginRequest(BaseModel):
    id_token: str
    uid: str  # already the Google email


# ---------- Routes ----------
@app.post("/login")
async def login_user(data: LoginRequest):
    try:
        # Verify the token (for validity and expiry)
        idinfo = id_token.verify_oauth2_token(data.id_token, requests.Request())

        # Basic safety: check that the token's email matches the passed UID
        token_email = idinfo.get("email")
        if token_email and token_email != data.uid:
            raise HTTPException(status_code=401, detail="Email mismatch")

        # Insert or ignore duplicate
        conn = mysql.connector.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute("INSERT IGNORE INTO users (user_id) VALUES (%s)", (data.uid,))
        conn.commit()
        cur.close()
        conn.close()

        print(f"User stored: {data.uid}")
        return {"status": "success", "user_id": data.uid}

    except ValueError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
    except Error as e:
        raise HTTPException(status_code=500, detail=f"MySQL error: {e}")