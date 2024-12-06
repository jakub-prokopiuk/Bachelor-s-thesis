from pydantic import BaseModel

class FavoriteRequest(BaseModel):
    charger_id: int
