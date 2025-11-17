from fastapi import APIRouter, Depends, HTTPException, Query
from app.schemas.activity import CreateSessionRequest, GetSessionsResponse
from app.schemas.responses import StandardResponse
from app.services.firebase_service import FirebaseService
from app.dependencies import get_current_user
from app.models.activity import Session
from datetime import datetime, timedelta

router = APIRouter()
firebase_service = FirebaseService()

@router.post("", response_model=StandardResponse, status_code=201)
async def create_session(
    request: CreateSessionRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new workout/activity session
    
    Examples: walking, running, cycling, gym workout
    """
    try:
        session_data = request.dict()
        session_data['user_id'] = current_user["user_id"]
        
        session_id = await firebase_service.create_session(
            user_id=current_user["user_id"],
            session_data=session_data
        )
        
        return StandardResponse(
            success=True,
            message="Session created successfully",
            data={"session_id": session_id}
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create session: {str(e)}")


@router.get("", response_model=GetSessionsResponse)
async def get_sessions(
    limit: int = Query(50, description="Maximum number of sessions to return"),
    days: int = Query(30, description="Get sessions from last N days"),
    current_user: dict = Depends(get_current_user)
):
    """Get user's workout sessions"""
    try:
        # Calculate timestamp for N days ago
        start_time = int((datetime.utcnow() - timedelta(days=days)).timestamp())
        
        sessions_data = await firebase_service.get_sessions(
            user_id=current_user["user_id"],
            limit=limit,
            start_time=start_time
        )
        
        sessions = [Session(**data) for data in sessions_data]
        
        return GetSessionsResponse(
            sessions=sessions,
            total=len(sessions)
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch sessions: {str(e)}")
