from pydantic import BaseModel

# get
class CreateUser(BaseModel):
    nama: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserOut(BaseModel):
    id_user: int
    nama: str
    email: str
    
    class Config:
        orm_mode:True
