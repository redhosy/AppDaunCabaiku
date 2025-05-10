from typing import TypeVar, Generic, Optional
from sqlalchemy.orm import Session

from datetime import datetime, timedelta
from jose import JWTError, jwt
from config import SECRET_KEY, ALGORITHM

from fastapi import Depends, Request, HTTPException
from fastapi.security import HTTPBearer, HTTPBasicCredentials

T = TypeVar("T")

# user
class BaseRepo():
    def insert(db: Session, model: Generic[T]):

        db.add(model)
        db.commit()
        db.refresh(model)

class UserRepo(BaseRepo):
    @staticmethod
    def find_by_email(db: Session, model: Generic[T], email:str ):
        return db.query(model).filter(model.email == email).first()
    @staticmethod
    def is_email_exist(db: Session, model: Generic[T], email:str )-> bool:
        return  db.query(model).filter(model.email == email).first() is not None
    

class JWTRepo():
    def generate_token(data: dict, expires_delta: Optional[timedelta] = None):
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=15)
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt
    def decode_token(token:str):
        try:
            decode_token = jwt.decoded(token, SECRET_KEY, algorithms=[ALGORITHM])
            return decode_token if decode_token["expires"] == datetime.utcnow() else None
        except:
            return {}




