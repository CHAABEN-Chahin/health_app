# Firebase Backend Integration

This document describes the integration between the Flutter frontend and the FastAPI backend with Firebase.

## Overview

The frontend has been updated to sync health data with the Firebase backend instead of relying solely on mock data. The integration follows a **local-first** approach where:

1. **Real-time data** is stored locally in SQLite
2. **Background sync** uploads data to Firebase at the end of each day
3. **Historical data** is fetched from Firebase when not available locally
4. **Mock data** is used as a fallback when cloud data is unavailable

## New Services

### 1. FirebaseService (`lib/services/firebase_service.dart`)

Main service wrapper for cloud operations via the backend API.

**Key Methods:**
- `syncVitalsToCloud()` - Sync vital signs (heart rate, SpO2, temperature) to cloud
- `syncActivityToCloud()` - Sync wellness metrics (steps, calories, distance) to cloud
- `fetchHistoricalVitals()` - Retrieve historical vital signs from cloud
- `fetchHistoricalActivity()` - Retrieve historical activity data from cloud
- `syncProfileToCloud()` - Sync user profile to cloud
- `fetchProfileFromCloud()` - Retrieve user profile from cloud
- `syncAlertToCloud()` - Sync health alerts to cloud

**Usage Example:**
```dart
final firebaseService = FirebaseService();

// Sync today's data
await firebaseService.syncVitalsToCloud(userId: '1');
await firebaseService.syncActivityToCloud(userId: '1');

// Fetch last 7 days of data
final historicalVitals = await firebaseService.fetchHistoricalVitals(
  userId: '1',
  days: 7,
);
```

### 2. SyncService (`lib/services/sync_service.dart`)

Background sync manager that handles automatic data synchronization.

**Features:**
- Schedules daily sync at 11:59 PM using Workmanager
- Periodic foreground sync every hour
- Manual sync trigger via `syncNow()`
- Runs in background isolate for end-of-day sync

**Initialization:**
```dart
// In main.dart
await SyncService().initialize();
```

## Modified Components

### 1. VitalsProvider

**Changes:**
- Added `FirebaseService` integration
- `loadHistoricalVitals()` now fetches from cloud when local database is empty
- New `syncTodayToCloud()` method for manual sync

**Example:**
```dart
final vitalsProvider = Provider.of<VitalsProvider>(context);

// Manual sync
await vitalsProvider.syncTodayToCloud();
```

### 2. DailyActivityScreen

**Changes:**
- Added `FirebaseService` integration
- Attempts to fetch activity data from cloud when local database is empty
- Falls back to mock data if cloud fetch fails

### 3. Main Application

**Changes:**
- Initializes `SyncService` on app startup
- Background sync automatically scheduled

## Data Flow

### Real-time Data Collection
```
Wearable Device → Bluetooth → BluetoothService → VitalsProvider → SQLite
```

### Background Sync (11:59 PM Daily)
```
SQLite → FirebaseService → API Service → FastAPI Backend → Firebase Firestore
```

### Historical Data Retrieval
```
User Request → VitalsProvider/DailyActivityScreen → FirebaseService → API Service → FastAPI Backend → Firebase Firestore
```

## Backend API Integration

The frontend communicates with the FastAPI backend through `ApiService` (`lib/services/api_service.dart`).

**Base URL:** `http://localhost:8000/api/v1` (configurable in `api_service.dart`)

**Key Endpoints Used:**
- `POST /vitals/sync` - Upload daily vitals
- `GET /vitals/historical?days=7` - Retrieve historical vitals
- `POST /activities/sync` - Upload daily activity
- `GET /activities/historical?days=7` - Retrieve historical activity
- `GET /users/me/profile` - Get user profile
- `PUT /users/me/profile` - Update user profile
- `POST /alerts` - Create health alert

## Configuration

### Frontend Configuration

Update the API base URL in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
// For production: 'https://your-api.com/api/v1'
```

### Backend Configuration

The backend requires a `.env` file with Firebase credentials:

```env
# Copy from .env.example
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
```

**Note:** The backend works in **demo mode** without Firebase credentials for testing.

## Testing

### 1. Start the Backend

```bash
cd back_end
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 2. Verify API is Running

Open http://localhost:8000/docs to see the interactive API documentation.

### 3. Run the Flutter App

```bash
cd front_end
flutter run
```

### 4. Test Sync

The app will:
- Generate real-time data from mock sensors (or actual Bluetooth device)
- Store data in local SQLite database
- Automatically sync to cloud at 11:59 PM (or manually via `syncTodayToCloud()`)

### 5. Verify Cloud Data

Check the Firebase Firestore console or use the API endpoints to verify data was synced.

## Mock Data Fallback

The app still uses mock data generation as a fallback when:
- Backend is not running
- No internet connection
- No cloud data available
- User is not authenticated

This ensures the app remains functional in offline mode.

## Security

- API tokens stored securely using `flutter_secure_storage`
- JWT authentication for all API requests
- Automatic token refresh on expiry
- Logout on 401 unauthorized responses

## Limitations & Future Work

1. **Conversion Layer Needed:** Cloud data needs proper conversion to local model objects
2. **Conflict Resolution:** No handling for cloud/local data conflicts yet
3. **Partial Sync:** No incremental sync - uploads entire day's data
4. **Error Recovery:** Limited retry logic on sync failures
5. **Multi-user:** Currently hardcoded to user ID '1'

## Troubleshooting

### Backend Connection Failed

**Error:** "Connection timeout" or "Network error"

**Solution:**
- Verify backend is running on port 8000
- Update `baseUrl` in `api_service.dart`
- Check firewall settings

### Sync Not Working

**Error:** "Already syncing" or "Cloud sync failed"

**Solution:**
- Check authentication status
- Verify user has valid JWT token
- Check backend logs for errors
- Ensure data exists in local database

### No Historical Data

**Issue:** Empty charts even after sync

**Solution:**
- Verify sync completed successfully
- Check Firebase Firestore for data
- Ensure date range is correct
- Check API endpoint responses in backend logs

## References

- [Backend Integration Guide](BACKEND_INTEGRATION_GUIDE.md)
- [API Quick Reference](back_end/API_QUICK_REFERENCE.md)
- [Frontend Services](front_end/lib/services/)
