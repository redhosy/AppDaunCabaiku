from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship
from config import Base
import datetime # Pastikan ini diimpor

class Users(Base):
    __tablename__ = "users"

    id_user = Column(Integer, primary_key=True, index=True, autoincrement=True) 
    nama = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False) 
    password = Column(String, nullable=False)
    image = Column(String, nullable=True, default=None) 
    create_date = Column(DateTime, default=datetime.datetime.utcnow) 
    update_date = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow) 

    diagnosa = relationship("Diagnosa", back_populates="users")