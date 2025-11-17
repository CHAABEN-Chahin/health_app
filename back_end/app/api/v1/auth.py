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
    Register a new user account
    
    Creates user in Firebase and generates JWT token
    """
    try:
        # Validate email
        if not validators.validate_email(request.email):
            raise HTTPException(status_code=400, detail="Invalid email format")
        
        # Validate password
        is_valid, error_msg = validators.validate_password(request.password)
        if not is_valid:
            raise HTTPException(status_code=400, detail=error_msg)
        
        # Create user
        user_data = await auth_service.signup(
            email=request.email,
            password=request.password,
            username=request.username,
            full_name=request.full_name
        )
        
        # Generate token
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
    Authenticate user and return JWT token
    
    Flutter app should:
    1. Call this endpoint with email/password
    2. Store the access_token securely
    3. Call GET /users/me/profile to fetch user data
    4. Store profile in local SQLite
    """
    try:
        # Authenticate user
        user_data = await auth_service.login(
            email=request.email,
            password=request.password
        )
        
        # Generate token
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
            detail="Invalid email or password"
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
