from fastapi import APIRouter, Depends, HTTPException, Query
from app.schemas.responses import StandardResponse
from app.services.firebase_service import FirebaseService
from app.dependencies import get_current_user
from app.models.alert import Alert
from datetime import datetime, timedelta
from typing import List

router = APIRouter()
firebase_service = FirebaseService()

@router.post("", response_model=StandardResponse, status_code=201)
async def create_alert(
    alert: Alert,
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new health alert
    
    Called when app detects abnormal vitals:
    - High/low heart rate
    - Low SpO2
    - Abnormal temperature
    - Inactivity warning
    """
    try:
        alert_data = alert.dict(exclude={'id'})
        alert_data['user_id'] = current_user["user_id"]
        
        alert_id = await firebase_service.create_alert(
            user_id=current_user["user_id"],
            alert_data=alert_data
        )
        
        return StandardResponse(
            success=True,
            message="Alert created successfully",
            data={"alert_id": alert_id}
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create alert: {str(e)}")


@router.get("", response_model=List[Alert])
async def get_alerts(
    limit: int = Query(50, description="Maximum number of alerts to return"),
    days: int = Query(7, description="Get alerts from last N days"),
    current_user: dict = Depends(get_current_user)
):
    """Get user's health alerts"""
    try:
        # Calculate timestamp for N days ago
        since_timestamp = int((datetime.utcnow() - timedelta(days=days)).timestamp())
        
        alerts_data = await firebase_service.get_alerts(
            user_id=current_user["user_id"],
            limit=limit,
            since_timestamp=since_timestamp
        )
        
        alerts = [Alert(**data) for data in alerts_data]
        return alerts
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch alerts: {str(e)}")


@router.post("/{alert_id}/acknowledge", response_model=StandardResponse)
async def acknowledge_alert(
    alert_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Mark an alert as acknowledged"""
    try:
        await firebase_service.acknowledge_alert(
            user_id=current_user["user_id"],
            alert_id=alert_id
        )
        
        return StandardResponse(
            success=True,
            message="Alert acknowledged"
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to acknowledge alert: {str(e)}")
