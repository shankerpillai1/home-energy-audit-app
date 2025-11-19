from sqlalchemy import Column, String, Float, TIMESTAMP, func
from sqlalchemy.exc import SQLAlchemyError
from config.server_config import Base, engine, SessionLocal
from models.sqlalchemy_models import UserData

# ---------- SQLAlchemy UserData Model ----------
'''
class UserData(Base):
    __tablename__ = "UserData"

    userID = Column(String(64), primary_key=True)  # matches SQL schema
    zipCode = Column(String(16))
    energyCompany = Column(String(255))
    suggestedBudget = Column(Float)

    createdAt = Column(
        TIMESTAMP, server_default=func.current_timestamp()
    )
    updatedAt = Column(
        TIMESTAMP,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )
'''


# Create the table (if it doesn’t already exist)
#Base.metadata.create_all(bind=engine)


# ---------- Database Utility Functions ----------
def get_user(user_id: str):
    """Retrieve user profile by userID."""
    session = SessionLocal()
    try:
        return session.query(UserData).filter_by(userID=user_id).first()
    except SQLAlchemyError as e:
        print(f"[DB] get_user error: {e}")
        return None
    finally:
        session.close()


def create_user(user_id: str, zip_code: str = None,
                energy_company: str = None, suggested_budget: float = None):
    """
    Insert a new user profile only if it doesn't already exist.
    """
    session = SessionLocal()
    try:
        existing = session.query(UserData).filter_by(userID=user_id).first()
        if existing:
            return False  # user already exists

        new_user = UserData(
            userID=user_id,
            zipCode=zip_code,
            energyCompany=energy_company,
            retrofitBudget=suggested_budget
        )

        session.add(new_user)
        session.commit()
        print(f"[DB] User created: {user_id}")
        return True

    except SQLAlchemyError as e:
        session.rollback()
        print(f"[DB] create_user error: {e}")
        return False
    finally:
        session.close()