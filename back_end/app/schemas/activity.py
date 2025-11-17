from pydantic import BaseModel
from typing import List, Optional
from app.models.activity import DailyActivity, Session, HourlyActivity

class SyncActivityRequest(BaseModel):
    date: str  # YYYY-MM-DD
    steps: int
    distance_km: float
    active_minutes: int
    calories_burned: int
    hourly_breakdown: Optional[List[HourlyActivity]] = []

class GetActivityResponse(BaseModel):
    data: List[DailyActivity]
    days: int
    start_date: str
    end_date: str

class CreateSessionRequest(BaseModel):
    session_type: str
    start_time: int
    end_time: int
    duration_seconds: int
    avg_heart_rate: Optional[int] = None
    max_heart_rate: Optional[int] = None
    calories_burned: Optional[int] = None
    avg_spo2: Optional[int] = None
    distance_km: Optional[float] = None
    steps: Optional[int] = None
    notes: Optional[str] = None

class GetSessionsResponse(BaseModel):
    sessions: List[Session]
    total: int
