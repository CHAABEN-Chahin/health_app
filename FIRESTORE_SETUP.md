# Firestore Setup Guide

This guide will help you set up Cloud Firestore for the HealthTrack app.

## Prerequisites

- Firebase project created at https://console.firebase.google.com
- Firebase CLI installed: `npm install -g firebase-tools`
- Firebase project connected to your Flutter app

## Step 1: Enable Firestore

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click on "Firestore Database" in the left menu
4. Click "Create database"
5. Choose "Start in test mode" (we'll update rules later)
6. Select a Cloud Firestore location (choose closest to your users)
7. Click "Enable"

## Step 2: Deploy Security Rules

### Option A: Using Firebase Console (Quick)

1. In Firebase Console, go to Firestore Database
2. Click on the "Rules" tab
3. Copy the contents of `firestore.rules` file
4. Paste into the editor
5. Click "Publish"

### Option B: Using Firebase CLI (Recommended)

1. Login to Firebase:
```bash
firebase login
```

2. Initialize Firebase in your project:
```bash
cd /path/to/health_app
firebase init firestore
```

3. Select your Firebase project

4. Use the existing `firestore.rules` file when prompted

5. Deploy the rules:
```bash
firebase deploy --only firestore:rules
```

## Step 3: Configure Indexes (Optional)

For better query performance, create composite indexes:

### Via Firebase Console:
1. Go to Firestore Database → Indexes
2. Click "Create Index"
3. Add these indexes:

**Vitals Index:**
- Collection: `users/{userId}/vitals`
- Fields: 
  - `date` (Ascending)
  - `synced_at` (Descending)

**Activities Index:**
- Collection: `users/{userId}/activities`
- Fields:
  - `date` (Ascending)
  - `synced_at` (Descending)

**Sessions Index:**
- Collection: `users/{userId}/sessions`
- Fields:
  - `start_time` (Descending)
  - `session_type` (Ascending)

**Alerts Index:**
- Collection: `users/{userId}/alerts`
- Fields:
  - `timestamp` (Descending)
  - `acknowledged` (Ascending)

**Nutrition Index:**
- Collection: `users/{userId}/nutrition`
- Fields:
  - `timestamp` (Descending)
  - `meal_type` (Ascending)

### Via Firebase CLI:
Alternatively, create `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "vitals",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "date", "order": "ASCENDING" },
        { "fieldPath": "synced_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "activities",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "date", "order": "ASCENDING" },
        { "fieldPath": "synced_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "sessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "start_time", "order": "DESCENDING" },
        { "fieldPath": "session_type", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "alerts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "timestamp", "order": "DESCENDING" },
        { "fieldPath": "acknowledged", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "nutrition",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "timestamp", "order": "DESCENDING" },
        { "fieldPath": "meal_type", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then deploy:
```bash
firebase deploy --only firestore:indexes
```

## Step 4: Set Up Budget Alerts (Recommended)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your Firebase project
3. Go to "Billing" → "Budgets & alerts"
4. Create a budget:
   - **Amount**: Set your monthly budget (e.g., $10)
   - **Alerts**: Set at 50%, 90%, 100%
   - **Email**: Add your email for notifications

## Step 5: Configure Flutter App

### Android Configuration

1. Download `google-services.json` from Firebase Console:
   - Project Settings → Your apps → Android app
   - Click "Download google-services.json"

2. Place file at:
   ```
   front_end/android/app/google-services.json
   ```

3. Verify `android/build.gradle` has:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
   }
   ```

4. Verify `android/app/build.gradle` has:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### iOS Configuration

1. Download `GoogleService-Info.plist` from Firebase Console:
   - Project Settings → Your apps → iOS app
   - Click "Download GoogleService-Info.plist"

2. Place file at:
   ```
   front_end/ios/Runner/GoogleService-Info.plist
   ```

3. Open `ios/Runner.xcworkspace` in Xcode
4. Drag `GoogleService-Info.plist` into the Runner folder
5. Ensure "Copy items if needed" is checked

## Step 6: Test the Setup

1. Run the app:
```bash
cd front_end
flutter run
```

2. Sign up with a new account

3. Check Firebase Console → Firestore Database
   - You should see a new document in `users` collection

4. Record some health data in the app

5. Check Firestore for subcollections (vitals, activities)

## Security Rules Explained

The security rules in `firestore.rules` ensure:

✅ Users can only access their own data  
✅ Authentication is required for all operations  
✅ Data validation for required fields  
✅ Subcollections inherit parent permissions  
❌ No public read/write access  
❌ Users cannot access other users' data  

## Monitoring & Maintenance

### Check Usage
1. Firebase Console → Firestore Database → Usage
2. Monitor reads, writes, and deletes
3. Check storage size

### View Logs
1. Firebase Console → Firestore Database → Rules Playground
2. Test security rules with different scenarios
3. Check denied requests

### Optimize Costs
- Enable offline persistence in app
- Cache frequently accessed data
- Batch write operations
- Use transactions for atomic updates

## Troubleshooting

### "Permission Denied" Error
- Check if user is authenticated
- Verify userId matches in security rules
- Test rules in Firebase Console Rules Playground

### Missing Data
- Check Firestore console for documents
- Verify collection/document paths
- Check app logs for errors
- Ensure offline persistence is enabled

### Slow Queries
- Check if indexes are created
- Monitor query performance in Firebase
- Consider adding more indexes

### High Costs
- Review usage metrics
- Check for excessive reads/writes
- Enable caching in app
- Use batch operations

## Best Practices

1. **Always authenticate users** before accessing Firestore
2. **Validate data** on client side before writing
3. **Use batch writes** for multiple operations
4. **Enable offline persistence** for better UX
5. **Monitor costs** regularly
6. **Test security rules** thoroughly
7. **Backup important data** (automatic in Firestore)
8. **Use transactions** for critical operations

## Next Steps

- [x] Enable Firestore
- [x] Deploy security rules
- [ ] Configure indexes
- [ ] Set up budget alerts
- [ ] Test authentication
- [ ] Test data sync
- [ ] Monitor usage
- [ ] Optimize queries

## Resources

- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Security Rules Reference](https://firebase.google.com/docs/firestore/security/get-started)
- [FlutterFire Setup](https://firebase.flutter.dev/docs/firestore/overview/)
- [Pricing Calculator](https://firebase.google.com/pricing)

## Support

If you encounter issues:
1. Check [Firebase Status](https://status.firebase.google.com/)
2. Review [FlutterFire Issues](https://github.com/firebase/flutterfire/issues)
3. Check app logs for specific errors
