from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UpdateUserRequest(BaseModel):
    username: Optional[str] = Field(None, max_length=50)
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8)

    class Config:
        from_attributes = True


class UserResponse(BaseModel):
    username: str
    email: str
    created_at: datetime

    class Config:
        from_attributes = True

class ResetPasswordRequest(BaseModel):
    email: EmailStr