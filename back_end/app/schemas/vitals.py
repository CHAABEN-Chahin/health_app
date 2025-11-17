from pydantic import BaseModel
from typing import List, Optional
from app.models.vitals import VitalReading, VitalsSummary, DailyVitals

class SyncVitalsRequest(BaseModel):
    date: str  # YYYY-MM-DD
    readings: List[VitalReading]
    summary: VitalsSummary

class GetVitalsResponse(BaseModel):
    data: List[DailyVitals]
    days: int
    start_date: str
    end_date: str
