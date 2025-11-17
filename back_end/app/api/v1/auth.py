from fastapi import APIRouter, HTTPException, status
from app.schemas.auth import SignupRequest, LoginRequest, TokenResponse
from app.schemas.responses import StandardResponse, ErrorResponse
from app.services.auth_service import AuthService
from app.utils.validators import Validators

router = APIRouter()
auth_service = AuthService()
validators = Validators()

@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def signup(request: SignupRequest):
    """
    Register a new user account using Firebase Authentication
    
    Flow:
    1. Frontend authenticates with Firebase Auth (email/password)
    2. Frontend gets Firebase ID token
    3. Frontend sends ID token to this endpoint
    4. Backend verifies token and creates user record (NO password stored)
    5. Backend returns JWT for API authorization
    
    Args:
        firebase_id_token: ID token from Firebase Auth
        username: Desired username
        full_name: User's full name
    """
    try:
        # Create user using Firebase token
        user_data = await auth_service.signup(
            firebase_id_token=request.firebase_id_token,
            username=request.username,
            full_name=request.full_name
        )
        
        # Generate backend JWT token for API authorization
        token = auth_service.create_token(user_data)
        
        return TokenResponse(
            access_token=token,
            token_type="bearer",
            user_id=user_data['user_id'],
            email=user_data['email'],
            username=user_data['username']
        )
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Signup failed: {str(e)}")


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest):
    """
    Authenticate user and return JWT token using Firebase Authentication
    
    Flow:
    1. Frontend authenticates with Firebase Auth (email/password)
    2. Frontend gets Firebase ID token
    3. Frontend sends ID token to this endpoint
    4. Backend verifies token and finds user
    5. Backend returns JWT for API authorization
    
    Flutter app should:
    1. Call Firebase Auth to login
    2. Get ID token from Firebase
    3. Call this endpoint with the ID token
    4. Store the returned access_token securely
    5. Call GET /users/me/profile to fetch user data
    6. Store profile in local SQLite
    """
    try:
        # Authenticate user using Firebase token
        user_data = await auth_service.login(
            firebase_id_token=request.firebase_id_token
        )
        
        # Generate backend JWT token for API authorization
        token = auth_service.create_token(user_data)
        
        return TokenResponse(
            access_token=token,
            token_type="bearer",
            user_id=user_data['user_id'],
            email=user_data['email'],
            username=user_data['username']
        )
    
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")


@router.post("/logout", response_model=StandardResponse)
async def logout():
    """
    Logout endpoint (client-side token removal)
    
    JWT tokens are stateless, so logout is handled by Flutter app
    removing the token from secure storage
    """
    return StandardResponse(
        success=True,
        message="Logged out successfully. Remove token from client storage."
    )
