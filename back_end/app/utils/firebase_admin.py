import firebase_admin
from firebase_admin import credentials, firestore, auth
from app.config import get_settings
from pathlib import Path
from typing import Optional, Dict

settings = get_settings()

# Initialize firestore client (will be None if initialization fails)
_firestore_client = None

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    global _firestore_client
    
    if firebase_admin._apps:
        print("✅ Firebase already initialized")
        _firestore_client = firestore.client()
        return  # Already initialized
    
    try:
        # Determine base directory (back_end folder)
        base_dir = Path(__file__).resolve().parent.parent.parent
        
        # Try to load from credentials file if path provided
        if settings.FIREBASE_CREDENTIALS_PATH:
            # Handle both absolute and relative paths
            cred_path = Path(settings.FIREBASE_CREDENTIALS_PATH)
            if not cred_path.is_absolute():
                cred_path = base_dir / cred_path
            
            if cred_path.exists():
                print(f"📄 Loading Firebase credentials from: {cred_path}")
                cred = credentials.Certificate(str(cred_path))
                firebase_admin.initialize_app(cred)
                _firestore_client = firestore.client()
                print("✅ Firebase initialized successfully with Firestore access")
                return
            else:
                print(f"⚠️  Credentials file not found: {cred_path}")
        
        # Try environment variables as fallback
        if settings.FIREBASE_PROJECT_ID and settings.FIREBASE_PRIVATE_KEY and settings.FIREBASE_CLIENT_EMAIL:
            print("📄 Loading Firebase credentials from environment variables")
            cred_dict = {
                "type": "service_account",
                "project_id": settings.FIREBASE_PROJECT_ID,
                "private_key_id": settings.FIREBASE_PRIVATE_KEY_ID,
                "private_key": settings.FIREBASE_PRIVATE_KEY.replace('\\n', '\n'),
                "client_email": settings.FIREBASE_CLIENT_EMAIL,
                "client_id": settings.FIREBASE_CLIENT_ID,
                "auth_uri": settings.FIREBASE_AUTH_URI,
                "token_uri": settings.FIREBASE_TOKEN_URI,
            }
            cred = credentials.Certificate(cred_dict)
            firebase_admin.initialize_app(cred)
            _firestore_client = firestore.client()
            print("✅ Firebase initialized successfully with Firestore access")
            return
        
        print("⚠️  No Firebase credentials found")
        print("   Set FIREBASE_CREDENTIALS_PATH in .env or provide credentials")
        print("   App will work in DEMO MODE without cloud sync")
        
    except Exception as e:
        print(f"❌ Firebase initialization failed: {e}")
        print("   App will work in DEMO MODE without cloud sync")
        import traceback
        traceback.print_exc()

def get_firestore_client():
    """Get the Firestore client instance"""
    return _firestore_client

def verify_firebase_token(id_token: str) -> Optional[Dict]:
    """
    Verify Firebase ID token and return decoded token with user info
    
    Args:
        id_token: Firebase ID token from client
        
    Returns:
        Dict with user info (uid, email, etc.) or None if invalid
    """
    try:
        # Verify the ID token
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except auth.InvalidIdTokenError:
        print("❌ Invalid Firebase ID token")
        return None
    except auth.ExpiredIdTokenError:
        print("❌ Firebase ID token has expired")
        return None
    except Exception as e:
        print(f"❌ Error verifying Firebase token: {e}")
        return None
