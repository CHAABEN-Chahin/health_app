import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/vital_sign.dart';
import '../services/bluetooth_service.dart';
import '../services/database_service.dart';
import '../services/alert_engine.dart';
import '../services/firebase_service.dart';
import '../models/wellness_metrics.dart';
import 'package:intl/intl.dart';

class VitalsProvider extends ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();
  final DatabaseService _databaseService = DatabaseService();
  final AlertEngine _alertEngine = AlertEngine();
  final FirebaseService _firebaseService = FirebaseService();
  
  VitalSign? _currentVitals;
  List<VitalSign> _recentVitals = [];
  List<VitalSign> _historicalVitals = [];
  
  StreamSubscription<Map<String, dynamic>>? _vitalsSubscription;
  Timer? _alertCheckTimer;
  bool _isLoading = false;
  String? _error;
  
  // Track last alert times for cooldown-based deduplication
  final Map<String, DateTime> _lastAlertTimes = {};
  final Duration _alertCooldown = const Duration(minutes: 5);
  
  // Activity tracking (calculated from sensor data)
  int _stepsToday = 0;
  int _caloriesToday = 0;
  double _distanceKmToday = 0.0;
  int _activeMinutesToday = 0;
  DateTime _lastSensorUpdate = DateTime.now();
  DateTime _todayDate = DateTime.now();
  
  // Step detection state
  bool _isPeakDetected = false;
  int _samplesSincePeak = 0;
  final double _stepThreshold = 1.5; // Acceleration threshold for step detection
  final int _minSamplesBetweenSteps = 2; // Min samples (10s at 5s intervals = 2 samples)
  
  // Getters
  VitalSign? get currentVitals => _currentVitals;
  List<VitalSign> get recentVitals => _recentVitals;
  List<VitalSign> get historicalVitals => _historicalVitals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get specific vital values
  double get currentHeartRate => (_currentVitals?.heartRate ?? 0).toDouble();
  double get currentSpO2 => (_currentVitals?.spo2 ?? 0).toDouble();
  double get currentTemperature => _currentVitals?.temperature ?? 0.0;
  
  String _userId = '1';
  
  VitalsProvider() {
    _initialize();
  }
  
  void setUserId(String userId) {
    _userId = userId;
  }
  
  Future<void> _initialize() async {
    await loadRecentVitals(userId: _userId);
    subscribeToVitals(userId: _userId);
    _startRealtimeAlertMonitoring();
  }
  
  /// Start real-time alert monitoring (checks every 5 seconds)
  void _startRealtimeAlertMonitoring() {
    _alertCheckTimer?.cancel();
    _alertCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_currentVitals != null) {
        await _checkForAlertsRealtime(_currentVitals!);
      }
    });
  }
  
  /// Check for alerts in real-time with cooldown-based deduplication
  Future<void> _checkForAlertsRealtime(VitalSign vital) async {
    try {
      final profile = await _databaseService.getUserProfile(_userId);
      
      // Always check vitals - AlertEngine will handle deduplication
      final alerts = await _alertEngine.checkVitals(vital, profile);
      
      // Filter alerts based on cooldown (except emergencies which always pass)
      for (final alert in alerts) {
        final alertKey = '${alert.vitalType}_${alert.severity}';
        final lastTime = _lastAlertTimes[alertKey];
        
        // Emergency alerts always trigger, others respect cooldown
        if (alert.severity == 'EMERGENCY' || 
            lastTime == null || 
            DateTime.now().difference(lastTime) >= _alertCooldown) {
          _lastAlertTimes[alertKey] = DateTime.now();
          // Alert is already saved and broadcast by AlertEngine
        }
      }
    } catch (e) {
      debugPrint('Error in realtime alert check: $e');
    }
  }
  
  /// Subscribe to real-time vital sign updates from Bluetooth
  void subscribeToVitals({String userId = '1'}) {
    _vitalsSubscription = _bluetoothService.dataStream.listen(
      (vitalData) async {
        try {
          debugPrint('📥 VitalsProvider: Received sensor data - HR=${vitalData['heart_rate']}, accel_x=${vitalData['accel_x']}, accel_y=${vitalData['accel_y']}, accel_z=${vitalData['accel_z']}');
          
          // Process sensor data to calculate activity metrics
          _processSensorData(vitalData);
          
          // Convert streaming data to VitalSign
          final vital = VitalSign.fromJson(vitalData, userId);
          _currentVitals = vital;
          _addToRecentVitals(vital);
          
          // Save to database in background
          try {
            await _databaseService.insertVitalSign(vital);
          } catch (e) {
            debugPrint('Error saving vital sign: $e');
          }
          
          // Set activity type for context-aware alerts
          try {
            final activityState = vitalData['activity_state'] as String?;
            if (activityState != null) {
              _alertEngine.setActivityType(activityState.toUpperCase());
            }
          } catch (e) {
            debugPrint('Error setting activity state: $e');
          }
          
          // Update wellness metrics with calculated activity data
          try {
            await _updateWellnessMetrics(userId, vitalData);
          } catch (e) {
            debugPrint('Error updating wellness metrics: $e');
          }
          
          notifyListeners();
        } catch (e) {
          debugPrint('Error processing vital sign: $e');
        }
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }
  
  /// Process raw sensor data to calculate activity metrics
  void _processSensorData(Map<String, dynamic> data) {
    final now = DateTime.now();
    
    // Reset counters if it's a new day
    if (!_isSameDay(_todayDate, now)) {
      _stepsToday = 0;
      _caloriesToday = 0;
      _distanceKmToday = 0.0;
      _activeMinutesToday = 0;
      _todayDate = now;
    }
    
    // Extract sensor values
    final accelX = (data['accel_x'] as num?)?.toDouble() ?? 0.0;
    final accelY = (data['accel_y'] as num?)?.toDouble() ?? 9.8;
    final accelZ = (data['accel_z'] as num?)?.toDouble() ?? 0.0;
    final heartRate = data['heart_rate'] as int? ?? 70;
    
    // Calculate acceleration magnitude (subtract gravity)
    final accelMagnitude = math.sqrt(
      accelX * accelX + 
      (accelY - 9.8) * (accelY - 9.8) + 
      accelZ * accelZ
    );
    
    // Step detection algorithm (peak detection)
    if (accelMagnitude > _stepThreshold && !_isPeakDetected && _samplesSincePeak >= _minSamplesBetweenSteps) {
      _stepsToday++;
      _isPeakDetected = true;
      _samplesSincePeak = 0;
      debugPrint('👣 Step detected! Total steps: $_stepsToday (accelMag: ${accelMagnitude.toStringAsFixed(2)})');
    } else if (accelMagnitude < _stepThreshold) {
      _isPeakDetected = false;
    }
    _samplesSincePeak++;
    
    // Calculate distance (average step = 0.75m)
    _distanceKmToday = _stepsToday * 0.00075;
    
    // Calculate calories burned (every 5 seconds)
    final secondsSinceLastUpdate = now.difference(_lastSensorUpdate).inSeconds;
    if (secondsSinceLastUpdate >= 5) {
      // Base metabolic rate: ~1.2 cal/min at rest
      final baseCalPerSecond = 1.2 / 60;
      // Heart rate zone multiplier (higher HR = more calories)
      final hrZoneMultiplier = (heartRate / 70.0).clamp(0.8, 4.0);
      // Movement intensity multiplier
      final movementMultiplier = 1 + (accelMagnitude / 2.0).clamp(0.0, 2.0);
      
      final caloriesBurned = (baseCalPerSecond * hrZoneMultiplier * movementMultiplier * secondsSinceLastUpdate).round();
      _caloriesToday += caloriesBurned;
      
      debugPrint('🔥 Calories burned: +$caloriesBurned (total: $_caloriesToday) - HR: $heartRate, accel: ${accelMagnitude.toStringAsFixed(2)}');
      
      _lastSensorUpdate = now;
    }
    
    // Track active minutes (high movement or elevated heart rate)
    if (accelMagnitude > 1.0 || heartRate > 100) {
      final minutesSinceLastUpdate = now.difference(_lastSensorUpdate).inMinutes;
      if (minutesSinceLastUpdate >= 1) {
        _activeMinutesToday++;
      }
    }
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  /// Update wellness metrics from sensor data
  Future<void> _updateWellnessMetrics(String userId, Map<String, dynamic> data) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    debugPrint('📊 Updating wellness: steps=$_stepsToday, calories=$_caloriesToday, distance=${_distanceKmToday.toStringAsFixed(2)}');
    
    final metrics = WellnessMetrics(
      userId: userId,
      date: today,
      steps: _stepsToday,
      distanceKm: _distanceKmToday,
      activeMinutes: _activeMinutesToday,
      caloriesBurned: _caloriesToday,
      restingHR: data['heart_rate'] as int?,
      avgHR: data['heart_rate'] as int?,
      maxHR: data['heart_rate'] as int?,
      avgSpo2: data['spo2'] as int?,
      hrv: 45.0, // Mock HRV
      stressLevel: _getStressLevel(data['heart_rate'] as int?),
      wellnessScore: _calculateWellnessScore(data),
    );
    
    await _databaseService.insertOrUpdateWellnessMetrics(metrics);
    debugPrint('✅ Wellness metrics saved to database');
  }
  
  String _getStressLevel(int? heartRate) {
    if (heartRate == null) return 'Low';
    if (heartRate > 100) return 'High';
    if (heartRate > 80) return 'Medium';
    return 'Low';
  }
  
  int _calculateWellnessScore(Map<String, dynamic> data) {
    int score = 70;
    
    // Add points for good vitals
    final hr = data['heart_rate'] as int?;
    if (hr != null && hr >= 60 && hr <= 100) score += 10;
    
    final spo2 = data['spo2'] as int?;
    if (spo2 != null && spo2 >= 95) score += 10;
    
    // Add points for activity (use calculated steps)
    if (_stepsToday > 5000) score += 5;
    if (_stepsToday > 10000) score += 5;
    
    return score.clamp(0, 100);
  }
  
  /// Sync today's data to Firebase cloud (called at end of day or manually)
  Future<bool> syncTodayToCloud() async {
    try {
      debugPrint('🔄 Starting cloud sync for today\'s data');
      
      // Sync vitals data
      final vitalsSuccess = await _firebaseService.syncVitalsToCloud(
        userId: _userId,
      );
      
      // Sync activity/wellness data
      final activitySuccess = await _firebaseService.syncActivityToCloud(
        userId: _userId,
      );
      
      if (vitalsSuccess && activitySuccess) {
        debugPrint('✅ Successfully synced all data to cloud');
        return true;
      } else {
        debugPrint('⚠️  Partial sync completed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Cloud sync failed: $e');
      _error = 'Cloud sync failed: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Add vital to recent list (keep last 100)
  void _addToRecentVitals(VitalSign vital) {
    _recentVitals.insert(0, vital);
    if (_recentVitals.length > 100) {
      _recentVitals.removeLast();
    }
  }
  
  /// Load recent vitals from database (last 24 hours)
  Future<void> loadRecentVitals({String userId = '1'}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));
      
      _recentVitals = await _databaseService.getVitalSignsInRange(
        userId,
        yesterday.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
      
      if (_recentVitals.isNotEmpty) {
        _currentVitals = _recentVitals.first;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load recent vitals: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load historical vitals for charts
  Future<void> loadHistoricalVitals({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // First try to load from local database
      _historicalVitals = await _databaseService.getVitalSignsInRange(
        userId,
        startTime.millisecondsSinceEpoch,
        endTime.millisecondsSinceEpoch,
      );
      
      // If no data locally, try to fetch from Firebase cloud
      if (_historicalVitals.isEmpty) {
        final days = endTime.difference(startTime).inDays;
        debugPrint('📥 No local data, fetching from Firebase cloud (last $days days)');
        
        final cloudData = await _firebaseService.fetchHistoricalVitals(
          userId: userId,
          days: days,
        );
        
        if (cloudData.isNotEmpty) {
          debugPrint('✅ Fetched ${cloudData.length} days from cloud');
          // Convert cloud data to VitalSign objects (simplified - you'd need proper conversion)
          // For now, fall back to mock data as placeholder
          _historicalVitals = _generateMockHistoricalData(userId, startTime, endTime);
        } else {
          // Still no data from cloud, use mock data as fallback
          debugPrint('⚠️  No cloud data available, using mock data');
          _historicalVitals = _generateMockHistoricalData(userId, startTime, endTime);
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load historical vitals: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Generate mock historical data for demo purposes
  List<VitalSign> _generateMockHistoricalData(String userId, DateTime startTime, DateTime endTime) {
    final vitals = <VitalSign>[];
    final random = math.Random();
    final duration = endTime.difference(startTime);
    
    // Determine interval based on time range
    Duration interval;
    if (duration.inHours <= 24) {
      interval = const Duration(minutes: 15); // Every 15 minutes for 24h
    } else if (duration.inDays <= 7) {
      interval = const Duration(hours: 1); // Every hour for 7 days
    } else {
      interval = const Duration(hours: 4); // Every 4 hours for 30 days
    }
    
    DateTime currentTime = startTime;
    
    while (currentTime.isBefore(endTime)) {
      // Simulate daily patterns
      final hour = currentTime.hour;
      int baseHeartRate;
      int baseSpo2 = 98;
      double baseTemp = 36.5;
      
      // Sleep hours (22:00 - 06:00)
      if (hour >= 22 || hour < 6) {
        baseHeartRate = 55 + random.nextInt(10); // 55-65
        baseSpo2 = 96 + random.nextInt(3); // 96-98
        baseTemp = 36.2 + random.nextDouble() * 0.4; // 36.2-36.6
      }
      // Morning (06:00 - 09:00)
      else if (hour >= 6 && hour < 9) {
        baseHeartRate = 70 + random.nextInt(20); // 70-90
        baseSpo2 = 97 + random.nextInt(3); // 97-99
        baseTemp = 36.4 + random.nextDouble() * 0.6; // 36.4-37.0
      }
      // Lunch time (12:00 - 14:00)
      else if (hour >= 12 && hour < 14) {
        baseHeartRate = 75 + random.nextInt(15); // 75-90
        baseSpo2 = 97 + random.nextInt(3); // 97-99
        baseTemp = 36.6 + random.nextDouble() * 0.5; // 36.6-37.1
      }
      // Evening exercise (18:00 - 20:00)
      else if (hour >= 18 && hour < 20) {
        baseHeartRate = 100 + random.nextInt(40); // 100-140
        baseSpo2 = 95 + random.nextInt(4); // 95-98
        baseTemp = 36.8 + random.nextDouble() * 0.7; // 36.8-37.5
      }
      // Rest of day
      else {
        baseHeartRate = 70 + random.nextInt(20); // 70-90
        baseSpo2 = 97 + random.nextInt(3); // 97-99
        baseTemp = 36.5 + random.nextDouble() * 0.5; // 36.5-37.0
      }
      
      // Add some random variations and occasional spikes
      final hasSpike = random.nextInt(100) < 10; // 10% chance of spike
      if (hasSpike) {
        baseHeartRate += random.nextInt(30) + 20; // Spike by 20-50
        baseSpo2 = math.max(88, baseSpo2 - random.nextInt(5)); // Drop by 0-5
      }
      
      // Determine activity state for this time period
      String activityState;
      if (hour >= 22 || hour < 6) {
        activityState = 'sleeping';
      } else if (hour >= 7 && hour < 9) {
        activityState = 'walking'; // Morning walk
      } else if (hour >= 18 && hour < 20) {
        activityState = 'running'; // Evening exercise
      } else if (hour >= 12 && hour < 14) {
        activityState = 'walking'; // Lunch walk
      } else {
        activityState = 'resting';
      }
      
      final vital = VitalSign(
        userId: userId,
        timestamp: currentTime.millisecondsSinceEpoch,
        heartRate: baseHeartRate.clamp(45, 190),
        spo2: baseSpo2.clamp(85, 100),
        temperature: double.parse(baseTemp.toStringAsFixed(1)),
        activityState: activityState,
      );
      
      vitals.add(vital);
      currentTime = currentTime.add(interval);
    }
    
    return vitals;
  }
  
  /// Get average heart rate for a time period
  double getAverageHeartRate(List<VitalSign> vitals) {
    if (vitals.isEmpty) return 0.0;
    final sum = vitals.fold<double>(0, (prev, vital) => prev + (vital.heartRate?.toDouble() ?? 0));
    return sum / vitals.length;
  }
  
  /// Get average SpO2 for a time period
  double getAverageSpO2(List<VitalSign> vitals) {
    if (vitals.isEmpty) return 0.0;
    final sum = vitals.fold<double>(0, (prev, vital) => prev + (vital.spo2?.toDouble() ?? 0));
    return sum / vitals.length;
  }
  
  /// Get average temperature for a time period
  double getAverageTemperature(List<VitalSign> vitals) {
    if (vitals.isEmpty) return 0.0;
    final sum = vitals.fold<double>(0, (prev, vital) => prev + (vital.temperature ?? 0));
    return sum / vitals.length;
  }
  
  /// Get min/max values for a vital type
  Map<String, double> getMinMaxHeartRate(List<VitalSign> vitals) {
    if (vitals.isEmpty) return {'min': 0.0, 'max': 0.0};
    final values = vitals.map((v) => v.heartRate?.toDouble() ?? 0.0).where((v) => v > 0).toList();
    if (values.isEmpty) return {'min': 0.0, 'max': 0.0};
    return {
      'min': values.reduce((a, b) => a < b ? a : b),
      'max': values.reduce((a, b) => a > b ? a : b),
    };
  }
  
  Map<String, double> getMinMaxSpO2(List<VitalSign> vitals) {
    if (vitals.isEmpty) return {'min': 0.0, 'max': 0.0};
    final values = vitals.map((v) => v.spo2?.toDouble() ?? 0.0).where((v) => v > 0).toList();
    if (values.isEmpty) return {'min': 0.0, 'max': 0.0};
    return {
      'min': values.reduce((a, b) => a < b ? a : b),
      'max': values.reduce((a, b) => a > b ? a : b),
    };
  }
  
  Map<String, double> getMinMaxTemperature(List<VitalSign> vitals) {
    if (vitals.isEmpty) return {'min': 0.0, 'max': 0.0};
    final values = vitals.map((v) => v.temperature ?? 0.0).where((v) => v > 0).toList();
    if (values.isEmpty) return {'min': 0.0, 'max': 0.0};
    return {
      'min': values.reduce((a, b) => a < b ? a : b),
      'max': values.reduce((a, b) => a > b ? a : b),
    };
  }
  
  /// Get vitals grouped by hour (for charts)
  Map<int, List<VitalSign>> groupVitalsByHour(List<VitalSign> vitals) {
    final grouped = <int, List<VitalSign>>{};
    for (var vital in vitals) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(vital.timestamp);
      final hour = dateTime.hour;
      grouped.putIfAbsent(hour, () => []).add(vital);
    }
    return grouped;
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _vitalsSubscription?.cancel();
    _alertCheckTimer?.cancel();
    super.dispose();
  }
}
