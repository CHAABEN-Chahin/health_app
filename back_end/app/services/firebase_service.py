from typing import List, Dict, Optional
from datetime import datetime
from utils.firebase_admin import get_firestore_client, initialize_firebase


class FirebaseService:
    def __init__(self):
        # Get Firestore client
        initialize_firebase()
        self.db = get_firestore_client()
        if self.db is None:
            self.demo_mode = True
            print("⚠️  FirebaseService running in DEMO MODE (no Firebase connection)")
            print("   All data operations will be simulated")
        else:
            self.demo_mode = False
            print("✅ FirebaseService connected to Firestore")
            print("   All read/write operations will sync to cloud")
    
    # ==================== USER OPERATIONS ====================
    
    async def create_user(self, user_data: dict) -> str:
        """Create a new user document"""
        if self.demo_mode:
            return "demo_user_" + user_data.get('email', 'test')
        
        doc_ref = self.db.collection('users').document()
        user_data['id'] = doc_ref.id
        user_data['created_at'] = datetime.utcnow().isoformat()
        doc_ref.set(user_data)
        return doc_ref.id
    
    async def get_user_by_email(self, email: str) -> Optional[dict]:
        """Get user by email"""
        if self.demo_mode:
            return None
        
        users = self.db.collection('users').where('email', '==', email).limit(1).stream()
        for user in users:
            data = user.to_dict()
            data['id'] = user.id
            return data
        return None
    
    async def get_user_by_id(self, user_id: str) -> Optional[dict]:
        """Get user by ID"""
        if self.demo_mode:
            return {'id': user_id, 'email': 'demo@example.com', 'username': 'demo_user'}
        
        doc = self.db.collection('users').document(user_id).get()
        if doc.exists:
            data = doc.to_dict()
            data['id'] = doc.id
            return data
        return None
    
    async def update_user(self, user_id: str, data: dict):
        """Update user document"""
        if self.demo_mode:
            return
        
        data['updated_at'] = datetime.utcnow().isoformat()
        self.db.collection('users').document(user_id).update(data)
    
    # ==================== PROFILE OPERATIONS ====================
    
    async def get_user_profile(self, user_id: str) -> Optional[dict]:
        """Get user profile"""
        if self.demo_mode:
            return {
                'user_id': user_id,
                'age': 30,
                'weight_kg': 70.0,
                'height_cm': 175.0,
                'daily_calorie_goal': 2000,
                'daily_step_goal': 10000,
                'daily_distance_goal': 5.0,
                'daily_active_minutes_goal': 30,
                'daily_protein_goal': 150,
                'daily_carbs_goal': 250,
                'daily_fats_goal': 70
            }
        
        doc = self.db.collection('users').document(user_id).collection('profile').document('data').get()
        if doc.exists:
            return doc.to_dict()
        return None
    
    async def update_user_profile(self, user_id: str, profile_data: dict):
        """Create or update user profile"""
        if self.demo_mode:
            return
        
        profile_data['user_id'] = user_id
        profile_data['updated_at'] = datetime.utcnow().isoformat()
        self.db.collection('users').document(user_id).collection('profile').document('data').set(profile_data, merge=True)
    
    # ==================== VITALS OPERATIONS ====================
    
    async def store_daily_vitals(self, user_id: str, date: str, readings: List[dict], summary: dict):
        """Store daily vitals data"""
        if self.demo_mode:
            return
        
        doc_ref = self.db.collection('users').document(user_id).collection('daily_vitals').document(date)
        doc_ref.set({
            'date': date,
            'readings': readings,
            'summary': summary,
            'synced_at': datetime.utcnow().isoformat()
        })
    
    async def get_vitals_range(self, user_id: str, start_date: str, end_date: str) -> List[dict]:
        """Get vitals data for a date range"""
        if self.demo_mode:
            return []
        
        docs = self.db.collection('users').document(user_id).collection('daily_vitals') \
            .where('date', '>=', start_date) \
            .where('date', '<=', end_date) \
            .order_by('date') \
            .stream()
        
        result = []
        for doc in docs:
            data = doc.to_dict()
            data['user_id'] = user_id
            result.append(data)
        return result
    
    async def get_vitals_by_date(self, user_id: str, date: str) -> Optional[dict]:
        """Get vitals for a specific date"""
        if self.demo_mode:
            return None
        
        doc = self.db.collection('users').document(user_id).collection('daily_vitals').document(date).get()
        if doc.exists:
            data = doc.to_dict()
            data['user_id'] = user_id
            return data
        return None
    
    # ==================== ACTIVITY OPERATIONS ====================
    
    async def store_daily_activity(self, user_id: str, date: str, activity_data: dict):
        """Store daily activity data"""
        if self.demo_mode:
            return
        
        activity_data['synced_at'] = datetime.utcnow().isoformat()
        doc_ref = self.db.collection('users').document(user_id).collection('daily_activities').document(date)
        doc_ref.set(activity_data)
    
    async def get_activity_range(self, user_id: str, start_date: str, end_date: str) -> List[dict]:
        """Get activity data for a date range"""
        if self.demo_mode:
            return []
        
        docs = self.db.collection('users').document(user_id).collection('daily_activities') \
            .where('date', '>=', start_date) \
            .where('date', '<=', end_date) \
            .order_by('date') \
            .stream()
        
        result = []
        for doc in docs:
            data = doc.to_dict()
            data['user_id'] = user_id
            result.append(data)
        return result
    
    # ==================== SESSION OPERATIONS ====================
    
    async def create_session(self, user_id: str, session_data: dict) -> str:
        """Create a new session"""
        if self.demo_mode:
            return "demo_session_" + str(session_data.get('start_time', 0))
        
        doc_ref = self.db.collection('users').document(user_id).collection('sessions').document()
        session_data['id'] = doc_ref.id
        session_data['user_id'] = user_id
        doc_ref.set(session_data)
        return doc_ref.id
    
    async def get_sessions(self, user_id: str, limit: int = 50, start_time: Optional[int] = None) -> List[dict]:
        """Get user sessions"""
        if self.demo_mode:
            return []
        
        query = self.db.collection('users').document(user_id).collection('sessions').order_by('start_time', direction=firestore.Query.DESCENDING)
        
        if start_time:
            query = query.where('start_time', '>=', start_time)
        
        query = query.limit(limit)
        docs = query.stream()
        
        result = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            result.append(data)
        return result
    
    # ==================== ALERT OPERATIONS ====================
    
    async def create_alert(self, user_id: str, alert_data: dict) -> str:
        """Create a new alert"""
        if self.demo_mode:
            return "demo_alert_" + str(alert_data.get('timestamp', 0))
        
        doc_ref = self.db.collection('users').document(user_id).collection('alerts').document()
        alert_data['id'] = doc_ref.id
        alert_data['user_id'] = user_id
        doc_ref.set(alert_data)
        return doc_ref.id
    
    async def get_alerts(self, user_id: str, limit: int = 50, since_timestamp: Optional[int] = None) -> List[dict]:
        """Get user alerts"""
        if self.demo_mode:
            return []
        
        query = self.db.collection('users').document(user_id).collection('alerts').order_by('timestamp', direction=firestore.Query.DESCENDING)
        
        if since_timestamp:
            query = query.where('timestamp', '>=', since_timestamp)
        
        query = query.limit(limit)
        docs = query.stream()
        
        result = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            result.append(data)
        return result
    
    async def acknowledge_alert(self, user_id: str, alert_id: str):
        """Mark alert as acknowledged"""
        if self.demo_mode:
            return
        
        self.db.collection('users').document(user_id).collection('alerts').document(alert_id).update({
            'acknowledged': True,
            'acknowledged_at': int(datetime.utcnow().timestamp())
        })
    
    # ==================== NUTRITION OPERATIONS ====================
    
    async def create_nutrition_entry(self, user_id: str, nutrition_data: dict) -> str:
        """Create a nutrition log entry"""
        if self.demo_mode:
            return "demo_nutrition_" + str(nutrition_data.get('timestamp', 0))
        
        doc_ref = self.db.collection('users').document(user_id).collection('nutrition').document()
        nutrition_data['id'] = doc_ref.id
        nutrition_data['user_id'] = user_id
        doc_ref.set(nutrition_data)
        return doc_ref.id
    
    async def get_nutrition_entries(self, user_id: str, start_timestamp: int, end_timestamp: int) -> List[dict]:
        """Get nutrition entries for a time range"""
        if self.demo_mode:
            return []
        
        docs = self.db.collection('users').document(user_id).collection('nutrition') \
            .where('timestamp', '>=', start_timestamp) \
            .where('timestamp', '<=', end_timestamp) \
            .order_by('timestamp', direction=firestore.Query.DESCENDING) \
            .stream()
        
        result = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            result.append(data)
        return result
