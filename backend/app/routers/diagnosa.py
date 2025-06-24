# app/routers/diagnosa.py
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, status, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from app.machine_learning import model_loader, predictor
from app.schemas import diagnosa as diagnosa_schema
from app.repository import diagnosa as diagnosa_repo
from app.repository.users import get_current_user # Asumsi ini ada dan berfungsi
from app.models.users import Users # Asumsi ini ada
from app.models import diagnosa as diagnosa_model # Asumsi ini diimport untuk type hinting atau relasi
from config import get_db
import os
import logging
from datetime import datetime, date
import uuid
from typing import List, Optional

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/diagnosa", tags=["Diagnosa"])

# Global variable untuk track model loading status
models_loaded = False

async def load_models_on_startup():
    """Memuat model ML saat aplikasi startup."""
    global models_loaded
    try:
        logger.info("Memuat model ML...")
        model_loader.load_models()
        models_loaded = True
        logger.info("Model berhasil dimuat!")
    except Exception as e:
        logger.error(f"Gagal memuat model: {str(e)}", exc_info=True)
        models_loaded = False
        
def check_models_loaded():
    """Dependency untuk memastikan model ML sudah dimuat."""
    if not models_loaded:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
            detail="Model ML belum dimuat. Silakan coba beberapa saat lagi."
        )

# Base URL untuk gambar yang diunggah - PENTING: Sesuaikan dengan IP/domain server Anda
IMAGE_BASE_URL = "http://192.168.196.187:8000/uploads" # Ganti dengan IP server Anda

@router.post("/predict", response_model=diagnosa_schema.DiagnosaResponse, status_code=status.HTTP_201_CREATED)
async def predict_disease(
    file: UploadFile = File(..., description="File gambar untuk prediksi penyakit daun"),
    db: Session = Depends(get_db),
    current_user: Users = Depends(get_current_user), # Ini membutuhkan user yang terautentikasi
    _: None = Depends(check_models_loaded) # Pastikan model sudah dimuat
):
    file_path = None
    try:
        logger.info(f"User '{current_user.nama}' (ID: {current_user.id_user}) mencoba memprediksi gambar.")

        if not file.content_type or not file.content_type.startswith('image/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, 
                detail="File harus berupa gambar (jpg, png, dll)."
            )
        
        contents = await file.read() 
        
        if len(contents) > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="Ukuran file terlalu besar. Maksimal 10MB."
            )
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_id = uuid.uuid4().hex[:8]
        file_extension = os.path.splitext(file.filename)[1] or '.png'
        filename = f"diagnosa_{timestamp}_{unique_id}{file_extension}"
        
        upload_dir = "uploads"
        os.makedirs(upload_dir, exist_ok=True)
        file_path = os.path.join(upload_dir, filename)
        
        with open(file_path, "wb") as f:
            f.write(contents)
        
        logger.info(f"File gambar disimpan: {file_path}")
        
        logger.info("Memulai prediksi...")
        prediction_result = await predictor.predict_image(contents) 
        
        diagnosa_data = diagnosa_schema.DiagnosaCreate(
            id_user=current_user.id_user, # PENTING: ID user dari objek current_user
            tanggal=date.today(),
            jenis_penyakit=prediction_result["nama_penyakit"],
            image=filename,
            rekomendasi=prediction_result["rekomendasi"],
            kategori=prediction_result["kategori"].upper(),
            akurasi=prediction_result["akurasi"]
        )
        
        saved_diagnosis = diagnosa_repo.create_diagnosa(db, diagnosa_data)
        logger.info(f"Diagnosa berhasil disimpan untuk user ID: {saved_diagnosis.id_user} dengan ID Diagnosa: {saved_diagnosis.id_diagnosa}")
        
        response_image_url = f"{IMAGE_BASE_URL}/{saved_diagnosis.image}"
        
        response = diagnosa_schema.DiagnosaResponse(
            id_diagnosa=saved_diagnosis.id_diagnosa,
            id_user=saved_diagnosis.id_user,
            tanggal=saved_diagnosis.tanggal,
            jenis_penyakit=saved_diagnosis.jenis_penyakit,
            image=response_image_url,
            rekomendasi=saved_diagnosis.rekomendasi,
            kategori=saved_diagnosis.kategori.value,
            akurasi=saved_diagnosis.akurasi,
            create_date=saved_diagnosis.create_date,
            update_date=saved_diagnosis.update_date
        )
        
        logger.info(f"Diagnosa berhasil disimpan dengan ID: {saved_diagnosis.id_diagnosa}")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Terjadi kesalahan tak terduga dalam prediksi: {str(e)}", exc_info=True)
        if file_path and os.path.exists(file_path): 
            try:
                os.remove(file_path)
                logger.info(f"File {file_path} berhasil dibersihkan.")
            except Exception as cleanup_e:
                logger.error(f"Gagal membersihkan file {file_path}: {cleanup_e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Terjadi kesalahan internal server: {str(e)}"
        )

@router.get("/all/", response_model=List[diagnosa_schema.DiagnosaResponse])
async def get_all_diagnoses(db: Session = Depends(get_db)):
    """Mengambil semua record diagnosa dari database (ADMIN ONLY, or for specific use cases)."""
    diagnoses_from_db = diagnosa_repo.get_all_diagnosa(db) 
    
    diagnoses_for_response = []
    for diag_db_obj in diagnoses_from_db:
        diagnoses_for_response.append(diagnosa_schema.DiagnosaResponse(
            id_diagnosa=diag_db_obj.id_diagnosa,
            id_user=diag_db_obj.id_user,
            tanggal=diag_db_obj.tanggal,
            jenis_penyakit=diag_db_obj.jenis_penyakit,
            image=f"{IMAGE_BASE_URL}/{diag_db_obj.image}", 
            rekomendasi=diag_db_obj.rekomendasi,
            kategori=diag_db_obj.kategori.value, 
            akurasi=diag_db_obj.akurasi,
            create_date=diag_db_obj.create_date,
            update_date=diag_db_obj.update_date
        ))
    
    return diagnoses_for_response

# FIX UTAMA: Endpoint untuk histori khusus user yang login DENGAN PAGINATION
@router.get("/historiku/", response_model=List[diagnosa_schema.DiagnosaResponse]) 
async def get_my_diagnoses(
    db: Session = Depends(get_db),
    current_user: Users = Depends(get_current_user), # Membutuhkan user terautentikasi
    skip: int = 0, # FIX: Parameter untuk offset/skip
    limit: int = 10 # FIX: Parameter untuk limit data per halaman
):
    """Mengambil record diagnosa untuk user yang sedang login dengan pagination."""
    logger.info(f"Endpoint /historiku/ diakses oleh User ID: {current_user.id_user}, Nama: {current_user.nama} (skip={skip}, limit={limit})")
    # FIX: Panggil fungsi repository yang mendapatkan diagnosa berdasarkan id_user dengan skip dan limit
    diagnoses_from_db = diagnosa_repo.get_diagnosa_by_user(db, current_user.id_user, skip=skip, limit=limit) 
    
    diagnoses_for_response = []
    for diag_db_obj in diagnoses_from_db:
        diagnoses_for_response.append(diagnosa_schema.DiagnosaResponse(
            id_diagnosa=diag_db_obj.id_diagnosa,
            id_user=diag_db_obj.id_user,
            tanggal=diag_db_obj.tanggal,
            jenis_penyakit=diag_db_obj.jenis_penyakit,
            image=f"{IMAGE_BASE_URL}/{diag_db_obj.image}", 
            rekomendasi=diag_db_obj.rekomendasi,
            kategori=diag_db_obj.kategori.value, 
            akurasi=diag_db_obj.akurasi,
            create_date=diag_db_obj.create_date,
            update_date=diag_db_obj.update_date
        ))
    
    return diagnoses_for_response


@router.get("/{id_diagnosa}", response_model=diagnosa_schema.DiagnosaResponse)
async def get_diagnosa_by_id(id_diagnosa: int, db: Session = Depends(get_db)):
    """Mengambil satu record diagnosa berdasarkan ID."""
    diagnosa_from_db = diagnosa_repo.get_diagnosa_by_id(db, id_diagnosa) 
    
    if not diagnosa_from_db:
        raise HTTPException(status_code=404, detail="Diagnosa tidak ditemukan.")
    
    response_data = diagnosa_schema.DiagnosaResponse(
        id_diagnosa=diagnosa_from_db.id_diagnosa,
        id_user=diagnosa_from_db.id_user,
        tanggal=diagnosa_from_db.tanggal,
        jenis_penyakit=diagnosa_from_db.jenis_penyakit,
        image=f"{IMAGE_BASE_URL}/{diagnosa_from_db.image}", 
        rekomendasi=diagnosa_from_db.rekomendasi,
        kategori=diagnosa_from_db.kategori.value, 
        akurasi=diagnosa_from_db.akurasi,
        create_date=diagnosa_from_db.create_date,
        update_date=diagnosa_from_db.update_date
    )
    
    return response_data

@router.delete("/{id_diagnosa}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_diagnosa(id_diagnosa: int, db: Session = Depends(get_db)):
    """Menghapus record diagnosa dan file gambar terkait dari server."""
    diagnosa_to_delete = diagnosa_repo.get_diagnosa_by_id(db, id_diagnosa)
    if not diagnosa_to_delete:
        raise HTTPException(status_code=404, detail="Diagnosa tidak ditemukan.")
    
    success = diagnosa_repo.delete_diagnosa(db, id_diagnosa)
    if not success:
        raise HTTPException(status_code=500, detail="Gagal menghapus diagnosa dari database.")

    if diagnosa_to_delete.image:
        file_path = os.path.join("uploads", diagnosa_to_delete.image)
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
                logger.info(f"File gambar '{file_path}' berhasil dihapus.")
            except Exception as cleanup_e:
                logger.error(f"Gagal membersihkan file {file_path}: {cleanup_e}")
    
    return JSONResponse(status_code=status.HTTP_200_OK, content={"message": "Diagnosa berhasil dihapus."})