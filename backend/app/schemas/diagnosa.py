from pydantic import BaseModel
from enum import Enum
from typing import Optional
from datetime import date


class KondisiDaun(str, enum):
    SEHAT = "sehat"
    KUNING = "daun kuning"
    KERITING = "daun keriting"

class DiagnosaCreate(BaseModel):
    tanggal: Optional[date] = None
    jenis_penyakit: str
    image: str
    rekomendasi: str
    kategori: KondisiDaun
    akurasi: float

class DiagnosaResponse(BaseModel):
    id_diagnosa: int
    id_user: int
    tanggal: date
    jenis_penyakit: str
    image: str
    rekomendasi: str
    kategori: KondisiDaun
    akurasi: float

