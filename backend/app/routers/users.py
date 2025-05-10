from fastapi import APIRouter, Depends
from pydantic_core import ValidationError
from app.schemas.users import ResponseSchema, TokenResponse, Register, Login
from sqlalchemy.orm import Session
from config import get_db
from passlib.context import CryptContext
from app.repository.users import UserRepo, JWTRepo
from app.models.users import Users

router = APIRouter(
    tags = ["Authentication"],
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@router.post("/register")
async def register(request: Register, db: Session = Depends(get_db)):
    try:
        # memastikan apakah email sudah ada
        if UserRepo.is_email_exist(db, Users, request.email):
            return ResponseSchema(
                code="400",
                status="Bad Request",
                message="Email sudah terdaftar"
            ).dict(exclude_none=True)
        # menambahahkan data user
        _user = Users(
            nama = request.nama,
            email = request.email,
            password =pwd_context.hash(request.password)
            )
        UserRepo.insert(db, _user)
        return ResponseSchema(
                code="200", 
                status="ok", 
                message="Berhasil Simpan Data").dict(exclude_none= True)
    except ValidationError as e:
        return ResponseSchema(
            code=400,
            status="Bad Request",
            message=str(e)
        ).dict(exclude_none=True)
    except Exception as e:
        print(e.args)
        return ResponseSchema(
            code="500",
            status="Error",
            message="Internal Server Error"
        ).dict(exclude_none=True)

@router.post("/login")
async def login(request: Login, db:Session = Depends(get_db)):
    try:
        # mencari user berdasarkan nama
        _user = UserRepo.find_by_email(db, Users, request.email)
        if not _user:
            return ResponseSchema(
                code="404",
                status="Not Found",
                message="Email Tidak Ditemukan"
            ).dict(exclude_none=True)
            
        if not pwd_context.verify(request.password, _user.password):
            return ResponseSchema(
                code="400",
                status="Bad Request",
                message="Invalid Password"
            ).dict(exclude_none=True)
        
        token = JWTRepo.generate_token({ 'sub': _user.email })
        return ResponseSchema(
            code="200",
            status="ok",
            message="Login Berhasil",
            result=TokenResponse(
                access_token=token,
                token_type="bearer"
                ).dict(exclude_none=True))
    except Exception as e:
        error_message = str(e.args)
        print(error_message)
        return ResponseSchema(
            code="500",
            status="Error",
            message="Internal Server Error"
        ).dict(exclude_none=True)
