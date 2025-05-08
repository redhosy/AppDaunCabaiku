from datetime import datetime, timedelta
from jose import jwt
from .config import config

def create_engine_token(data:dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=config.access_token_expire_minutes)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, config.secret_key, algorithm=config.algorithm)