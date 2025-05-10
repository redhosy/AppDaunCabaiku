from sqlalchemy import Column, Integer,Date, String, Enum, Float, ForeignKey, DateTime 
from sqlalchemy.orm import relationship
from config import Base
from enum import Enum as PyEnum
import datetime


class KondisiDaun(PyEnum):
        SEHAT = "sehat"
        KUNING = "daun kuning"
        KERITING = "daun keriting"

class Diagnosa(Base):
    __tablename__ = "diagnosa"

    id_diagnosa = Column(Integer, primary_key=True, index=True)
    id_user =Column(Integer, ForeignKey("users.id_user"))
    tanggal = Column(Date)
    jenis_penyakit = Column(String)
    image = Column(String)
    rekomendasi = Column(String)
    kategori = Column(Enum(KondisiDaun))
    akurasi = Column(Float)
    create_date = Column(DateTime, default=datetime.datetime.now())
    update_date = Column(DateTime)

    users = relationship("Users", back_populates="diagnosa")
