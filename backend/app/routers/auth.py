from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.crud import create_user, get_user_by_username, verify_password
from app.auth import create_access_token
from app.schemas.auth import RegisterRequest, LoginRequest

router = APIRouter()

@router.post("/register")
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    if get_user_by_username(db, payload.username):
        raise HTTPException(status_code=400, detail="Username already registered")
    user = create_user(db, payload.username, payload.email, payload.password)
    return {"message": "User created successfully", "username": user.username}

@router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = get_user_by_username(db, payload.username)
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    access_token = create_access_token({"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}
