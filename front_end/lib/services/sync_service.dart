import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_service.dart';

/// Background sync service that handles periodic data synchronization
/// Syncs health data to Firebase cloud at scheduled intervals
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  bool _isInitialized = false;
  Timer? _periodicSyncTimer;
  
  /// Initialize background sync service
  /// Sets up periodic task to sync data at 11:59 PM daily
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SyncService already initialized');
      return;
    }

    try {
      debugPrint('🔄 Initializing SyncService...');
      
      // Initialize Workmanager for background tasks
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Schedule daily sync at 11:59 PM
      await scheduleDailySync();
      
      // Also start a periodic timer for manual sync every hour (optional)
      _startPeriodicSync();
      
      _isInitialized = true;
      debugPrint('✅ SyncService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize SyncService: $e');
      rethrow;
    }
  }

  /// Schedule daily sync task
  Future<void> scheduleDailySync() async {
    try {
      // Cancel any existing task
      await Workmanager().cancelByUniqueName('daily-sync');
      
      // Calculate delay until 11:59 PM today
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day, 23, 59);
      Duration delay = midnight.difference(now);
      
      // If we've passed 11:59 PM today, schedule for tomorrow
      if (delay.isNegative) {
        final tomorrow = DateTime(now.year, now.month, now.day + 1, 23, 59);
        delay = tomorrow.difference(now);
      }

      debugPrint('📅 Scheduling daily sync in ${delay.inHours}h ${delay.inMinutes % 60}m');

      // Register periodic task (runs every 24 hours)
      await Workmanager().registerPeriodicTask(
        'daily-sync',
        'syncDailyData',
        frequency: const Duration(hours: 24),
        initialDelay: delay,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
      
      debugPrint('✅ Daily sync scheduled successfully');
    } catch (e) {
      debugPrint('❌ Failed to schedule daily sync: $e');
    }
  }

  /// Start periodic sync timer (every hour in foreground)
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    
    // Sync every hour when app is in foreground
    _periodicSyncTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      debugPrint('⏰ Periodic sync triggered');
      syncNow(userId: '1'); // Default user
    });
  }

  /// Manually trigger sync now
  Future<bool> syncNow({required String userId}) async {
    try {
      debugPrint('🔄 Manual sync triggered for user: $userId');
      
      // Check if user is logged in
      final isLoggedIn = await _firebaseService.initialize();
      if (!isLoggedIn) {
        debugPrint('⚠️  User not logged in, skipping sync');
        return false;
      }

      // Sync today's vitals
      final vitalsSuccess = await _firebaseService.syncVitalsToCloud(
        userId: userId,
      );

      // Sync today's activity
      final activitySuccess = await _firebaseService.syncActivityToCloud(
        userId: userId,
      );

      if (vitalsSuccess && activitySuccess) {
        debugPrint('✅ Manual sync completed successfully');
        return true;
      } else {
        debugPrint('⚠️  Partial sync completed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Manual sync failed: $e');
      return false;
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = null;
      debugPrint('✅ All sync tasks cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel tasks: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }
}

/// Background task callback dispatcher
/// This function runs in a separate isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background task started: $task');
    
    try {
      if (task == 'syncDailyData') {
        final firebaseService = FirebaseService();
        
        // Get today's date
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayStr = yesterday.toIso8601String().split('T')[0];
        
        // Sync yesterday's data (since this runs at 11:59 PM)
        final vitalsSuccess = await firebaseService.syncVitalsToCloud(
          userId: '1', // Default user - should get from storage
          date: yesterdayStr,
        );
        
        final activitySuccess = await firebaseService.syncActivityToCloud(
          userId: '1',
          date: yesterdayStr,
        );
        
        if (vitalsSuccess && activitySuccess) {
          debugPrint('✅ Background sync completed successfully');
          return Future.value(true);
        } else {
          debugPrint('⚠️  Background sync partially failed');
          return Future.value(false);
        }
      }
      
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}
