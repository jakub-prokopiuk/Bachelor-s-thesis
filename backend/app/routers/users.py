from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.crud import update_user, get_user_by_id
from app.schemas.users import UpdateUserRequest
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

router = APIRouter()

@router.get("/user/{user_id}")
def get_user_info(user_id: int, db: Session = Depends(get_db)):
    user = get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "username": user.username,
        "email": user.email,
        "created_at": user.created_at,
    }

@router.put("/user/{user_id}")
def update_user(user_id: int, payload: UpdateUserRequest, db: Session = Depends(get_db)):
    user = get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if payload.username:
        user.username = payload.username
    
    if payload.email:
        user.email = payload.email
    
    if payload.password:
        user.hashed_password = pwd_context.hash(payload.password)
    
    db.commit()
    db.refresh(user)
    
    return {"message": "User information updated successfully", "username": user.username}

@router.delete("/user/{user_id}")
def delete_user_account(user_id: int, db: Session = Depends(get_db)):
    user = get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    
    return {"message": "User account deleted successfully"}
