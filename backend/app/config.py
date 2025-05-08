from pydantic import BaseSettings

class Settings(BaseSettings):
    database_url: DATABASE_URL
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: ACCESS_TOKEN_EXPIRE_MINUTES

    class Config:
        env_file = ".env"

config = Settings()
