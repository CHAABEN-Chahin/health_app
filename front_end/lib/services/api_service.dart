import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://5aeefcb0eff3.ngrok-free.app/api/v1';
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  
  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid - logout user
          await logout();
        }
        return handler.next(error);
      },
    ));
  }
  
  // ==================== AUTHENTICATION ====================
  
  Future<Map<String, dynamic>> signup({
    required String firebaseIdToken,
    required String username,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post('/auth/signup', data: {
        'firebase_id_token': firebaseIdToken,
        'username': username,
        'full_name': fullName,
      });
      
      final data = response.data;
      await _storage.write(key: 'access_token', value: data['access_token']);
      await _storage.write(key: 'user_id', value: data['user_id']);
      
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> login(String firebaseIdToken) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'firebase_id_token': firebaseIdToken,
      });
      
      final data = response.data;
      await _storage.write(key: 'access_token', value: data['access_token']);
      await _storage.write(key: 'user_id', value: data['user_id']);
      
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'user_id');
  }
  
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }
  
  // ==================== USER PROFILE ====================
  
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _dio.get('/users/me/profile');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> updateMyProfile(Map<String, dynamic> profileData) async {
    try {
      print(profileData);
      await _dio.put('/users/me/profile', data: profileData);
    } on DioException catch (e) {
      print(e.message);
      throw _handleError(e);
    }
  }
  
  // ==================== VITALS ====================
  
  Future<void> syncDailyVitals({
    required String date,
    required List<Map<String, dynamic>> readings,
    required Map<String, dynamic> summary,
  }) async {
    try {
      await _dio.post('/vitals/sync', data: {
        'date': date,
        'readings': readings,
        'summary': summary,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getHistoricalVitals(int days) async {
    try {
      final response = await _dio.get('/vitals/historical', queryParameters: {
        'days': days,
      });
      
      return List<Map<String, dynamic>>.from(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>?> getVitalsByDate(String date) async {
    try {
      final response = await _dio.get('/vitals/date/$date');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    }
  }
  
  // ==================== ACTIVITIES ====================
  
  Future<void> syncDailyActivity({
    required String date,
    required int steps,
    required double distanceKm,
    required int activeMinutes,
    required int caloriesBurned,
    List<Map<String, dynamic>>? hourlyBreakdown,
  }) async {
    try {
      await _dio.post('/activities/sync', data: {
        'date': date,
        'steps': steps,
        'distance_km': distanceKm,
        'active_minutes': activeMinutes,
        'calories_burned': caloriesBurned,
        'hourly_breakdown': hourlyBreakdown ?? [],
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getHistoricalActivity(int days) async {
    try {
      final response = await _dio.get('/activities/historical', queryParameters: {
        'days': days,
      });
      
      return List<Map<String, dynamic>>.from(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== SESSIONS ====================
  
  Future<String> createSession(Map<String, dynamic> sessionData) async {
    try {
      final response = await _dio.post('/sessions', data: sessionData);
      return response.data['data']['session_id'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getSessions({int days = 30, int limit = 50}) async {
    try {
      final response = await _dio.get('/sessions', queryParameters: {
        'days': days,
        'limit': limit,
      });
      
      return List<Map<String, dynamic>>.from(response.data['sessions']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== ALERTS ====================
  
  Future<String> createAlert(Map<String, dynamic> alertData) async {
    try {
      final response = await _dio.post('/alerts', data: alertData);
      return response.data['data']['alert_id'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getAlerts({int days = 7, int limit = 50}) async {
    try {
      final response = await _dio.get('/alerts', queryParameters: {
        'days': days,
        'limit': limit,
      });
      
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _dio.post('/alerts/$alertId/acknowledge');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== NUTRITION ====================
  
  Future<String> logNutrition(Map<String, dynamic> nutritionData) async {
    try {
      final response = await _dio.post('/nutrition', data: nutritionData);
      return response.data['data']['entry_id'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getNutritionEntries({int days = 30}) async {
    try {
      final response = await _dio.get('/nutrition', queryParameters: {
        'days': days,
      });
      
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== ERROR HANDLING ====================
  
  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      } else if (data is Map && data.containsKey('error')) {
        return data['error'].toString();
      }
      return 'Request failed: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server response timeout. Please try again.';
    } else {
      return 'Network error: ${e.message}';
    }
  }
}
