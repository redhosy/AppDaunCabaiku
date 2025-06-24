# app/schemas/users.py
from pydantic import BaseModel, EmailStr, validator
from typing import Optional, Generic, TypeVar
from datetime import datetime

T = TypeVar("T")

class Register(BaseModel):
    nama: str
    email: EmailStr
    password: str

    @validator('password')
    def password_length(cls, v):
        if len(v) < 8:
            raise ValueError('Password minimal 8 karakter')
        return v

class Login(BaseModel): 
    email: EmailStr
    password: str

# Skema untuk Respons Token JWT
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int 
    nama: str 
    email: EmailStr 
    image: Optional[str] = None # FIX: Tambahkan image (nullable)

# FIX: Skema baru untuk detail user (digunakan oleh /me endpoint dan update)
class UserDetailResponse(BaseModel):
    id_user: int
    nama: str
    email: EmailStr
    image: Optional[str] = None # URL foto profil
    create_date: datetime
    update_date: datetime

    class Config:
        from_attributes = True # Mengizinkan konversi dari ORM model

# FIX: Skema untuk permintaan update profil
class UserUpdate(BaseModel):
    nama: str
    # email: EmailStr
    image: Optional[str] = None

# Skema respons umum (tetap sama)
class ResponseSchema(BaseModel, Generic[T]):
    code: str
    status: str
    message: str
    result: Optional[T]

    class Config:
        from_attributes = True