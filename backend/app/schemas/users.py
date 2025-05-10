from typing import  Optional, TypeVar
from pydantic import BaseModel,EmailStr, root_validator

T = TypeVar("T")

# login
class Login(BaseModel):
    email: EmailStr
    password: str

# register
class Register(BaseModel):
    id_user : int
    nama : str
    email : EmailStr
    password : str
    konfirmasi_password : str
    
    @root_validator()
    def cek_validator(cls, values):
        print("validator jalan dengan nilai:", values)
        pw = values.get("password")
        cpw = values.get("konfirmasi_password")
        if pw != cpw:
            raise ValueError("Password dan konfirmasi password tidak cocok")
        return values
# respon model
class ResponseSchema(BaseModel):
    code : int 
    status : str 
    message : str 
    result : Optional[T] = None 

# token
class TokenResponse(BaseModel):
    access_token : str
    token_type : str
    
