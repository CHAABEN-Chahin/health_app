import 'dart:async';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import 'database_service.dart';

/// Firebase service wrapper that handles cloud sync operations
/// This service acts as an intermediary between the local database and Firestore
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isSyncing = false;
  String? _lastError;
  
  // Getters
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;

  /// Initialize Firebase service
  Future<bool> initialize() async {
    try {
      // Firebase is always initialized via firebase_core
      return true;
    } catch (e) {
      debugPrint('FirebaseService initialization error: $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Sync vitals data to Firebase (end-of-day or manual)
  Future<bool> syncVitalsToCloud({
    required String userId,
    String? date,
  }) async {
    if (_isSyncing) {
      debugPrint('Already syncing, skipping duplicate request');
      return false;
    }

    try {
      _isSyncing = true;
      _lastError = null;

      // Use today's date if not specified
      final syncDate = date ?? DateTime.now().toIso8601String().split('T')[0];
      
      debugPrint('🔄 Syncing vitals for date: $syncDate');

      // Get vitals from local database for the specified date
      // Calculate start and end timestamps for the date
      final dateTime = DateTime.parse(syncDate);
      final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final vitals = await _databaseService.getVitalSignsInRange(
        userId,
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      );
      
      if (vitals.isEmpty) {
        debugPrint('⚠️  No vitals to sync for $syncDate');
        _isSyncing = false;
        return true; // Not an error, just no data
      }

      // Prepare readings data
      final readings = vitals.map((vital) => {
        'timestamp': vital.timestamp,
        'heart_rate': vital.heartRate,
        'spo2': vital.spo2,
        'temperature': vital.temperature,
      }).toList();

      // Calculate summary statistics
      final summary = _calculateVitalsSummary(vitals);

      // Sync to cloud via Firestore
      await _firestoreService.syncDailyVitals(
        userId: userId,
        date: syncDate,
        readings: readings,
        summary: summary,
      );

      debugPrint('✅ Successfully synced ${vitals.length} vitals to cloud');
      _isSyncing = false;
      return true;
    } catch (e) {
      debugPrint('❌ Failed to sync vitals: $e');
      _lastError = e.toString();
      _isSyncing = false;
      return false;
    }
  }

  /// Sync activity/wellness data to Firebase
  Future<bool> syncActivityToCloud({
    required String userId,
    String? date,
  }) async {
    try {
      final syncDate = date ?? DateTime.now().toIso8601String().split('T')[0];
      debugPrint('🔄 Syncing activity for date: $syncDate');

      // Get wellness metrics from local database
      final metrics = await _databaseService.getWellnessMetricsForDate(userId, syncDate);
      
      if (metrics == null) {
        debugPrint('⚠️  No activity data to sync for $syncDate');
        return true;
      }

      // Sync to cloud via Firestore
      await _firestoreService.syncDailyActivity(
        userId: userId,
        date: syncDate,
        steps: metrics.steps ?? 0,
        distanceKm: metrics.distanceKm ?? 0.0,
        activeMinutes: metrics.activeMinutes ?? 0,
        caloriesBurned: metrics.caloriesBurned ?? 0,
      );

      debugPrint('✅ Successfully synced activity data to cloud');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to sync activity: $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Fetch historical vitals from cloud and cache locally
  Future<List<Map<String, dynamic>>> fetchHistoricalVitals({
    required String userId,
    required int days,
  }) async {
    try {
      debugPrint('📥 Fetching $days days of historical vitals from cloud');
      
      final historicalData = await _firestoreService.getHistoricalVitals(
        userId: userId,
        days: days,
      );
      
      debugPrint('✅ Fetched ${historicalData.length} days of vitals from cloud');
      return historicalData;
    } catch (e) {
      debugPrint('❌ Failed to fetch historical vitals: $e');
      _lastError = e.toString();
      return [];
    }
  }

  /// Fetch historical activity from cloud and cache locally
  Future<List<Map<String, dynamic>>> fetchHistoricalActivity({
    required String userId,
    required int days,
  }) async {
    try {
      debugPrint('📥 Fetching $days days of historical activity from cloud');
      
      final historicalData = await _firestoreService.getHistoricalActivity(
        userId: userId,
        days: days,
      );
      
      debugPrint('✅ Fetched ${historicalData.length} days of activity from cloud');
      return historicalData;
    } catch (e) {
      debugPrint('❌ Failed to fetch historical activity: $e');
      _lastError = e.toString();
      return [];
    }
  }

  /// Sync user profile to cloud
  Future<bool> syncProfileToCloud({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      debugPrint('🔄 Syncing user profile to cloud');
      
      await _firestoreService.setUserProfile(userId, profileData);
      
      debugPrint('✅ Successfully synced profile to cloud');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to sync profile: $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Fetch user profile from cloud and cache locally
  Future<Map<String, dynamic>?> fetchProfileFromCloud(String userId) async {
    try {
      debugPrint('📥 Fetching user profile from cloud');
      
      final profile = await _firestoreService.getUserProfile(userId);
      
      debugPrint('✅ Fetched profile from cloud');
      return profile;
    } catch (e) {
      debugPrint('❌ Failed to fetch profile: $e');
      _lastError = e.toString();
      return null;
    }
  }

  /// Sync alert to cloud
  Future<String?> syncAlertToCloud(String userId, Map<String, dynamic> alertData) async {
    try {
      debugPrint('🔄 Syncing alert to cloud');
      
      final alertId = await _firestoreService.createAlert(
        userId: userId,
        alertData: alertData,
      );
      
      debugPrint('✅ Successfully synced alert to cloud: $alertId');
      return alertId;
    } catch (e) {
      debugPrint('❌ Failed to sync alert: $e');
      _lastError = e.toString();
      return null;
    }
  }

  /// Calculate summary statistics for vitals
  Map<String, dynamic> _calculateVitalsSummary(List<dynamic> vitals) {
    if (vitals.isEmpty) {
      return {
        'avg_heart_rate': null,
        'min_heart_rate': null,
        'max_heart_rate': null,
        'avg_spo2': null,
        'min_spo2': null,
        'max_spo2': null,
        'avg_temperature': null,
        'min_temperature': null,
        'max_temperature': null,
      };
    }

    // Calculate heart rate stats
    final heartRates = vitals
        .map((v) => v.heartRate as int?)
        .where((hr) => hr != null)
        .cast<int>()
        .toList();
    
    final spo2Values = vitals
        .map((v) => v.spo2 as int?)
        .where((spo2) => spo2 != null)
        .cast<int>()
        .toList();
    
    final tempValues = vitals
        .map((v) => v.temperature as double?)
        .where((temp) => temp != null)
        .cast<double>()
        .toList();

    return {
      'avg_heart_rate': heartRates.isNotEmpty
          ? heartRates.reduce((a, b) => a + b) / heartRates.length
          : null,
      'min_heart_rate': heartRates.isNotEmpty
          ? heartRates.reduce((a, b) => a < b ? a : b)
          : null,
      'max_heart_rate': heartRates.isNotEmpty
          ? heartRates.reduce((a, b) => a > b ? a : b)
          : null,
      'avg_spo2': spo2Values.isNotEmpty
          ? spo2Values.reduce((a, b) => a + b) / spo2Values.length
          : null,
      'min_spo2': spo2Values.isNotEmpty
          ? spo2Values.reduce((a, b) => a < b ? a : b)
          : null,
      'max_spo2': spo2Values.isNotEmpty
          ? spo2Values.reduce((a, b) => a > b ? a : b)
          : null,
      'avg_temperature': tempValues.isNotEmpty
          ? tempValues.reduce((a, b) => a + b) / tempValues.length
          : null,
      'min_temperature': tempValues.isNotEmpty
          ? tempValues.reduce((a, b) => a < b ? a : b)
          : null,
      'max_temperature': tempValues.isNotEmpty
          ? tempValues.reduce((a, b) => a > b ? a : b)
          : null,
    };
  }

  /// Clear last error
  void clearError() {
    _lastError = null;
  }
}
