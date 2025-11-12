import mysql.connector
from mysql.connector import Error

DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "yourpassword",
    "database": "user_auth",
}

def init_db():
    """Initialize database and ensure the users table exists."""
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

        print("✅ Database initialized successfully.")
    except Error as e:
        print(f"MySQL init error: {e}")

def get_user(email: str):
    """Retrieve a user by email."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT * FROM users WHERE user_id = %s", (email,))
        user = cur.fetchone()
        cur.close()
        conn.close()
        return user
    except Error as e:
        print(f"MySQL get_user error: {e}")
        return None

def create_user(email: str):
    """Insert a new user into the database."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute("INSERT IGNORE INTO users (user_id) VALUES (%s)", (email,))
        conn.commit()
        cur.close()
        conn.close()
        print(f"✅ User created: {email}")
        return True
    except Error as e:
        print(f"MySQL create_user error: {e}")
        return False