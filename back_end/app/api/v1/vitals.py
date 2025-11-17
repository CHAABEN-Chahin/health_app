from fastapi import APIRouter, Depends, HTTPException, Query
from app.schemas.vitals import SyncVitalsRequest, GetVitalsResponse
from app.schemas.responses import StandardResponse
from app.services.firebase_service import FirebaseService
from app.dependencies import get_current_user
from app.models.vitals import DailyVitals
from datetime import datetime, timedelta

router = APIRouter()
firebase_service = FirebaseService()

@router.post("/sync", response_model=StandardResponse)
async def sync_daily_vitals(
    request: SyncVitalsRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Sync today's vitals data to cloud
    
    Called by Flutter app at end of day (11:59 PM) via background job
    
    Request includes:
    - date: "2025-11-17"
    - readings: Array of all vital readings from today (HR, SpO2, temp, etc.)
    - summary: Aggregated statistics (avg_hr, steps, calories, wellness_score)
    
    This data moves from "today's real-time data" to "historical data"
    """
    try:
        readings_dict = [reading.dict() for reading in request.readings]
        summary_dict = request.summary.dict()
        
        await firebase_service.store_daily_vitals(
            user_id=current_user["user_id"],
            date=request.date,
            readings=readings_dict,
            summary=summary_dict
        )
        
        return StandardResponse(
            success=True,
            message=f"Vitals for {request.date} synced successfully"
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to sync vitals: {str(e)}")


@router.get("/historical", response_model=GetVitalsResponse)
async def get_historical_vitals(
    days: int = Query(7, description="Number of days to retrieve (7 or 30)"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get historical vitals data from cloud
    
    Called when user opens:
    - "Last 7 Days" analysis screen
    - "Last 30 Days" analysis screen
    
    Flutter app should:
    1. Check local SQLite cache first
    2. If missing, call this endpoint
    3. Store returned data in local historical_vitals table
    4. Display charts from cached data
    
    Returns daily aggregated data for the requested period
    """
    try:
        # Calculate date range
        end_date = datetime.utcnow().date()
        start_date = end_date - timedelta(days=days-1)
        
        # Fetch from Firebase
        vitals_data = await firebase_service.get_vitals_range(
            user_id=current_user["user_id"],
            start_date=start_date.isoformat(),
            end_date=end_date.isoformat()
        )
        
        # Convert to DailyVitals models
        daily_vitals = [DailyVitals(**data) for data in vitals_data]
        
        return GetVitalsResponse(
            data=daily_vitals,
            days=days,
            start_date=start_date.isoformat(),
            end_date=end_date.isoformat()
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch historical vitals: {str(e)}")


@router.get("/date/{date}")
async def get_vitals_by_date(
    date: str,
    current_user: dict = Depends(get_current_user)
):
    """Get vitals for a specific date (YYYY-MM-DD)"""
    try:
        vitals = await firebase_service.get_vitals_by_date(
            user_id=current_user["user_id"],
            date=date
        )
        
        if not vitals:
            raise HTTPException(status_code=404, detail=f"No vitals found for {date}")
        
        return vitals
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch vitals: {str(e)}")
