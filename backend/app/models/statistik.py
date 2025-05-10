from sqlalchemy import  Column, Integer, ForeignKey,Date, DateTime
import datetime
from datetime import date 
from sqlalchemy.orm import relationship 
from config import Base


class Statistik(Base):
    __tablename__ = "statistik"
    id_statistik = Column(Integer, primary_key=True, index=True)
    id_user = Column(Integer, ForeignKey("users.id_user"))
    tanggal = Column(Date, default = date.today)
    total_sehat = Column(Integer, default=0)
    total_kuning = Column(Integer, default=0)
    total_keriting = Column(Integer, default=0)
    create_date = Column(DateTime, default=datetime.datetime.now())
    update_date = Column(DateTime)

    users = relationship("Users", back_populates="statistik")