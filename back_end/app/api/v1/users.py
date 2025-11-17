from fastapi import APIRouter, Depends, HTTPException, status
from app.schemas.user import UserProfileResponse, UpdateProfileRequest
from app.schemas.responses import StandardResponse
from app.services.firebase_service import FirebaseService
from app.dependencies import get_current_user

router = APIRouter()
firebase_service = FirebaseService()

@router.get("/me/profile", response_model=UserProfileResponse)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    """
    Get the authenticated user's profile
    
    Flutter app calls this after login to:
    1. Fetch user profile from cloud
    2. Store it in local SQLite user_profile table
    3. Use locally for app operation
    """
    try:
        profile = await firebase_service.get_user_profile(current_user["user_id"])
        
        if not profile:
            # Return default profile if none exists
            return UserProfileResponse(
                user_id=current_user["user_id"],
                daily_calorie_goal=2000,
                daily_step_goal=10000,
                daily_distance_goal=5.0,
                daily_active_minutes_goal=30,
                daily_protein_goal=150,
                daily_carbs_goal=250,
                daily_fats_goal=70
            )
        
        return UserProfileResponse(**profile)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch profile: {str(e)}")


@router.put("/me/profile", response_model=StandardResponse)
async def update_my_profile(
    request: UpdateProfileRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Update the authenticated user's profile
    
    Flutter app calls this when:
    - User edits profile settings
    - User updates health goals
    - User changes personal information
    
    Updates are stored in Firebase and synced to local SQLite
    """
    try:
        # Only update fields that were provided
        update_data = request.dict(exclude_unset=True)
        
        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        await firebase_service.update_user_profile(current_user["user_id"], update_data)
        
        return StandardResponse(
            success=True,
            message="Profile updated successfully"
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")


@router.get("/me", response_model=dict)
async def get_my_info(current_user: dict = Depends(get_current_user)):
    """Get basic user information"""
    try:
        user = await firebase_service.get_user_by_id(current_user["user_id"])
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        return {
            "user_id": user['id'],
            "email": user['email'],
            "username": user.get('username', ''),
            "full_name": user.get('full_name', ''),
            "created_at": user.get('created_at'),
            "last_login": user.get('last_login')
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch user info: {str(e)}")
