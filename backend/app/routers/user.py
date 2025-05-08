from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import schemas, models
from app.database import get_db
from app.utils.hash import hash_password, verify_password
from app.utils.jwt import create_access_token

router = APIRouter(tags=["User"])


@router.post("/register", response_model=schemas.UserOut)
def regiter(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.user.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = hash_password(user.password)
    new_user = models.user.User(nama=user.nama, email=user.email, password=hashed_password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login")
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(models.user.User).filter(models.user.User.email == user.email).first()
    if not db_user or not verify_password(user.password, db_user.password):
        raise HTTPException(status_code=401, detail="Invalid  credentials")
    
    access_token = create_access_token(data={"sub":db_user.email})
    return{"assess_token": access_token,"token_type":"bearer"}
    


