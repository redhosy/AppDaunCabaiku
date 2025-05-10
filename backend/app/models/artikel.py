from sqlalchemy import Integer, String, Column, Date, DateTime
from datetime import date
import datetime
from config import Base


class Artikel(Base):
    __tablename__ = "artikel"

    id_artikel = Column(Integer, primary_key=True, index=True)
    judul = Column(String, nullable=False)
    isi = Column(String, nullable=False)
    penulis = Column(String, nullable=False)
    tanggal = Column(Date, default = date.today)
    kategori = Column(String, nullable=False)
    gambar = Column(String, nullable=False)
    create_date = Column(DateTime, default=datetime.datetime.now())
    update_date = Column(DateTime)