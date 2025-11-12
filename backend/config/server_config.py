from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

LEAKAGE_TASK_DATABASE_URL = "mysql+pymysql://root:CS1980Capstone@localhost/leakage_tasks_database"

engine = create_engine(LEAKAGE_TASK_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)
Base = declarative_base()