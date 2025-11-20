from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import pymongo
import gridfs
from config.sql_database_config import run_sql_script

SQL_URL = "mysql+pymysql://root:CS1980Capstone@localhost/"
SQL_DATABASE_NAME = "home_energy_audit_app_database"
MONGO_URL = "mongodb://localhost:27017/"
MONGODB_NAME = "LeakageImages"

run_sql_script(SQL_URL, SQL_DATABASE_NAME, "config/home_energy_audit_app_database.sql")

engine = create_engine(SQL_URL + SQL_DATABASE_NAME)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)
Base = declarative_base()

myclient = pymongo.MongoClient(MONGO_URL)
mongoDB = myclient[MONGODB_NAME]
mongofs = gridfs.GridFS(mongoDB)
