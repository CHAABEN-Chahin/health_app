import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';

/// Firestore service for direct cloud database operations
/// Replaces the backend API with direct Firebase Firestore access
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER PROFILE ====================

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      debugPrint('📥 Fetching user profile for: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        debugPrint('✅ User profile found');
        return doc.data();
      } else {
        debugPrint('⚠️  User profile not found');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch user profile: $e');
      rethrow;
    }
  }

  /// Create or update user profile in Firestore
  Future<User> setUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      debugPrint('💾 Saving user profile for: $userId');
      
      // Add timestamps
      profileData['updated_at'] = FieldValue.serverTimestamp();
      if (!profileData.containsKey('created_at')) {
        profileData['created_at'] = FieldValue.serverTimestamp();
      }
      
      await _firestore.collection('users').doc(userId).set(
        profileData,
        SetOptions(merge: true),
      );

      debugPrint('✅ User profile saved successfully');
      var doc = await _firestore.collection('users').doc(userId).get();
      final User user = User.fromMap(doc.data()!);
      return user;

    } catch (e) {
      debugPrint('❌ Failed to save user profile: $e');
      rethrow;
    }
  }

  // ==================== VITALS ====================

  /// Sync daily vitals to Firestore
  Future<void> syncDailyVitals({
    required String userId,
    required String date,
    required List<Map<String, dynamic>> readings,
    required Map<String, dynamic> summary,
  }) async {
    try {
      debugPrint('💾 Syncing vitals for date: $date');
      
      final data = {
        'date': date,
        'readings': readings,
        'summary': summary,
        'synced_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('vitals')
          .doc(date)
          .set(data, SetOptions(merge: true));
      
      debugPrint('✅ Vitals synced successfully');
    } catch (e) {
      debugPrint('❌ Failed to sync vitals: $e');
      rethrow;
    }
  }

  /// Get historical vitals from Firestore
  Future<List<Map<String, dynamic>>> getHistoricalVitals({
    required String userId,
    required int days,
  }) async {
    try {
      debugPrint('📥 Fetching $days days of historical vitals');
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vitals')
          .where('date', isGreaterThanOrEqualTo: _formatDate(startDate))
          .where('date', isLessThanOrEqualTo: _formatDate(endDate))
          .orderBy('date', descending: true)
          .get();
      
      final data = snapshot.docs.map((doc) => {
        'date': doc.id,
        ...doc.data(),
      }).toList();
      
      debugPrint('✅ Fetched ${data.length} days of vitals');
      return data;
    } catch (e) {
      debugPrint('❌ Failed to fetch historical vitals: $e');
      return [];
    }
  }

  /// Get vitals by specific date
  Future<Map<String, dynamic>?> getVitalsByDate({
    required String userId,
    required String date,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vitals')
          .doc(date)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to fetch vitals for date $date: $e');
      return null;
    }
  }

  // ==================== ACTIVITIES ====================

  /// Sync daily activity to Firestore
  Future<void> syncDailyActivity({
    required String userId,
    required String date,
    required int steps,
    required double distanceKm,
    required int activeMinutes,
    required int caloriesBurned,
    List<Map<String, dynamic>>? hourlyBreakdown,
  }) async {
    try {
      debugPrint('💾 Syncing activity for date: $date');
      
      final data = {
        'date': date,
        'steps': steps,
        'distance_km': distanceKm,
        'active_minutes': activeMinutes,
        'calories_burned': caloriesBurned,
        'hourly_breakdown': hourlyBreakdown ?? [],
        'synced_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .doc(date)
          .set(data, SetOptions(merge: true));
      
      debugPrint('✅ Activity synced successfully');
    } catch (e) {
      debugPrint('❌ Failed to sync activity: $e');
      rethrow;
    }
  }

  /// Get historical activity from Firestore
  Future<List<Map<String, dynamic>>> getHistoricalActivity({
    required String userId,
    required int days,
  }) async {
    try {
      debugPrint('📥 Fetching $days days of historical activity');
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('date', isGreaterThanOrEqualTo: _formatDate(startDate))
          .where('date', isLessThanOrEqualTo: _formatDate(endDate))
          .orderBy('date', descending: true)
          .get();
      
      final data = snapshot.docs.map((doc) => {
        'date': doc.id,
        ...doc.data(),
      }).toList();
      
      debugPrint('✅ Fetched ${data.length} days of activity');
      return data;
    } catch (e) {
      debugPrint('❌ Failed to fetch historical activity: $e');
      return [];
    }
  }

  // ==================== SESSIONS ====================

  /// Create a workout session in Firestore
  Future<String> createSession({
    required String userId,
    required Map<String, dynamic> sessionData,
  }) async {
    try {
      debugPrint('💾 Creating workout session');
      
      sessionData['created_at'] = FieldValue.serverTimestamp();
      
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .add(sessionData);
      
      debugPrint('✅ Session created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Failed to create session: $e');
      rethrow;
    }
  }

  /// Get workout sessions from Firestore
  Future<List<Map<String, dynamic>>> getSessions({
    required String userId,
    int days = 30,
    int limit = 50,
  }) async {
    try {
      debugPrint('📥 Fetching sessions');
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('start_time', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .orderBy('start_time', descending: true)
          .limit(limit)
          .get();
      
      final sessions = snapshot.docs.map((doc) => {
        'session_id': doc.id,
        ...doc.data(),
      }).toList();
      
      debugPrint('✅ Fetched ${sessions.length} sessions');
      return sessions;
    } catch (e) {
      debugPrint('❌ Failed to fetch sessions: $e');
      return [];
    }
  }

  // ==================== ALERTS ====================

  /// Create an alert in Firestore
  Future<String> createAlert({
    required String userId,
    required Map<String, dynamic> alertData,
  }) async {
    try {
      debugPrint('💾 Creating alert');
      
      alertData['created_at'] = FieldValue.serverTimestamp();
      alertData['acknowledged'] = false;
      
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('alerts')
          .add(alertData);
      
      debugPrint('✅ Alert created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Failed to create alert: $e');
      rethrow;
    }
  }

  /// Get alerts from Firestore
  Future<List<Map<String, dynamic>>> getAlerts({
    required String userId,
    int days = 7,
    int limit = 50,
  }) async {
    try {
      debugPrint('📥 Fetching alerts');
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('alerts')
          .where('timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      final alerts = snapshot.docs.map((doc) => {
        'alert_id': doc.id,
        ...doc.data(),
      }).toList();
      
      debugPrint('✅ Fetched ${alerts.length} alerts');
      return alerts;
    } catch (e) {
      debugPrint('❌ Failed to fetch alerts: $e');
      return [];
    }
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert({
    required String userId,
    required String alertId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('alerts')
          .doc(alertId)
          .update({
        'acknowledged': true,
        'acknowledged_at': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Alert acknowledged: $alertId');
    } catch (e) {
      debugPrint('❌ Failed to acknowledge alert: $e');
      rethrow;
    }
  }

  // ==================== NUTRITION ====================

  /// Log nutrition entry in Firestore
  Future<String> logNutrition({
    required String userId,
    required Map<String, dynamic> nutritionData,
  }) async {
    try {
      debugPrint('💾 Logging nutrition entry');
      
      nutritionData['created_at'] = FieldValue.serverTimestamp();
      
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition')
          .add(nutritionData);
      
      debugPrint('✅ Nutrition entry logged: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Failed to log nutrition: $e');
      rethrow;
    }
  }

  /// Get nutrition entries from Firestore
  Future<List<Map<String, dynamic>>> getNutritionEntries({
    required String userId,
    int days = 30,
  }) async {
    try {
      debugPrint('📥 Fetching nutrition entries');
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition')
          .where('timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .orderBy('timestamp', descending: true)
          .get();
      
      final entries = snapshot.docs.map((doc) => {
        'entry_id': doc.id,
        ...doc.data(),
      }).toList();
      
      debugPrint('✅ Fetched ${entries.length} nutrition entries');
      return entries;
    } catch (e) {
      debugPrint('❌ Failed to fetch nutrition entries: $e');
      return [];
    }
  }

  // ==================== HELPER METHODS ====================

  /// Format date to YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  /// Batch write operation for efficiency
  WriteBatch batch() {
    return _firestore.batch();
  }
}
