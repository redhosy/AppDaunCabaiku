from sqlalchemy import Column, Integer, String, Date, Enum, Float, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base
from enum import Enum as PyEnum


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

    user = relationship("User", back_populates="diagnosa")
