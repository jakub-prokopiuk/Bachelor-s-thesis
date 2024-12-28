from fastapi import FastAPI
from app.routers import chargers, auth, favorites, users

app = FastAPI()

# Include the routers
app.include_router(chargers.router, prefix="/api", tags=["chargers"])
app.include_router(auth.router, prefix="/api", tags=["auth"])
app.include_router(favorites.router, prefix="/api", tags=["favorites"])
app.include_router(users.router, prefix="/api", tags=["users"])

@app.get("/")
def read_root():
    return {"message": "Welcome to the EV Charger API"}