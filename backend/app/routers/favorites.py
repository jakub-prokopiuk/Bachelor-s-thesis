from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.models import Favorite, User, EVCharger
from app.database import get_db
from app.auth import get_current_user
from app.schemas.favorites import FavoriteRequest

router = APIRouter()

@router.post("/favorites/")
def add_to_favorites(
    favorite_request: FavoriteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    charger_id = favorite_request.charger_id

    charger = db.query(EVCharger).filter(EVCharger.id == charger_id).first()
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")

    existing_favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.charger_id == charger_id
    ).first()

    if existing_favorite:
        raise HTTPException(status_code=409, detail="Charger already added to favorites")

    favorite = Favorite(user_id=current_user.id, charger_id=charger_id)
    db.add(favorite)
    db.commit()

    return {"message": "Charger added to favorites"}

@router.get("/favorites/")
def get_favorites(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    favorites = db.query(Favorite).filter(Favorite.user_id == current_user.id).all()
    
    if not favorites:
        raise HTTPException(status_code=404, detail="No favorite chargers found.")
    
    chargers = [favorite.charger for favorite in favorites]
    
    return chargers

@router.delete("/favorites/")
def remove_from_favorites(
    charger_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    favorite = db.query(Favorite).filter(Favorite.user_id == current_user.id, Favorite.charger_id == charger_id).first()

    if not favorite:
        raise HTTPException(status_code=404, detail="Favorite charger not found")

    db.delete(favorite)
    db.commit()

    return {"message": "Charger removed from favorites"}
