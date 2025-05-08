from fastapi import FastAPI
from app.routers import user, diagnosa, grafik

app = FastAPI()

Base.metadata.create_all(bind=engine)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# include_router
app.include_router(user.router)
# app.include_router(diagnosa.router)
# app.include_router(grafik.router)


    