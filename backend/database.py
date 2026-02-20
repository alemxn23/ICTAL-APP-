from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Boolean, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
import datetime

SQLALCHEMY_DATABASE_URL = "sqlite:///./epilepsy_care.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    full_name = Column(String)
    age = Column(Integer)
    weight = Column(Float)
    terms_accepted = Column(Boolean, default=False)
    
    # Profile Data for Risk Calculation
    last_dose_time = Column(DateTime)
    medication_frequency_hours = Column(Integer, default=12)
    
    hrv_history = relationship("HRVHistory", back_populates="owner")

class HRVHistory(Base):
    __tablename__ = "hrv_history"

    id = Column(Integer, primary_key=True, index=True)
    vfc_value = Column(Float)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    user_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="hrv_history")

Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
