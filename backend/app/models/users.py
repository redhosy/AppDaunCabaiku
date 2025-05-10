from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship
from config import Base

import datetime

class Users(Base):
    __tablename__ = "users"

    id_user = Column(Integer, primary_key=True, index=True)
    nama = Column(String, nullable=True)
    email = Column(String, nullable=True)
    password = Column(String, nullable=True)
    google_id = Column(String, unique=True, nullable=True)
    create_date = Column(DateTime, default=datetime.datetime.now())
    update_date = Column(DateTime)

    diagnosa = relationship("Diagnosa", back_populates="users") 
    statistik = relationship("Statistik", back_populates="users") 
