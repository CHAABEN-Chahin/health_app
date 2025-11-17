from app.utils.security import SecurityUtils
from app.services.firebase_service import FirebaseService
from app.utils.firebase_admin import verify_firebase_token
from datetime import datetime
from typing import Optional

class AuthService:
    def __init__(self):
        self.firebase_service = FirebaseService()
        self.security = SecurityUtils()
    
    async def signup(self, firebase_id_token: str, username: str, full_name: str) -> dict:
        """
        Register a new user using Firebase ID token
        
        User must first register with Firebase Auth on the frontend,
        then provide the ID token here to create backend user record
        """
        # Verify Firebase ID token
        decoded_token = verify_firebase_token(firebase_id_token)
        if not decoded_token:
            raise ValueError("Invalid Firebase ID token")
        
        firebase_uid = decoded_token.get('uid')
        email = decoded_token.get('email')
        
        if not firebase_uid or not email:
            raise ValueError("Invalid token data")
        
        # Check if user already exists by Firebase UID
        existing_user = await self.firebase_service.get_user_by_firebase_uid(firebase_uid)
        if existing_user:
            raise ValueError("User already registered")
        
        # Create user record (NO password stored)
        user_data = {
            'firebase_uid': firebase_uid,
            'email': email,
            'username': username,
            'full_name': full_name,
            'created_at': datetime.utcnow().isoformat()
        }
        
        user_id = await self.firebase_service.create_user(user_data)
        
        # Create default profile
        default_profile = {
            'user_id': user_id,
            'daily_calorie_goal': 2000,
            'daily_step_goal': 10000,
            'daily_distance_goal': 5.0,
            'daily_active_minutes_goal': 30,
            'daily_protein_goal': 150,
            'daily_carbs_goal': 250,
            'daily_fats_goal': 70,
        }
        await self.firebase_service.update_user_profile(user_id, default_profile)
        
        return {
            'user_id': user_id,
            'email': email,
            'username': username
        }
    
    async def login(self, firebase_id_token: str) -> dict:
        """
        Authenticate user using Firebase ID token
        
        User must first login with Firebase Auth on the frontend,
        then provide the ID token here to get backend JWT
        """
        # Verify Firebase ID token
        decoded_token = verify_firebase_token(firebase_id_token)
        if not decoded_token:
            raise ValueError("Invalid Firebase ID token")
        
        firebase_uid = decoded_token.get('uid')
        email = decoded_token.get('email')
        
        if not firebase_uid or not email:
            raise ValueError("Invalid token data")
        
        # Get user from backend by Firebase UID
        user = await self.firebase_service.get_user_by_firebase_uid(firebase_uid)
        if not user:
            raise ValueError("User not found. Please complete signup first.")
        
        # Update last login
        await self.firebase_service.update_user(user['id'], {'last_login': datetime.utcnow().isoformat()})
        
        return {
            'user_id': user['id'],
            'email': user['email'],
            'username': user.get('username', ''),
        }
    
    def create_token(self, user_data: dict) -> str:
        """Create JWT access token for backend API authorization"""
        token_data = {
            'sub': user_data['user_id'],
            'email': user_data['email'],
            'username': user_data.get('username', '')
        }
        return self.security.create_access_token(token_data)
    
    def verify_token(self, token: str) -> Optional[dict]:
        """Verify and decode JWT token"""
        return self.security.verify_token(token)
