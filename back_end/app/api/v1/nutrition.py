from fastapi import APIRouter, Depends, HTTPException, Query
from app.schemas.responses import StandardResponse
from app.services.firebase_service import FirebaseService
from app.dependencies import get_current_user
from app.models.nutrition import NutritionEntry
from datetime import datetime, timedelta
from typing import List

router = APIRouter()
firebase_service = FirebaseService()

@router.post("", response_model=StandardResponse, status_code=201)
async def log_nutrition(
    entry: NutritionEntry,
    current_user: dict = Depends(get_current_user)
):
    """
    Log a nutrition entry (meal/snack)
    
    Called when user logs food intake
    """
    try:
        entry_data = entry.dict(exclude={'id'})
        entry_data['user_id'] = current_user["user_id"]
        
        entry_id = await firebase_service.create_nutrition_entry(
            user_id=current_user["user_id"],
            nutrition_data=entry_data
        )
        
        return StandardResponse(
            success=True,
            message="Nutrition entry logged successfully",
            data={"entry_id": entry_id}
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to log nutrition: {str(e)}")


@router.get("", response_model=List[NutritionEntry])
async def get_nutrition_entries(
    days: int = Query(30, description="Get entries from last N days"),
    current_user: dict = Depends(get_current_user)
):
    """Get user's nutrition log entries"""
    try:
        end_time = int(datetime.utcnow().timestamp())
        start_time = int((datetime.utcnow() - timedelta(days=days)).timestamp())
        
        entries_data = await firebase_service.get_nutrition_entries(
            user_id=current_user["user_id"],
            start_timestamp=start_time,
            end_timestamp=end_time
        )
        
        entries = [NutritionEntry(**data) for data in entries_data]
        return entries
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch nutrition entries: {str(e)}")


@router.post("/analyze", response_model=dict)
async def analyze_food_image(current_user: dict = Depends(get_current_user)):
    """
    Placeholder for future AI-powered food analysis
    
    Will use Gen AI to:
    - Identify food from image
    - Estimate nutritional values
    - Suggest similar healthier alternatives
    """
    return {
        "message": "AI food analysis coming soon!",
        "note": "This endpoint will integrate with Gen AI backend in the future"
    }
