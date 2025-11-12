from sqlalchemy import Column, Integer, String
from sqlalchemy.exc import SQLAlchemyError
from config.server_config import Base, engine, SessionLocal

# ---------- SQLAlchemy User Model ----------
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(255), unique=True, nullable=False)


# Create the table (if it doesn’t already exist)
Base.metadata.create_all(bind=engine)


# ---------- Database Utility Functions ----------
def get_user(email: str):
    """Retrieve a user by email."""
    session = SessionLocal()
    try:
        return session.query(User).filter_by(user_id=email).first()
    except SQLAlchemyError as e:
        print(f"[DB] get_user error: {e}")
        return None
    finally:
        session.close()


def create_user(email: str):
    """Insert a new user into the database if it doesn't already exist."""
    session = SessionLocal()
    try:
        existing = session.query(User).filter_by(user_id=email).first()
        if existing:
            return False  # already exists
        new_user = User(user_id=email)
        session.add(new_user)
        session.commit()
        print(f"[DB] User created: {email}")
        return True
    except SQLAlchemyError as e:
        session.rollback()
        print(f"[DB] create_user error: {e}")
        return False
    finally:
        session.close()