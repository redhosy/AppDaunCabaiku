from pydantic import BaseModel
from datetime import datetime

class ArtikelCreate(BaseModel):
    judul: str
    isi: str
    penulis: str
    tanggal: datetime
    kategori: str
    gambar: str

class ArtikelResponse(BaseModel):
    id_artikel: int
    judul: str
    isi: str
    penulis: str
    tanggal: datetime
    kategori: str
    gambar: str
