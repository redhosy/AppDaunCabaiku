# app/routers/authentication.py
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, status
from fastapi.responses import JSONResponse
from pydantic_core import ValidationError
from sqlalchemy.orm import Session
from config import get_db, ACCESS_TOKEN_EXPIRE_MINUTES
from passlib.context import CryptContext
from app.repository.users import UserRepo, JWTRepo, get_current_user
from app.models.users import Users 
from app.schemas.users import ResponseSchema, TokenResponse, Register, Login, UserDetailResponse, UserUpdate 
import logging
import traceback
from datetime import timedelta
import os
import uuid 

logger = logging.getLogger(__name__)

router = APIRouter(
    tags=["Authentication"], # Tetap pertahankan tags untuk dokumentasi Swagger/OpenAPI
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

IMAGE_BASE_URL = "http://192.168.196.187:8000/uploads" # Ganti dengan IP server Anda


@router.post("/register", response_model=ResponseSchema)
async def register(request: Register, db: Session = Depends(get_db)):
    try:
        logger.info(f"Menerima permintaan registrasi untuk email: {request.email}, nama: {request.nama}")

        if UserRepo.is_email_exist(db, Users, request.email):
            logger.warning(f"Percobaan registrasi dengan email yang sudah terdaftar: {request.email}")
            return ResponseSchema(code="400", status="Bad Request", message="Email sudah terdaftar").dict(exclude_none=True)

        if UserRepo.is_nama_exist(db, Users, request.nama):
            logger.warning(f"Percobaan registrasi dengan nama pengguna yang sudah terdaftar: {request.nama}")
            return ResponseSchema(code="400", status="Bad Request", message="Nama pengguna sudah terdaftar").dict(exclude_none=True)

        _user = Users(
            nama = request.nama,
            email = request.email,
            password = pwd_context.hash(request.password),
        )

        UserRepo.insert(db, _user)
        logger.info(f"User '{request.nama}' berhasil terdaftar dengan ID: {_user.id_user}.")

        return ResponseSchema(
            code="200", 
            status="ok", 
            message="Berhasil Simpan Data"
        ).dict(exclude_none= True)

    except ValidationError as e:
        logger.error(f"Validasi Pydantic gagal saat registrasi: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=e.errors()
        )
    except Exception as e:
        logger.error(f"Terjadi kesalahan tak terduga saat registrasi: {e}", exc_info=True)
        traceback.print_exc()
        return ResponseSchema(
            code="500",
            status="Error",
            message="Internal Server Error"
        ).dict(exclude_none=True)


@router.post("/login", response_model=ResponseSchema)
async def login(request: Login, db:Session = Depends(get_db)):
    try:
        logger.info(f"Mencoba login untuk email: {request.email}")

        _user = UserRepo.find_by_email(db, Users, request.email)

        if not _user:
            logger.warning(f"Percobaan login gagal: Email '{request.email}' tidak ditemukan.")
            return ResponseSchema(code="404", status="Not Found", message="Email tidak ditemukan").dict(exclude_none=True)

        if not pwd_context.verify(request.password, _user.password):
            logger.warning(f"Percobaan login gagal: Password salah untuk email '{request.email}'.")
            return ResponseSchema(code="400", status="Bad Request", message="Invalid Password").dict(exclude_none=True)

        token = JWTRepo.generate_token(data={ 'sub': _user.email }, expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))

        logger.info(f"Login user '{_user.email}' berhasil, token dihasilkan.")

        profile_image_full_url = None
        if _user.image:
            profile_image_full_url = f"{IMAGE_BASE_URL}/profile_pictures/{_user.image}"

        return ResponseSchema(
            code="200",
            status="ok",
            message="Login Berhasil",
            result=TokenResponse(
                access_token=token,
                token_type="bearer",
                user_id=_user.id_user,
                nama=_user.nama,
                email=_user.email,
                image=profile_image_full_url,
            )
        ).dict(exclude_none=True)
    except Exception as e:
        logger.error(f"Terjadi kesalahan tak terduga saat login: {e}", exc_info=True)
        traceback.print_exc()
        return ResponseSchema(code="500", status="Error", message="Internal Server Error").dict(exclude_none=True)

@router.get("/me", response_model=ResponseSchema)
async def read_users_me(current_user: Users = Depends(get_current_user)):
    """Endpoint untuk mendapatkan data user yang sedang login."""
    logger.info(f"Endpoint /user diakses oleh user: {current_user.nama}")

    profile_image_full_url = None
    if current_user.image:
        profile_image_full_url = f"{IMAGE_BASE_URL}/profile_pictures/{current_user.image}"

    user_detail_response = UserDetailResponse(
        id_user=current_user.id_user,
        nama=current_user.nama,
        email=current_user.email,
        image=profile_image_full_url,
        create_date=current_user.create_date,
        update_date=current_user.update_date
    )

    return ResponseSchema(
        code="200",
        status="ok",
        message="User data fetched successfully",
        result=user_detail_response
    ).dict(exclude_none=True)

@router.put("/me", response_model=ResponseSchema)
async def update_users_me(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: Users = Depends(get_current_user)
):
    logger.info(f"User '{current_user.nama}' (ID: {current_user.id_user}) mencoba mengupdate profil.")

    update_data = user_update.model_dump(exclude_unset=True)

    if "email" in update_data and update_data["email"] != current_user.email:
        if UserRepo.is_email_exist(db, Users, update_data["email"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email sudah terdaftar."
            )

    if "nama" in update_data and update_data["nama"] != current_user.nama:
        if UserRepo.is_nama_exist(db, Users, update_data["nama"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nama pengguna sudah digunakan."
            )

    updated_user = UserRepo.update_user(db, current_user, update_data)

    return ResponseSchema(
        code="200",
        status="ok",
        message="Profil berhasil diperbarui",
        result=UserDetailResponse(
            id_user=updated_user.id_user,
            nama=updated_user.nama,
            email=updated_user.email,
            image=f"{IMAGE_BASE_URL}/profile_pictures/{updated_user.image}" if updated_user.image else None,
            create_date=updated_user.create_date,
            update_date=updated_user.update_date
        )
    ).dict(exclude_none=True)

@router.post("/upload_profile_picture", response_model=ResponseSchema)
async def upload_profile_picture(
    file: UploadFile = File(..., description="File gambar untuk foto profil"),
    db: Session = Depends(get_db),
    current_user: Users = Depends(get_current_user)
):
    logger.info(f"User '{current_user.nama}' (ID: {current_user.id_user}) mencoba mengunggah foto profil.")

    if not file.content_type or not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="File harus berupa gambar (jpg, png, dll)."
        )

    contents = await file.read() 
    if len(contents) > 5 * 1024 * 1024: 
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Ukuran file terlalu besar. Maksimal 5MB."
        )

    file_extension = os.path.splitext(file.filename)[1]
    unique_filename = f"profile_{current_user.id_user}_{uuid.uuid4().hex[:8]}{file_extension}"

    upload_dir = "uploads/profile_pictures" 
    os.makedirs(upload_dir, exist_ok=True)
    file_path = os.path.join(upload_dir, unique_filename)

    try:
        with open(file_path, "wb") as f:
            f.write(contents)
        logger.info(f"Foto profil disimpan: {file_path}")

        UserRepo.update_user(db, current_user, {"image": unique_filename})

        full_image_url = f"{IMAGE_BASE_URL}/profile_pictures/{unique_filename}"

        return ResponseSchema(
            code="200",
            status="ok",
            message="Foto profil berhasil diunggah.",
            result={"profile_picture_url": full_image_url}
        ).dict(exclude_none=True)
    except Exception as e:
        logger.error(f"Gagal mengunggah atau menyimpan foto profil: {e}", exc_info=True)
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Terjadi kesalahan server saat mengunggah foto profil: {str(e)}"
        )