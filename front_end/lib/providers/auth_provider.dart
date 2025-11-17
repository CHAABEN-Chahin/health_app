import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  UserProfile? _userProfile;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _currentUser?.id;
  
  AuthProvider() {
    _checkAutoLogin();
  }
  
  /// Check if user is already logged in (auto-login)
  Future<void> _checkAutoLogin() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final isLoggedIn = await _authService.initialize();
      if (isLoggedIn) {
        _currentUser = _authService.currentUser;
        _isAuthenticated = true;
        
        // Try to load profile
        try {
          await _loadUserProfile();
        } catch (e) {
          debugPrint('Profile not loaded: $e');
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Auto-login failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Login with username/email and password
  Future<bool> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _authService.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      
      if (result.success) {
        _currentUser = result.user;
        _isAuthenticated = true;
        
        // Load user profile from API
        try {
          await _loadUserProfile();
        } catch (e) {
          debugPrint('Profile not loaded: $e');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _authService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );
      
      if (result.success) {
        // Refresh to get current user data
        await _authService.refreshCurrentUser();
        _currentUser = _authService.currentUser;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Load user profile from API
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _apiService.getMyProfile();
      _userProfile = UserProfile.fromMap(profile);
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      rethrow;
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _apiService.updateMyProfile(profile.toMap());
      _userProfile = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Update failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Create user profile (after registration/onboarding)
  Future<bool> createProfile({
    required int age,
    required String gender,
    required double weightKg,
    required double heightCm,
    String? medicalConditions,
    String? allergies,
    String? medications,
    String? fitnessGoals,
  }) async {
    print(_currentUser);
    if (_currentUser == null) return false;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final profile = UserProfile(
        userId: _currentUser!.id,
        age: age,
        gender: gender,
        weightKg: weightKg,
        heightCm: heightCm,
        medicalConditions: medicalConditions,
        allergies: allergies,
        medications: medications,
        fitnessGoals: fitnessGoals,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      await _apiService.updateMyProfile(profile.toMap());
      
      _userProfile = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Profile creation failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _authService.changePassword(
        currentPassword: oldPassword,
        newPassword: newPassword,
      );
      
      if (result.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Password change failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _currentUser = null;
      _userProfile = null;
      _isAuthenticated = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Logout failed: $e';
      notifyListeners();
    }
  }
  
  /// Delete account
  Future<bool> deleteAccount(String password) async {
    if (_currentUser == null) return false;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _authService.deleteAccount(password);
      
      if (result.success) {
        _currentUser = null;
        _userProfile = null;
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Account deletion failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
