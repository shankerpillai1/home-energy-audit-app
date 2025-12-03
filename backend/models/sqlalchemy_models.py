import enum
from sqlalchemy import Column, String, Float, Enum, JSON, ForeignKey
from sqlalchemy.orm import relationship
from backend.config.server_config import Base, engine

class TaskType(str, enum.Enum):
    window = "window"
    door = "door"
    wall = "wall"

class TaskState(str, enum.Enum):
    open = "open"
    closed = "closed"
    draft = "draft"

class TaskDecision(str, enum.Enum):
    no_decision = "no_decision"
    archived = "archived"
    todo = "todo"

class LeakageTask(Base):
    __tablename__ = "LeakageTask"

    taskID = Column(String(64), primary_key=True)
    userID = Column(String(64))
    title = Column(String(255))
    type = Column(Enum(TaskType))
    state = Column(Enum(TaskState))
    decision = Column(Enum(TaskDecision), default=TaskDecision.no_decision, nullable=False)
    closedResult = Column(String(255))
    insideTemp = Column(Float)
    outsideTemp = Column(Float)
    RGBphotoIDs = Column(JSON)
    thermalPhotoIDs = Column(JSON)
    leakSeverity = Column(String(64))
    energyLossValue = Column(Float)
    energyLossCost = Column(Float)
    savingsPercent = Column(Float)
    savingsCost = Column(Float)
    reportPhotoID = Column(String(64))

    suggestions = relationship("Suggestion", backref="task", cascade="all, delete-orphan")

class Suggestion(Base):
    __tablename__ = "Suggestion"

    suggestionID = Column(String(64), primary_key=True)
    taskID = Column(String(64), ForeignKey("LeakageTask.taskID"))
    title = Column(String(255))
    subtitle = Column(String(255))
    difficulty = Column(String(64))
    costRange = Column(String(64))
    estimatedReduction = Column(String(64))
    lifetime = Column(String(64))

from sqlalchemy import TIMESTAMP, func

class UserData(Base):
    __tablename__ = "UserData"

    userID = Column(String(64), primary_key=True)
    zipCode = Column(String(16))
    energyCompany = Column(String(255))
    retrofitBudget = Column(String(64))
    ownership = Column(String(32))
    appliances = Column(JSON)

    createdAt = Column(
        TIMESTAMP,
        server_default=func.current_timestamp()
    )
    updatedAt = Column(
        TIMESTAMP,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )