from pydantic import BaseModel
from typing import List, Optional
from app.models import vitals

class SyncVitalsRequest(BaseModel):
    date: str  # YYYY-MM-DD
    readings: List[vitals.VitalReading]
    summary: vitals.VitalsSummary
class GetVitalsResponse(BaseModel):
    data: List[vitals.DailyVitals]
    days: int
    start_date: str
    end_date: str
