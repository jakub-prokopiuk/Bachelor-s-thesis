from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.crud import update_user_data, get_user_by_id
from app.schemas.users import UpdateUserRequest
from passlib.context import CryptContext
from app.utils import send_reset_email, generate_random_password
from app.crud import get_user_by_email
from app.schemas.users import ResetPasswordRequest


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
    updated_user = update_user_data(db, user_id, username=payload.username, email=payload.email, password=payload.password)
    
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"message": "User information updated successfully", "username": updated_user.username}

@router.delete("/user/{user_id}")
def delete_user_account(user_id: int, db: Session = Depends(get_db)):
    user = get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    
    return {"message": "User account deleted successfully"}

@router.post("/reset-password")
def reset_password(request: ResetPasswordRequest, db: Session = Depends(get_db)):
    user = get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    new_password = generate_random_password()

    update_user_data(db, user.id, password=new_password)

    try:
        send_reset_email(user.email, new_password)
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error sending email")

    return {"message": "Password reset successfully, email sent."}
