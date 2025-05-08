from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship 
from app.schemas.user import CreateUser
from app.database import Base


class Users(Base):
    __tablename__ = "users"

    id_user = Column(Integer, primary_key=True, index=True)
    nama = Column(String, nullable=True)
    email = Column(String, nullable=True)
    password = Column(String, nullable=True)

    diagnosa = relationship("Diagnosa", back_populates="users")
    statistik = relationship("Statistik", back_populates="users")

   
