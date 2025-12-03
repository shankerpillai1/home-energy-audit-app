from sqlalchemy import Column, String, Float, TIMESTAMP, func
from sqlalchemy.exc import SQLAlchemyError
from backend.config.server_config import Base, engine, SessionLocal
from backend.models.sqlalchemy_models import UserData
from backend.services.reflections_utils import model_to_dict



# Create the table (if it doesn’t already exist)
#Base.metadata.create_all(bind=engine)


# ---------- Database Utility Functions ----------
def get_user(user_id: str):
    session = SessionLocal()
    try:
        user = session.query(UserData).filter_by(userID=user_id).first()
        return model_to_dict(user) if user else None
    finally:
        session.close()


def create_user(user_id: str, zip_code: str = None,
                energy_company: str = None, suggested_budget: float = None):
    """
    Reflection-based safe user creation.
    Auto-filters only valid database columns.
    """
    session = SessionLocal()
    try:
        existing = session.query(UserData).filter_by(userID=user_id).first()
        if existing:
            return False  # user already exists

        
        payload = {
            "userID": user_id,
            "zipCode": zip_code,
            "energyCompany": energy_company,
            "retrofitBudget": suggested_budget
        }

        
        valid_columns = {
            col.key for col in inspect(UserData).mapper.column_attrs
        }

        
        filtered_payload = {
            k: v for k, v in payload.items()
            if k in valid_columns and v is not None
        }

        new_user = UserData(**filtered_payload)

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