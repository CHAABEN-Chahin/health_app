import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../services/database_service.dart';
import '../services/alert_engine.dart';

class AlertsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AlertEngine _alertEngine = AlertEngine();
  
  List<Alert> _allAlerts = [];
  List<Alert> _unreadAlerts = [];
  List<Alert> _unacknowledgedAlerts = [];
  
  StreamSubscription<Alert>? _alertStreamSubscription;
  
  bool _isLoading = false;
  String? _error;
  
  // Filter state
  String? _currentFilter;
  
  // Getters
  List<Alert> get allAlerts => _allAlerts;
  List<Alert> get unreadAlerts => _unreadAlerts;
  List<Alert> get unacknowledgedAlerts => _unacknowledgedAlerts;
  int get unreadCount => _unreadAlerts.length;
  int get unacknowledgedCount => _unacknowledgedAlerts.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentFilter => _currentFilter;
  
  /// Get filtered alerts based on current filter (only unacknowledged)
  List<Alert> get filteredAlerts {
    final unacknowledged = _allAlerts.where((alert) => !alert.acknowledged).toList();
    if (_currentFilter == null) {
      return unacknowledged;
    }
    return unacknowledged.where((alert) => alert.severity == _currentFilter).toList();
  }
  
  /// Get alerts by severity (unacknowledged only)
  List<Alert> get emergencyAlerts => 
      _allAlerts.where((a) => a.severity == 'EMERGENCY' && !a.acknowledged).toList();
  
  List<Alert> get criticalAlerts => 
      _allAlerts.where((a) => a.severity == 'CRITICAL' && !a.acknowledged).toList();
  
  List<Alert> get warningAlerts => 
      _allAlerts.where((a) => a.severity == 'WARNING' && !a.acknowledged).toList();
  
  AlertsProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await loadAlerts();
    _subscribeToAlertStream();
  }
  
  /// Subscribe to alert creation stream for real-time updates
  void _subscribeToAlertStream() {
    _alertStreamSubscription = _alertEngine.alertCreatedStream.listen((alert) {
      debugPrint('🔔 AlertsProvider: New alert received - ${alert.severity} ${alert.vitalType}');
      
      // Add new alert to the list
      _allAlerts.insert(0, alert); // Add at the beginning (most recent first)
      
      // Update unread and unacknowledged lists
      if (!alert.isRead) {
        _unreadAlerts.insert(0, alert);
      }
      if (!alert.acknowledged) {
        _unacknowledgedAlerts.insert(0, alert);
      }
      
      debugPrint('🔔 AlertsProvider: Unacknowledged count now: ${_unacknowledgedAlerts.length}');
      
      // Notify listeners to update UI (THIS TRIGGERS BADGE UPDATE)
      notifyListeners();
    }, onError: (error) {
      debugPrint('❌ AlertsProvider: Stream error: $error');
    });
  }
  
  /// Load all alerts from database
  Future<void> loadAlerts({int userId = 1}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _allAlerts = await _databaseService.getAlertsForUser(userId);
      _allAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
      
      _unreadAlerts = _allAlerts.where((alert) => !alert.isRead).toList();
      _unacknowledgedAlerts = _allAlerts.where((alert) => !alert.acknowledged).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load alerts: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load alerts for a specific time range
  Future<void> loadAlertsInRange({
    required int userId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _allAlerts = await _databaseService.getAlertsInRange(
        userId,
        startTime.millisecondsSinceEpoch,
        endTime.millisecondsSinceEpoch,
      );
      _allAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _unreadAlerts = _allAlerts.where((alert) => !alert.isRead).toList();
      _unacknowledgedAlerts = _allAlerts.where((alert) => !alert.acknowledged).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load alerts: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Mark alert as read
  Future<void> markAsRead(String alertId) async {
    try {
      final success = await _databaseService.markAlertAsRead(alertId);
      
      if (success) {
        // Update local state
        final index = _allAlerts.indexWhere((a) => a.id == alertId);
        if (index != -1) {
          _allAlerts[index] = _allAlerts[index].copyWith(isRead: true);
        }
        
        _unreadAlerts = _allAlerts.where((alert) => !alert.isRead).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to mark alert as read: $e';
      notifyListeners();
    }
  }
  
  /// Acknowledge alert (removes it from view)
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      final result = await _databaseService.acknowledgeAlert(alertId);
      
      if (result > 0) {
        // Update local state
        final index = _allAlerts.indexWhere((a) => a.id == alertId);
        if (index != -1) {
          _allAlerts[index] = _allAlerts[index].copyWith(acknowledged: true);
        }
        
        _unacknowledgedAlerts = _allAlerts.where((alert) => !alert.acknowledged).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to acknowledge alert: $e';
      notifyListeners();
    }
  }
  
  /// Acknowledge multiple alerts at once
  Future<void> acknowledgeMultiple(List<String> alertIds) async {
    try {
      for (final alertId in alertIds) {
        await _databaseService.acknowledgeAlert(alertId);
      }
      
      // Update local state
      for (final alertId in alertIds) {
        final index = _allAlerts.indexWhere((a) => a.id == alertId);
        if (index != -1) {
          _allAlerts[index] = _allAlerts[index].copyWith(acknowledged: true);
        }
      }
      
      _unacknowledgedAlerts = _allAlerts.where((alert) => !alert.acknowledged).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to acknowledge alerts: $e';
      notifyListeners();
    }
  }
  
  /// Mark all alerts as read
  Future<void> markAllAsRead({int userId = 1}) async {
    try {
      for (var alert in _unreadAlerts) {
        await _databaseService.markAlertAsRead(alert.id);
      }
      
      // Update local state
      _allAlerts = _allAlerts.map((alert) {
        return Alert(
          id: alert.id,
          userId: alert.userId,
          severity: alert.severity,
          title: alert.title,
          message: alert.message,
          recommendation: alert.recommendation,
          vitalType: alert.vitalType,
          vitalValue: alert.vitalValue,
          timestamp: alert.timestamp,
          isRead: true,
        );
      }).toList();
      
      _unreadAlerts.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark all as read: $e';
      notifyListeners();
    }
  }
  
  /// Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      final success = await _databaseService.deleteAlert(alertId);
      
      if (success) {
        _allAlerts.removeWhere((a) => a.id == alertId);
        _unreadAlerts.removeWhere((a) => a.id == alertId);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to delete alert: $e';
      notifyListeners();
    }
  }
  
  /// Clear all alerts
  Future<void> clearAllAlerts({int userId = 1}) async {
    try {
      // Delete all alerts for user
      for (var alert in _allAlerts) {
        await _databaseService.deleteAlert(alert.id);
      }
      
      _allAlerts.clear();
      _unreadAlerts.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear alerts: $e';
      notifyListeners();
    }
  }
  
  /// Set severity filter
  void setFilter(String? severity) {
    _currentFilter = severity;
    notifyListeners();
  }
  
  /// Clear filter
  void clearFilter() {
    _currentFilter = null;
    notifyListeners();
  }
  
  /// Get alert count by severity
  Map<String, int> getAlertCountsBySeverity() {
    return {
      'EMERGENCY': emergencyAlerts.length,
      'CRITICAL': criticalAlerts.length,
      'WARNING': warningAlerts.length,
    };
  }
  
  /// Get alerts from last 24 hours
  List<Alert> getAlertsLast24Hours() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    final yesterdayMs = yesterday.millisecondsSinceEpoch;
    return _allAlerts.where((alert) => alert.timestamp > yesterdayMs).toList();
  }
  
  /// Get alerts from last 7 days
  List<Alert> getAlertsLast7Days() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekAgoMs = weekAgo.millisecondsSinceEpoch;
    return _allAlerts.where((alert) => alert.timestamp > weekAgoMs).toList();
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertStreamSubscription?.cancel();
    super.dispose();
  }
}
