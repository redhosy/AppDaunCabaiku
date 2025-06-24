from pydantic import BaseModel, validator
from datetime import date, datetime
from typing import Optional

class DiagnosaBase(BaseModel):
    # Base class untuk field umum
    id_user: int
    tanggal: date
    jenis_penyakit: str
    image: str # Akan menyimpan nama file atau URL relatif
    rekomendasi: str
    kategori: str # Karena Enum di DB akan di-convert to string
    akurasi: float

    @validator('akurasi')
    def validate_akurasi(cls, v):
        # FIX: Asumsi akurasi 0-100 seperti di UI Flutter
        if not 0.0 <= v <= 100.0:
            raise ValueError('Akurasi harus antara 0.0 dan 100.0')
        return v
    
    @validator('kategori')
    def validate_kategori(cls, v):
        valid_categories = ["SEHAT", "KERITING", "KUNING"]
        if v.upper() not in valid_categories: # FIX: pastikan perbandingan uppercase
            raise ValueError(f'Kategori harus salah satu dari: {valid_categories}')
        return v.upper() # FIX: pastikan kategori disimpan dalam uppercase

class DiagnosaCreate(DiagnosaBase):
    # Tidak ada tambahan field untuk create
    pass

class DiagnosaResponse(DiagnosaBase):
    id_diagnosa: int # ID ini ada saat respons, tidak saat create
    create_date: datetime
    update_date: Optional[datetime] # Optional karena bisa null

    class Config:
        from_attributes = True # Dulu orm_mode = True
        # Untuk Date dan DateTime, Pydantic 2.x dengan from_attributes=True sudah handle serialisasi/deserialisasi