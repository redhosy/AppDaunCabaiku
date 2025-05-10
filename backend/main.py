from fastapi import FastAPI
from config import engine

import app.models.users as user_table

import app.routers.users as user_routers

user_table.Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(user_routers.router)


    