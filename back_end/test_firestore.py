"""
Test script to verify Firestore read/write operations
Run this from the back_end directory: python test_firestore.py
"""
import asyncio
from app.utils.firebase_admin import initialize_firebase
from app.services.firebase_service import FirebaseService
from datetime import datetime

async def test_firestore_operations():
    """Test basic Firestore read/write operations"""
    
    print("\n" + "="*60)
    print("TESTING FIRESTORE READ/WRITE OPERATIONS")
    print("="*60 + "\n")
    
    # Initialize Firebase
    initialize_firebase()
    
    # Create FirebaseService instance
    firebase = FirebaseService()
    
    if firebase.demo_mode:
        print("❌ Firebase is in DEMO MODE - Firestore not connected!")
        print("   Check your serviceAccountKey.json file")
        return False
    
    print("✅ Firebase connected successfully!\n")
    
    # Test 1: Write a test user
    print("📝 TEST 1: Creating a test user...")
    test_user_data = {
        'email': f'test_{datetime.now().timestamp()}@example.com',
        'username': 'test_user',
        'full_name': 'Test User',
        'password_hash': 'dummy_hash_for_test'
    }
    
    try:
        user_id = await firebase.create_user(test_user_data)
        print(f"✅ User created with ID: {user_id}\n")
    except Exception as e:
        print(f"❌ Failed to create user: {e}\n")
        return False
    
    # Test 2: Read the user back
    print("📖 TEST 2: Reading the user back...")
    try:
        user_data = await firebase.get_user_by_id(user_id)
        if user_data:
            print(f"✅ User retrieved: {user_data['email']}\n")
        else:
            print("❌ User not found\n")
            return False
    except Exception as e:
        print(f"❌ Failed to read user: {e}\n")
        return False
    
    # Test 3: Update user profile
    print("📝 TEST 3: Creating user profile...")
    profile_data = {
        'age': 30,
        'weight_kg': 70.0,
        'height_cm': 175.0,
        'daily_calorie_goal': 2000,
        'daily_step_goal': 10000
    }
    
    try:
        await firebase.update_user_profile(user_id, profile_data)
        print(f"✅ Profile created for user\n")
    except Exception as e:
        print(f"❌ Failed to create profile: {e}\n")
        return False
    
    # Test 4: Read profile back
    print("📖 TEST 4: Reading user profile...")
    try:
        profile = await firebase.get_user_profile(user_id)
        if profile:
            print(f"✅ Profile retrieved:")
            print(f"   Age: {profile.get('age')}")
            print(f"   Weight: {profile.get('weight_kg')} kg")
            print(f"   Height: {profile.get('height_cm')} cm\n")
        else:
            print("❌ Profile not found\n")
            return False
    except Exception as e:
        print(f"❌ Failed to read profile: {e}\n")
        return False
    
    # Test 5: Store vitals data
    print("📝 TEST 5: Storing daily vitals...")
    vitals_data = {
        'date': '2025-11-17',
        'readings': [
            {'timestamp': int(datetime.now().timestamp()), 'heart_rate': 72, 'spo2': 98}
        ],
        'summary': {
            'avg_heart_rate': 72,
            'avg_spo2': 98,
            'total_readings': 1
        }
    }
    
    try:
        await firebase.store_daily_vitals(user_id, '2025-11-17', vitals_data['readings'], vitals_data['summary'])
        print(f"✅ Vitals data stored\n")
    except Exception as e:
        print(f"❌ Failed to store vitals: {e}\n")
        return False
    
    # Test 6: Read vitals back
    print("📖 TEST 6: Reading vitals data...")
    try:
        vitals = await firebase.get_vitals_by_date(user_id, '2025-11-17')
        if vitals:
            print(f"✅ Vitals retrieved:")
            print(f"   Date: {vitals.get('date')}")
            print(f"   Avg HR: {vitals.get('summary', {}).get('avg_heart_rate')}\n")
        else:
            print("❌ Vitals not found\n")
            return False
    except Exception as e:
        print(f"❌ Failed to read vitals: {e}\n")
        return False
    
    print("="*60)
    print("✅ ALL TESTS PASSED - Firestore is working correctly!")
    print("="*60 + "\n")
    
    print(f"Test user ID: {user_id}")
    print(f"You can view this data in Firebase Console:")
    print(f"https://console.firebase.google.com/project/health-track-app-9e7cf/firestore\n")
    
    return True

if __name__ == "__main__":
    success = asyncio.run(test_firestore_operations())
    exit(0 if success else 1)
