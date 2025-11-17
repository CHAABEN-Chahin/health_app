from fastapi import APIRouter, Depends, HTTPException, Query
from app.schemas.activity import SyncActivityRequest, GetActivityResponse, CreateSessionRequest, GetSessionsResponse
from app.schemas.responses import StandardResponse
from app.services.firebase_service import FirebaseService
from app.dependencies import get_current_user
from app.models.activity import DailyActivity, Session
from datetime import datetime, timedelta

router = APIRouter()
firebase_service = FirebaseService()

@router.post("/sync", response_model=StandardResponse)
async def sync_daily_activity(
    request: SyncActivityRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Sync today's activity data to cloud
    
    Called by Flutter app at end of day
    Uploads steps, distance, calories, active minutes
    """
    try:
        activity_data = {
            'user_id': current_user["user_id"],
            'date': request.date,
            'steps': request.steps,
            'distance_km': request.distance_km,
            'active_minutes': request.active_minutes,
            'calories_burned': request.calories_burned,
            'hourly_breakdown': [h.dict() for h in request.hourly_breakdown] if request.hourly_breakdown else []
        }
        
        await firebase_service.store_daily_activity(
            user_id=current_user["user_id"],
            date=request.date,
            activity_data=activity_data
        )
        
        return StandardResponse(
            success=True,
            message=f"Activity for {request.date} synced successfully"
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to sync activity: {str(e)}")


@router.get("/historical", response_model=GetActivityResponse)
async def get_historical_activity(
    days: int = Query(7, description="Number of days to retrieve (7 or 30)"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get historical activity data from cloud
    
    Returns daily activity summaries for the requested period
    """
    try:
        end_date = datetime.utcnow().date()
        start_date = end_date - timedelta(days=days-1)
        
        activity_data = await firebase_service.get_activity_range(
            user_id=current_user["user_id"],
            start_date=start_date.isoformat(),
            end_date=end_date.isoformat()
        )
        
        daily_activities = [DailyActivity(**data) for data in activity_data]
        
        return GetActivityResponse(
            data=daily_activities,
            days=days,
            start_date=start_date.isoformat(),
            end_date=end_date.isoformat()
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch historical activity: {str(e)}")
