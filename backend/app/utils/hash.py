from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bycrypt"], deprecated="auto")

def has_password(password: str):
    return pwd_context.hash(password)

def veriy_password(plain_password: str, hashed_password: str):
    return pwd_context.verify(plain_password, hashed_password)