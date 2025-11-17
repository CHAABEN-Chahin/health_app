from utils.security import SecurityUtils
from services.firebase_service import FirebaseService
from datetime import datetime
from typing import Optional

class AuthService:
    def __init__(self):
        self.firebase_service = FirebaseService()
        self.security = SecurityUtils()
    
    async def signup(self, email: str, password: str, username: str, full_name: str) -> dict:
        """Register a new user"""
        # Check if user already exists
        existing_user = await self.firebase_service.get_user_by_email(email)
        if existing_user:
            raise ValueError("Email already registered")
        
        # Hash password
        password_hash = self.security.hash_password(password)
        
        # Create user
        user_data = {
            'email': email,
            'password_hash': password_hash,
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
    
    async def login(self, email: str, password: str) -> dict:
        """Authenticate user and return user info"""
        # Get user from Firebase
        user = await self.firebase_service.get_user_by_email(email)
        if not user:
            raise ValueError("Invalid credentials")
        
        # Verify password
        if not self.security.verify_password(password, user['password_hash']):
            raise ValueError("Invalid credentials")
        
        # Update last login
        await self.firebase_service.update_user(user['id'], {'last_login': datetime.utcnow().isoformat()})
        
        return {
            'user_id': user['id'],
            'email': user['email'],
            'username': user.get('username', ''),
        }
    
    def create_token(self, user_data: dict) -> str:
        """Create JWT access token"""
        token_data = {
            'sub': user_data['user_id'],
            'email': user_data['email'],
            'username': user_data.get('username', '')
        }
        return self.security.create_access_token(token_data)
    
    def verify_token(self, token: str) -> Optional[dict]:
        """Verify and decode JWT token"""
        return self.security.verify_token(token)
