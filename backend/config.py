from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

DATABASE_URL = "postgresql://postgres:12345678@localhost:5432/Capstone_p"
engine = create_engine(DATABASE_URL)
sessionmaker = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = sessionmaker()
    try:
        yield db
    finally:
        db.close()

#jwt
SECRET_KEY = "dokumenrahasia"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
