# app/repository/diagnosa.py
from sqlalchemy.orm import Session
from app.models.diagnosa import Diagnosa, KondisiDaun
from app.schemas.diagnosa import DiagnosaCreate
from typing import List, Optional
from datetime import datetime
import logging
import time

logger = logging.getLogger(__name__)

# Fungsi untuk membuat diagnosa baru
def create_diagnosa(db: Session, diagnosa: DiagnosaCreate) -> Diagnosa:
    db_diagnosa = Diagnosa(
        id_user=diagnosa.id_user,
        tanggal=diagnosa.tanggal,
        jenis_penyakit=diagnosa.jenis_penyakit,
        image=diagnosa.image,
        rekomendasi=diagnosa.rekomendasi,
        kategori=KondisiDaun(diagnosa.kategori.upper()),
        akurasi=diagnosa.akurasi,
        create_date=datetime.utcnow()
    )
    db.add(db_diagnosa)
    db.commit()
    db.refresh(db_diagnosa)
    return db_diagnosa

# Fungsi untuk mendapatkan semua diagnosa (tanpa filter user)
def get_all_diagnosa(db: Session) -> List[Diagnosa]:
    return db.query(Diagnosa).all()

# FIX UTAMA: Fungsi untuk mendapatkan diagnosa berdasarkan user_id DENGAN PAGINATION
def get_diagnosa_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 10) -> List[Diagnosa]: # FIX: Tambahkan parameter skip dan limit
    start_time = time.time()
    logger.info(f"Mengambil diagnosa untuk user_id: {user_id} (skip={skip}, limit={limit})")
    # FIX: Terapkan offset dan limit pada query SQLAlchemy
    result = db.query(Diagnosa).filter(Diagnosa.id_user == user_id).offset(skip).limit(limit).all()
    logger.info(f"Pengambilan diagnosa untuk user_id {user_id} selesai dalam: {time.time() - start_time:.4f} detik. Ditemukan {len(result)} item.")
    return result

# Fungsi untuk mendapatkan satu diagnosa berdasarkan ID
def get_diagnosa_by_id(db: Session, diagnosa_id: int) -> Optional[Diagnosa]:
    return db.query(Diagnosa).filter(Diagnosa.id_diagnosa == diagnosa_id).first()

# Fungsi untuk menghapus diagnosa
def delete_diagnosa(db: Session, diagnosa_id: int) -> bool:
    diagnosa = db.query(Diagnosa).filter(Diagnosa.id_diagnosa == diagnosa_id).first()
    if diagnosa:
        db.delete(diagnosa)
        db.commit()
        return True
    return False