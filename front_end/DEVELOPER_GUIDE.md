# Developer Guide - Firebase Integration

## Quick Start

The app now runs fully on Firebase - no backend server needed!

## Architecture Overview

```
┌─────────────────┐
│   Flutter App   │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌─────────────┐
│Firebase│ │  Cloud      │
│  Auth  │ │ Firestore   │
└────────┘ └─────────────┘
```

## Services

### 1. FirestoreService (`lib/services/firestore_service.dart`)

Direct Firestore operations for all data.

**Usage:**
```dart
final firestoreService = FirestoreService();

// User profile
await firestoreService.setUserProfile(userId, profileData);
final profile = await firestoreService.getUserProfile(userId);

// Vitals
await firestoreService.syncDailyVitals(
  userId: userId,
  date: '2024-01-15',
  readings: [...],
  summary: {...},
);

// Activities
await firestoreService.syncDailyActivity(
  userId: userId,
  date: '2024-01-15',
  steps: 8500,
  distanceKm: 6.2,
  activeMinutes: 45,
  caloriesBurned: 320,
);

// Sessions
final sessionId = await firestoreService.createSession(
  userId: userId,
  sessionData: {...},
);

// Alerts
final alertId = await firestoreService.createAlert(
  userId: userId,
  alertData: {...},
);

// Nutrition
final entryId = await firestoreService.logNutrition(
  userId: userId,
  nutritionData: {...},
);
```

### 2. FirebaseService (`lib/services/firebase_service.dart`)

Wrapper around FirestoreService for convenience.

**Usage:**
```dart
final firebaseService = FirebaseService();

// Sync data
await firebaseService.syncVitalsToCloud(userId: userId);
await firebaseService.syncActivityToCloud(userId: userId);

// Fetch history
final vitals = await firebaseService.fetchHistoricalVitals(
  userId: userId,
  days: 7,
);
```

### 3. AuthService (`lib/services/auth_service.dart`)

Firebase Authentication integration.

**Usage:**
```dart
final authService = AuthService();

// Register
final result = await authService.register(
  username: 'john_doe',
  email: 'john@example.com',
  password: 'SecurePass123',
  fullName: 'John Doe',
);

// Login
final result = await authService.login(
  usernameOrEmail: 'john@example.com',
  password: 'SecurePass123',
);

// Logout
await authService.logout();
```

## Data Flow

### Recording Health Data

```
1. User connects wearable
2. BluetoothService receives data
3. VitalsProvider updates state
4. DatabaseService stores in SQLite (offline)
5. FirebaseService syncs to Firestore (when online)
```

### Viewing Historical Data

```
1. User requests historical view
2. Check local SQLite first
3. If not available, fetch from Firestore
4. Cache in SQLite for offline access
5. Display in UI
```

## Common Patterns

### Adding New Data Type

1. **Add Firestore method:**
```dart
// In firestore_service.dart
Future<String> createNewDataType({
  required String userId,
  required Map<String, dynamic> data,
}) async {
  data['created_at'] = FieldValue.serverTimestamp();
  
  final docRef = await _firestore
      .collection('users')
      .doc(userId)
      .collection('new_data_type')
      .add(data);
  
  return docRef.id;
}
```

2. **Add wrapper in FirebaseService:**
```dart
// In firebase_service.dart
Future<String?> syncNewDataToCloud({
  required String userId,
  required Map<String, dynamic> data,
}) async {
  try {
    return await _firestoreService.createNewDataType(
      userId: userId,
      data: data,
    );
  } catch (e) {
    debugPrint('Failed to sync: $e');
    return null;
  }
}
```

3. **Update security rules:**
```javascript
// In firestore.rules
match /new_data_type/{docId} {
  allow read: if isOwner(userId);
  allow write: if isOwner(userId) && 
                 request.resource.data.required_field is string;
}
```

### Error Handling

Always wrap Firestore calls in try-catch:

```dart
try {
  await firestoreService.setUserProfile(userId, data);
  // Success
} on FirebaseException catch (e) {
  // Handle Firebase-specific errors
  if (e.code == 'permission-denied') {
    print('Access denied');
  } else if (e.code == 'not-found') {
    print('Document not found');
  }
} catch (e) {
  // Handle other errors
  print('Unexpected error: $e');
}
```

### Offline Handling

Data is automatically cached by Firestore:

```dart
// Enable offline persistence (done automatically)
await FirebaseFirestore.instance
    .settings = const Settings(persistenceEnabled: true);

// Data will be synced when back online
await firestoreService.syncDailyVitals(...);
```

## Testing

### Local Testing

```bash
cd front_end
flutter run
```

### Firestore Emulator (Optional)

```bash
# Install Firebase emulator
npm install -g firebase-tools

# Start emulator
firebase emulators:start --only firestore

# In your app, connect to emulator
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

## Debugging

### Enable Firestore Logging

```dart
// In main.dart (debug only)
if (kDebugMode) {
  FirebaseFirestore.setLoggingEnabled(true);
}
```

### Check Firestore Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Firestore Database
4. Browse collections and documents
5. Check security rules in "Rules" tab

### Common Issues

**Permission Denied:**
- User not authenticated
- Security rules blocking access
- Wrong userId in request

**Document Not Found:**
- Document doesn't exist yet
- Wrong collection/document path
- User doesn't have access

**Quota Exceeded:**
- Check Firebase Console → Usage
- May need to upgrade plan
- Optimize read/write operations

## Best Practices

### 1. Batch Operations

For multiple writes:
```dart
final batch = firestoreService.batch();

batch.set(ref1, data1);
batch.update(ref2, data2);
batch.delete(ref3);

await batch.commit();
```

### 2. Transactions

For atomic operations:
```dart
await FirebaseFirestore.instance.runTransaction((transaction) async {
  final snapshot = await transaction.get(docRef);
  final newValue = snapshot.data()['count'] + 1;
  transaction.update(docRef, {'count': newValue});
});
```

### 3. Real-time Listeners

For live updates:
```dart
FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('vitals')
    .snapshots()
    .listen((snapshot) {
      // Update UI with new data
    });
```

### 4. Pagination

For large datasets:
```dart
Query query = FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('sessions')
    .orderBy('start_time', descending: true)
    .limit(20);

// Get first page
final snapshot = await query.get();

// Get next page
if (snapshot.docs.isNotEmpty) {
  final lastDoc = snapshot.docs.last;
  query = query.startAfterDocument(lastDoc);
  final nextSnapshot = await query.get();
}
```

## Migration from API

### Before (API-based)
```dart
// OLD - Don't use
final apiService = ApiService();
await apiService.syncDailyVitals(...);
```

### After (Firestore-based)
```dart
// NEW - Use this
final firebaseService = FirebaseService();
await firebaseService.syncVitalsToCloud(userId: userId);
```

## Performance Tips

1. **Cache Frequently Used Data** - Store in memory or SQLite
2. **Use Indexes** - Add composite indexes for complex queries
3. **Limit Query Size** - Use pagination for large datasets
4. **Batch Writes** - Combine multiple writes into one batch
5. **Offline First** - Always write to SQLite first, sync later

## Security Checklist

- [ ] Security rules deployed
- [ ] Authentication required for all operations
- [ ] Users can only access their own data
- [ ] Input validation on client side
- [ ] Sensitive data encrypted
- [ ] Budget alerts configured
- [ ] Regular security audits

## Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Best Practices](https://firebase.google.com/docs/firestore/best-practices)

## Need Help?

1. Check Firebase Console for errors
2. Review Firestore security rules
3. Check app debug logs
4. Verify internet connection
5. Test with Firestore emulator
