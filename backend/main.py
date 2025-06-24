# main.py
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from config import engine
import logging
import os

# Import models
import app.models.users as user_table
import app.models.diagnosa as diagnosa_table

# Import routers
import app.routers.authentication as user_routers
import app.routers.diagnosa as diagnosa_routers


# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
# Gunakan logger dari logging, bukan dari venv
logger = logging.getLogger(__name__)


# Create tables
user_table.Base.metadata.create_all(bind=engine)
diagnosa_table.Base.metadata.create_all(bind=engine)

# Create FastAPI app
app = FastAPI(
    title="Plant Disease Detection API",
    description="API untuk deteksi penyakit tanaman menggunakan CNN + SVM",
    version="1.0.0"
)

@app.on_event("startup")
async def startup_event():
    logger.info("Memulai aplikasi...")
    await diagnosa_routers.load_models_on_startup() # Memuat model ML di startup

# Create uploads directory
os.makedirs("uploads", exist_ok=True)

# Mount static files untuk serve uploaded images
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Include routers
app.include_router(user_routers.router, prefix="/api/v1", tags=["Users"])
app.include_router(diagnosa_routers.router, prefix="/api/v1", tags=["Diagnosa"])

@app.get("/")
async def root():
    return {"message": "API Pendeteksi Penyakit Tanaman", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}