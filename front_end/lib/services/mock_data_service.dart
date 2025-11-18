import 'dart:async';
import 'dart:math';

class MockDataService {
  final Random _random = Random();
  Timer? _timer;
  StreamController<Map<String, dynamic>>? _controller;

  // Activity states for realistic simulation
  String _activityState = 'resting'; // resting, walking, running
  int _baseHeartRate = 70;
  double _baseTemperature = 36.5;
  int _baseSpo2 = 98;
  
  // Alert triggering scenarios (cycles through different conditions more frequently)
  int _dataPointCount = 0;
  String _currentScenario = 'normal'; // normal, high_hr, low_spo2, fever, emergency, bradycardia, tachycardia
  int _scenarioDuration = 0; // How many data points to maintain current scenario

  // Start generating mock data with realistic variations
  Stream<Map<String, dynamic>> startGeneratingData({Duration interval = const Duration(seconds: 5)}) {
    stop(); // Stop any existing stream

    _controller = StreamController<Map<String, dynamic>>.broadcast();
    
    // Send initial data immediately
    _controller!.add(_generateRealisticData());
    
    _timer = Timer.periodic(interval, (_) {
      final data = _generateRealisticData();
      _controller!.add(data);
    });

    return _controller!.stream;
  }

  // Generate realistic sensor data with variations
  Map<String, dynamic> _generateRealisticData() {
    final now = DateTime.now();
    _dataPointCount++;
    
    // Cycle through alert scenarios (every 6-12 data points = 30-60 seconds at 5s interval)
    // More alert scenarios with varying durations
    if (_scenarioDuration <= 0) {
      final scenarios = [
        'normal', 'normal', // 2x normal
        'high_hr', 'very_high_hr', // High heart rate variations
        'low_spo2', 'very_low_spo2', // Low oxygen variations
        'fever', 'high_fever', // Temperature variations
        'bradycardia', // Low heart rate
        'tachycardia', // Very high heart rate during rest
        'emergency', // Multiple critical values
      ];
      _currentScenario = scenarios[_random.nextInt(scenarios.length)];
      _scenarioDuration = 6 + _random.nextInt(6); // Maintain scenario for 6-12 data points (30-60 seconds)
    }
    _scenarioDuration--;

    // 24/7 activity cycle: 60 seconds walking -> 40 seconds running (repeating)
    final cyclePosition = _dataPointCount % 20; // 20 data points = 100 seconds cycle
    
    if (cyclePosition < 12) {
      // 60 seconds walking (12 data points * 5s = 60s)
      _activityState = 'walking';
      _baseHeartRate = 95;
      _baseSpo2 = 98;
    } else {
      // 40 seconds running (8 data points * 5s = 40s)
      _activityState = 'running';
      _baseHeartRate = 140;
      _baseSpo2 = 96;
    }

    // Apply alert scenarios
    int heartRate = _baseHeartRate + _random.nextInt(10) - 5;
    int spo2 = _baseSpo2 + _random.nextInt(3) - 1;
    double temperature = _baseTemperature + (_random.nextDouble() * 0.4 - 0.2);
    
    switch (_currentScenario) {
      case 'high_hr':
        heartRate = 155 + _random.nextInt(15); // Warning/Critical high HR (155-170)
        break;
      case 'very_high_hr':
        heartRate = 175 + _random.nextInt(15); // Critical/Emergency high HR (175-190)
        break;
      case 'low_spo2':
        spo2 = 90 + _random.nextInt(3); // Warning low SpO2 (90-92)
        break;
      case 'very_low_spo2':
        spo2 = 85 + _random.nextInt(4); // Critical low SpO2 (85-88)
        break;
      case 'fever':
        temperature = 37.8 + _random.nextDouble() * 0.7; // Mild fever (37.8-38.5)
        break;
      case 'high_fever':
        temperature = 38.6 + _random.nextDouble() * 0.8; // High fever (38.6-39.4)
        break;
      case 'bradycardia':
        if (_activityState == 'resting' || _activityState == 'sleeping') {
          heartRate = 45 + _random.nextInt(5); // Low HR when resting (45-50)
        } else {
          heartRate = 50 + _random.nextInt(5); // Slightly low HR
        }
        break;
      case 'tachycardia':
        if (_activityState == 'resting') {
          heartRate = 115 + _random.nextInt(15); // High resting HR (115-130)
        } else {
          heartRate = _baseHeartRate + 10; // Normal during activity
        }
        break;
      case 'emergency':
        heartRate = 195 + _random.nextInt(20); // Emergency HR (195-215)
        spo2 = 82 + _random.nextInt(4); // Emergency SpO2 (82-85)
        temperature = 39.0 + _random.nextDouble() * 0.8; // High fever too
        break;
      default:
        // Normal variations
        break;
    }
    
    // Accelerometer data (simulates movement)
    double accelMagnitude = 0.5;
    if (_activityState == 'walking') accelMagnitude = 2.0;
    if (_activityState == 'running') accelMagnitude = 5.0;
    if (_activityState == 'resting') accelMagnitude = 0.3;

    // Gyroscope data (angular velocity)
    double gyroMagnitude = 0.5;
    if (_activityState == 'walking') gyroMagnitude = 1.5;
    if (_activityState == 'running') gyroMagnitude = 3.0;
    if (_activityState == 'resting') gyroMagnitude = 0.2;
    
    // Generate sensor values with realistic noise
    final accelX = (_random.nextDouble() * 2 - 1) * accelMagnitude;
    final accelY = (_random.nextDouble() * 2 - 1) * accelMagnitude + 9.8; // Gravity
    final accelZ = (_random.nextDouble() * 2 - 1) * accelMagnitude;
    final gyroX = (_random.nextDouble() * 2 - 1) * gyroMagnitude;
    final gyroY = (_random.nextDouble() * 2 - 1) * gyroMagnitude;
    final gyroZ = (_random.nextDouble() * 2 - 1) * gyroMagnitude;

    return {
      // Raw vital signs
      'heart_rate': heartRate.clamp(40, 220),
      'spo2': spo2.clamp(80, 100),
      'temperature': double.parse(temperature.toStringAsFixed(1)),
      
      // Raw motion sensors (m/s² for accel, rad/s for gyro)
      'accel_x': double.parse(accelX.toStringAsFixed(3)),
      'accel_y': double.parse(accelY.toStringAsFixed(3)),
      'accel_z': double.parse(accelZ.toStringAsFixed(3)),
      'gyro_x': double.parse(gyroX.toStringAsFixed(3)),
      'gyro_y': double.parse(gyroY.toStringAsFixed(3)),
      'gyro_z': double.parse(gyroZ.toStringAsFixed(3)),
      
      // Metadata
      'timestamp': now.millisecondsSinceEpoch ~/ 1000,
      'battery': 75 + _random.nextInt(25),
      'activity_state': _activityState, // For demo/debugging only
      'current_scenario': _currentScenario, // For alert testing
    };
  }

  // Simulate specific scenarios for testing
  Map<String, dynamic> generateCriticalHeartRate() {
    return {
      'heart_rate': 185,
      'spo2': 97,
      'temperature': 36.8,
      'accel_x': 3.2,
      'accel_y': 10.5,
      'accel_z': 0.8,
      'gyro_x': 2.5,
      'gyro_y': -1.2,
      'gyro_z': 1.8,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'battery': 80,
    };
  }

  Map<String, dynamic> generateLowSpO2() {
    return {
      'heart_rate': 95,
      'spo2': 88,
      'temperature': 36.5,
      'accel_x': 0.5,
      'accel_y': 9.8,
      'accel_z': 0.2,
      'gyro_x': 0.3,
      'gyro_y': -0.2,
      'gyro_z': 0.4,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'battery': 65,
    };
  }

  Map<String, dynamic> generateHighFever() {
    return {
      'heart_rate': 98,
      'spo2': 97,
      'temperature': 38.9,
      'accel_x': 0.3,
      'accel_y': 9.9,
      'accel_z': 0.1,
      'gyro_x': 0.2,
      'gyro_y': -0.1,
      'gyro_z': 0.2,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'battery': 70,
    };
  }

  Map<String, dynamic> generateEmergencyHR() {
    return {
      'heart_rate': 205,
      'spo2': 95,
      'temperature': 37.2,
      'accel_x': 5.5,
      'accel_y': 12.0,
      'accel_z': 1.5,
      'gyro_x': 4.0,
      'gyro_y': -2.5,
      'gyro_z': 3.2,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'battery': 55,
    };
  }

  // Generate historical data for charts
  List<Map<String, dynamic>> generateHistoricalData({
    required int hours,
    required int intervalMinutes,
  }) {
    final data = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final totalPoints = (hours * 60) ~/ intervalMinutes;

    for (int i = totalPoints; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: i * intervalMinutes));
      
      // Simulate daily patterns
      int hr = 70;
      if (timestamp.hour >= 22 || timestamp.hour < 6) {
        hr = 55 + _random.nextInt(10); // Sleeping
      } else if (timestamp.hour >= 7 && timestamp.hour < 9) {
        hr = 85 + _random.nextInt(15); // Morning activity
      } else if (timestamp.hour >= 12 && timestamp.hour < 13) {
        hr = 80 + _random.nextInt(10); // Lunch
      } else if (timestamp.hour >= 18 && timestamp.hour < 20) {
        hr = 95 + _random.nextInt(20); // Evening exercise
      } else {
        hr = 70 + _random.nextInt(15); // Rest of day
      }

      data.add({
        'heart_rate': hr,
        'spo2': 96 + _random.nextInt(4),
        'temperature': 36.2 + _random.nextDouble() * 1.0,
        'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
        'battery': 100 - (totalPoints - i) * 2, // Simulated battery drain
      });
    }

    return data;
  }

  // Generate daily activity data
  Map<String, dynamic> generateDailyActivity() {
    return {
      'steps': 6000 + _random.nextInt(4000),
      'distance_km': 4.0 + _random.nextDouble() * 4.0,
      'calories_burned': 1200 + _random.nextInt(800),
      'active_minutes': 45 + _random.nextInt(60),
      'floors_climbed': 5 + _random.nextInt(10),
      'resting_hr': 60 + _random.nextInt(15),
      'avg_hr': 75 + _random.nextInt(15),
      'max_hr': 140 + _random.nextInt(30),
      'hrv': 40.0 + _random.nextDouble() * 40.0,
      'stress_level': _random.nextBool() ? 'Low' : 'Medium',
      'wellness_score': 70 + _random.nextInt(25),
    };
  }

  // Stop generating data
  void stop() {
    _timer?.cancel();
    _controller?.close();
    _timer = null;
    _controller = null;
  }

  void dispose() {
    stop();
  }
}
