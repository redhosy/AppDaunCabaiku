from pydantic import BaseModel
from datetime import date
from typing import Optional

class StatistikCreate(BaseModel):
    tanggal: Optional[date] = None
    total_sehat: int
    total_kuning: int 
    total_keriting: int 

class StatistikResponse(BaseModel):
    id_statistik: int
    id_user: int
    tanggal: date
    total_sehat: int
    total_kuning: int 
    total_keriting: int 

class Config:
    orm_mode = True