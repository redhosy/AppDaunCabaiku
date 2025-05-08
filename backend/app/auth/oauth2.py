from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTerror, jwt
from app.config import config
from app.database import get_db
from app.models.user import Users
from sqlalchemy.orm import Session

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def get_current_user(token: str = Depends(oauth2_scheme), db:Session = Depends(get_db)):
    credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate vredentials",
    headers={"WWW-Authenticate":"Bearer"},
)
try:
    payload = jwt.decode(token, config.secret_key, algorithms=[config.algorithm])
    email: str = payload.get("sub")
    if email is None:
        raise credentials_exception
except JWTerror:
    raise credentials_exception
user=  db.query(user).filter(User.email == email).first()
if user is None:
    raise credentials_exception
return user
