from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.services.auth_service import AuthService

security = HTTPBearer()
auth_service = AuthService()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """
    Dependency to get the current authenticated user from JWT token
    Usage: current_user: dict = Depends(get_current_user)
    """
    token = credentials.credentials
    
    payload = auth_service.verify_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return {
        'user_id': payload.get('sub'),
        'email': payload.get('email'),
        'username': payload.get('username', '')
    }

async def get_optional_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """Optional authentication - returns None if not authenticated"""
    try:
        return await get_current_user(credentials)
    except:
        return None
