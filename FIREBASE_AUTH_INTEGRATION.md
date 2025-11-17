# Firebase Authentication Integration

## Overview

This document describes the Firebase Authentication integration that eliminates password storage in the backend while maintaining backend awareness of authenticated users.

## Architecture

### Before (Old Flow)
```
Frontend → Backend (/auth/signup with email/password)
→ Backend hashes password
→ Backend stores password_hash in Firestore
→ Backend returns JWT

Frontend → Backend (/auth/login with email/password)
→ Backend verifies password hash
→ Backend returns JWT
```

**Problems:**
- ❌ Password duplication (Firebase + Backend)
- ❌ Backend responsible for password security
- ❌ Complex password management
- ❌ Increased security risks

### After (New Flow)
```
SIGNUP:
Frontend → Firebase Auth (email/password)
→ Firebase creates user
→ Frontend gets Firebase ID token
→ Frontend → Backend (/auth/signup with ID token + username)
→ Backend verifies ID token with Firebase Admin SDK
→ Backend creates user record (NO password stored)
→ Backend returns JWT for API authorization

LOGIN:
Frontend → Firebase Auth (email/password)
→ Firebase verifies password
→ Frontend gets Firebase ID token
→ Frontend → Backend (/auth/login with ID token)
→ Backend verifies ID token with Firebase Admin SDK
→ Backend finds user by firebase_uid
→ Backend returns JWT for API authorization

API CALLS:
Frontend → Backend API (with JWT Bearer token)
→ Backend verifies JWT
→ Process request
```

**Benefits:**
- ✅ Single source of truth: Firebase handles authentication
- ✅ No password storage in backend
- ✅ Backend still aware of auth via token verification
- ✅ Access to Firebase features (password reset, email verification, 2FA)
- ✅ Better security posture
- ✅ Simplified password management

## Implementation Details

### Backend Changes

#### 1. Schema Updates (`app/schemas/auth.py`)

**Before:**
```python
class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    username: str
    full_name: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
```

**After:**
```python
class SignupRequest(BaseModel):
    firebase_id_token: str  # No more password!
    username: str
    full_name: str

class LoginRequest(BaseModel):
    firebase_id_token: str  # No more password!
```

#### 2. Firebase Admin SDK (`app/utils/firebase_admin.py`)

Added token verification function:

```python
from firebase_admin import auth

def verify_firebase_token(id_token: str) -> Optional[Dict]:
    """Verify Firebase ID token and return decoded token"""
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token  # Contains: uid, email, etc.
    except auth.InvalidIdTokenError:
        return None
    except auth.ExpiredIdTokenError:
        return None
```

#### 3. Auth Service (`app/services/auth_service.py`)

**Signup - Before:**
```python
async def signup(self, email: str, password: str, username: str, full_name: str):
    password_hash = self.security.hash_password(password)  # ❌
    user_data = {
        'email': email,
        'password_hash': password_hash,  # ❌ Stored password
        'username': username,
        'full_name': full_name,
    }
    user_id = await self.firebase_service.create_user(user_data)
    return {'user_id': user_id, 'email': email, 'username': username}
```

**Signup - After:**
```python
async def signup(self, firebase_id_token: str, username: str, full_name: str):
    # Verify Firebase token
    decoded_token = verify_firebase_token(firebase_id_token)
    if not decoded_token:
        raise ValueError("Invalid Firebase ID token")
    
    firebase_uid = decoded_token.get('uid')
    email = decoded_token.get('email')
    
    # Create user record WITHOUT password
    user_data = {
        'firebase_uid': firebase_uid,  # ✅ Link to Firebase user
        'email': email,
        'username': username,
        'full_name': full_name,
        # NO password_hash! ✅
    }
    user_id = await self.firebase_service.create_user(user_data)
    return {'user_id': user_id, 'email': email, 'username': username}
```

**Login - Before:**
```python
async def login(self, email: str, password: str):
    user = await self.firebase_service.get_user_by_email(email)
    if not user:
        raise ValueError("Invalid credentials")
    
    # Verify password hash ❌
    if not self.security.verify_password(password, user['password_hash']):
        raise ValueError("Invalid credentials")
    
    return {'user_id': user['id'], 'email': user['email'], 'username': user['username']}
```

**Login - After:**
```python
async def login(self, firebase_id_token: str):
    # Verify Firebase token
    decoded_token = verify_firebase_token(firebase_id_token)
    if not decoded_token:
        raise ValueError("Invalid Firebase ID token")
    
    firebase_uid = decoded_token.get('uid')
    
    # Find user by Firebase UID
    user = await self.firebase_service.get_user_by_firebase_uid(firebase_uid)
    if not user:
        raise ValueError("User not found. Please complete signup first.")
    
    return {'user_id': user['id'], 'email': user['email'], 'username': user['username']}
```

#### 4. Firebase Service (`app/services/firebase_service.py`)

Added new method:
```python
async def get_user_by_firebase_uid(self, firebase_uid: str) -> Optional[dict]:
    """Get user by Firebase UID"""
    users = self.db.collection('users').where('firebase_uid', '==', firebase_uid).limit(1).stream()
    for user in users:
        data = user.to_dict()
        data['id'] = user.id
        return data
    return None
```

### Frontend Changes

#### 1. API Service (`lib/services/api_service.dart`)

**Before:**
```dart
Future<Map<String, dynamic>> signup({
  required String email,
  required String password,  // ❌
  required String username,
  required String fullName,
}) async {
  final response = await _dio.post('/auth/signup', data: {
    'email': email,
    'password': password,  // ❌ Sent to backend
    'username': username,
    'full_name': fullName,
  });
  return response.data;
}
```

**After:**
```dart
Future<Map<String, dynamic>> signup({
  required String firebaseIdToken,  // ✅ Token instead of password
  required String username,
  required String fullName,
}) async {
  final response = await _dio.post('/auth/signup', data: {
    'firebase_id_token': firebaseIdToken,  // ✅ Secure token
    'username': username,
    'full_name': fullName,
    // NO password sent! ✅
  });
  return response.data;
}
```

#### 2. Auth Service (`lib/services/auth_service.dart`)

**Signup - Before:**
```dart
final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

await _apiService.signup(
  email: email,
  password: password,  // ❌ Password sent to backend
  username: username,
  fullName: fullName,
);
```

**Signup - After:**
```dart
final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
  email: email,
  password: password,  // ✅ Only Firebase sees password
);

final idToken = await _firebaseUser!.getIdToken();  // ✅ Get secure token

await _apiService.signup(
  firebaseIdToken: idToken,  // ✅ Token sent to backend
  username: username,
  fullName: fullName,
  // NO password sent! ✅
);
```

**Login - Before:**
```dart
await _firebaseAuth.signInWithEmailAndPassword(
  email: usernameOrEmail,
  password: password,
);

await _apiService.login(usernameOrEmail, password);  // ❌ Password sent
```

**Login - After:**
```dart
await _firebaseAuth.signInWithEmailAndPassword(
  email: usernameOrEmail,
  password: password,  // ✅ Only Firebase sees password
);

final idToken = await _firebaseUser!.getIdToken();  // ✅ Get secure token
await _apiService.login(idToken);  // ✅ Token sent instead
```

#### 3. User Model (`lib/models/user.dart`)

**Removed:**
- `passwordHash` field
- `password_hash` from toMap() and fromMap()
- `passwordHash` from copyWith()

The User model no longer contains any password-related fields.

## Security Considerations

### Token Security

1. **Firebase ID Tokens are short-lived** (1 hour by default)
   - Reduces risk of token theft
   - Automatically refreshed by Firebase SDK

2. **Token Verification**
   - Backend verifies tokens with Firebase Admin SDK
   - Invalid/expired tokens rejected immediately
   - No direct password handling in backend

3. **JWT for API Authorization**
   - Backend still issues JWT for API calls
   - JWT contains only necessary user info
   - Separate from Firebase authentication

### Best Practices

1. **Never log ID tokens** in production
2. **Use HTTPS** for all API calls (tokens in headers)
3. **Implement rate limiting** on auth endpoints
4. **Monitor failed authentication attempts**
5. **Use Firebase Security Rules** for Firestore access

## Migration Strategy

### For Existing Users

If you have existing users with password_hash in the database:

1. **Keep old login working temporarily**:
   - Add a flag `migrated: boolean` to user records
   - Support both old (password) and new (token) login flows
   - When user logs in with password, mark as `migrated: false`
   - Prompt user to "secure their account" (triggers token-based flow)

2. **Gradual migration**:
   - Send email to users about security upgrade
   - Offer password reset (Firebase) as migration trigger
   - After reset, user automatically uses new flow

3. **Data cleanup**:
   - After migration period, remove `password_hash` field
   - Keep `firebase_uid` for linking

### For New Users

- New registrations automatically use Firebase Auth
- No password ever stored in backend
- Seamless experience from day one

## Testing

### Unit Tests

Test Firebase token verification:
```python
def test_verify_valid_token():
    token = create_test_token()
    result = verify_firebase_token(token)
    assert result is not None
    assert 'uid' in result

def test_verify_invalid_token():
    result = verify_firebase_token("invalid_token")
    assert result is None
```

### Integration Tests

Test auth flow:
```python
async def test_signup_with_firebase_token():
    # Create Firebase user (test environment)
    token = await create_firebase_user("test@example.com", "password")
    
    # Call backend signup
    response = await client.post("/auth/signup", json={
        "firebase_id_token": token,
        "username": "testuser",
        "full_name": "Test User"
    })
    
    assert response.status_code == 201
    assert "access_token" in response.json()
```

## Troubleshooting

### Common Issues

**1. "Invalid Firebase ID token"**
- Token may have expired (1 hour lifetime)
- Get fresh token from Firebase: `user.getIdToken(true)`
- Verify Firebase Admin SDK is initialized correctly

**2. "User not found. Please complete signup first."**
- User authenticated with Firebase but not registered in backend
- Direct user to complete signup flow
- May occur if backend registration failed during initial signup

**3. "Firebase initialization failed"**
- Check Firebase credentials are configured
- Verify `FIREBASE_CREDENTIALS_PATH` or environment variables
- Check Firebase project settings

**4. Token verification slow**
- Firebase verifies tokens remotely (first time)
- Subsequent verifications use cached public keys
- Consider caching if high volume

## Future Enhancements

- [ ] Support for OAuth providers (Google, Apple, Facebook)
- [ ] Multi-factor authentication (MFA)
- [ ] Email verification enforcement
- [ ] Phone number authentication
- [ ] Custom token claims for roles/permissions
- [ ] Token refresh automation
- [ ] Session management improvements

## References

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Firebase Admin SDK - Verify ID Tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens)
- [Firebase Security Best Practices](https://firebase.google.com/docs/rules/best-practices)
