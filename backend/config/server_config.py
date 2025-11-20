from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import pymongo
import gridfs

LEAKAGE_TASK_DATABASE_URL = "mysql+pymysql://root:CS1980Capstone@localhost/home_energy_audit_app_database"
MONGO_URL = "mongodb://localhost:27017/"
MONGODB_NAME = "LeakageImages"

engine = create_engine(LEAKAGE_TASK_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)
Base = declarative_base()

myclient = pymongo.MongoClient(MONGO_URL)
mongoDB = myclient[MONGODB_NAME]
mongofs = gridfs.GridFS(mongoDB)
