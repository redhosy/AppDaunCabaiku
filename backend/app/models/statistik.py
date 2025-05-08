from sqlalchemy import String, Column, Integer, ForeignKey, Date
from datetime import date 
from sqlalchemy.orm import relationship 
from app.database import Base


class statistik(Base):
    __tablename__ = "statistik"
    id_statistik = Column(Integer, primary_key=True, index=True)
    id_user = Column(Integer, ForeignKey("users.id_user"))
    tanggal = Column(Date, default = date.today)
    total_sehat = Column(Integer, default=0)
    total_kuning = Column(Integer, default=0)
    total_keriting = Column(Integer, default=0)

    user = relationship("User", back_populates="statistik")