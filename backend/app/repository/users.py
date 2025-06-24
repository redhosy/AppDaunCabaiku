from typing import TypeVar, Generic, Optional, Dict, Any
from app.models.users import Users # Pastikan model Users Anda benar (ada kolom 'nama')
from sqlalchemy.orm import Session

from datetime import datetime, timedelta
from jose import JWTError, jwt
from config import get_db, SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, OAuth2PasswordBearer
import logging
import traceback

logger = logging.getLogger(__name__)

T = TypeVar("T")
security = HTTPBearer()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/login")


# User Repository Class
class UserRepo():
    @staticmethod
    def insert(db: Session, user_model: Users):
        db.add(user_model)
        db.commit()
        db.refresh(user_model)

    @staticmethod
    def find_by_id(db: Session, model_class: type[Generic[T]], user_id: int): # FIX: Fungsi find by ID
        return db.query(model_class).filter(model_class.id_user == user_id).first()

    @staticmethod
    def find_by_email(db: Session, model_class: type[Generic[T]], email: str):
        return db.query(model_class).filter(model_class.email == email).first()
    
    @staticmethod
    def find_by_nama(db: Session, model_class: type[Generic[T]], nama: str):
        return db.query(model_class).filter(model_class.nama == nama).first()

    @staticmethod
    def is_email_exist(db: Session, model_class: type[Generic[T]], email: str) -> bool:
        return db.query(model_class).filter(model_class.email == email).first() is not None

    @staticmethod
    def is_nama_exist(db: Session, model_class: type[Generic[T]], nama: str) -> bool:
        return db.query(model_class).filter(model_class.nama == nama).first() is not None
    
    # FIX: Fungsi untuk update user
    @staticmethod
    def update_user(db: Session, user: Users, update_data: Dict[str, Any]) -> Users:
        for key, value in update_data.items():
            setattr(user, key, value)
        user.update_date = datetime.utcnow() # Update timestamp
        db.add(user)
        db.commit()
        db.refresh(user)
        return user


# JWT Repository Class
class JWTRepo():
    @staticmethod
    def generate_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire.timestamp()})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt

# Dependency untuk mendapatkan user saat ini dari token JWT
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> Users:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Autentikasi gagal. Kredensial tidak valid.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        
        username_or_email_from_token: str = payload.get("sub")
        expire_timestamp = payload.get("exp")
        
        logger.info(f"Token dekode sukses. Payload: {payload}")
        logger.info(f"Subject (nama/email) dari token: {username_or_email_from_token}")
        logger.info(f"Waktu kedaluwarsa token (Unix timestamp): {expire_timestamp}")

        if username_or_email_from_token is None:
            logger.warning("Subject (nama/email) tidak ditemukan di payload token.")
            raise credentials_exception
        
        if expire_timestamp is None:
            logger.warning("Token tidak memiliki klaim 'exp' (kedaluwarsa).")
            raise credentials_exception
        
        token_expiry_datetime = datetime.fromtimestamp(expire_timestamp)
        current_utc_datetime = datetime.utcnow()
        
        logger.info(f"Waktu kedaluwarsa token (UTC): {token_expiry_datetime}")
        logger.info(f"Waktu saat ini (UTC): {current_utc_datetime}")

        if token_expiry_datetime < current_utc_datetime:
            logger.warning("Token telah kedaluwarsa.")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token autentikasi telah kedaluwarsa. Silakan login kembali.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
    except JWTError as e:
        logger.error(f"Error decoding JWT token: {e}", exc_info=True)
        if "signature has expired" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token autentikasi telah kedaluwarsa. Silakan login kembali.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        raise credentials_exception
    except Exception as e:
        logger.error(f"Terjadi kesalahan tak terduga saat memvalidasi token: {e}", exc_info=True)
        raise credentials_exception

    user = UserRepo.find_by_email(db, Users, username_or_email_from_token)
    
    if user is None:
        logger.warning(f"User '{username_or_email_from_token}' dari token tidak ditemukan di database.")
        raise credentials_exception

    logger.info(f"User '{user.nama}' berhasil diautentikasi.")
    return user