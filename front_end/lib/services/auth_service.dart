import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../core/constants/constants.dart';
import 'api_service.dart';

class AuthService {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  firebase.User? _firebaseUser;
  String? _currentUserId;
  User? _currentUser;

  User? get currentUser => _currentUser;
  String? get currentUserId => _currentUserId;
  bool get isAuthenticated => _firebaseUser != null;

  // Initialize auth service - check if user is already logged in
  Future<bool> initialize() async {
    try {
      _firebaseUser = _firebaseAuth.currentUser;
      
      if (_firebaseUser != null) {
        _currentUserId = _firebaseUser!.uid;
        
        // Try to load user profile from backend
        try {
          final profile = await _apiService.getMyProfile();
          _currentUser = User.fromMap(profile);
          return true;
        } catch (e) {
          print('Failed to load profile: $e');
          // User might not have completed profile setup yet
          return true;
        }
      }
    } catch (e) {
      print('Auth initialization error: $e');
    }
    return false;
  }

  // Register new user with Firebase + Backend
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      // Step 1: Create Firebase user (Firebase handles password securely)
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _firebaseUser = userCredential.user;
      
      if (_firebaseUser == null) {
        return AuthResult(
          success: false,
          message: 'Failed to create Firebase account',
        );
      }

      // Step 2: Get Firebase ID token to authenticate with backend
      final idToken = await _firebaseUser!.getIdToken();
      
      if (idToken == null) {
        await _firebaseUser!.delete();
        return AuthResult(
          success: false,
          message: 'Failed to get authentication token',
        );
      }
      
      // Step 3: Register with backend API (sends ID token, NOT password)
      try {
        final response = await _apiService.signup(
          firebaseIdToken: idToken,
          username: username,
          fullName: fullName ?? username,
        );
        
        _currentUserId = _firebaseUser!.uid;
        
        // Update Firebase display name
        await _firebaseUser!.updateDisplayName(fullName ?? username);
        
        return AuthResult(
          success: true,
          message: 'Registration successful',
          userId: _currentUserId,
        );
      } catch (e) {
        // Backend registration failed, delete Firebase user
        await _firebaseUser!.delete();
        return AuthResult(
          success: false,
          message: 'Backend registration failed: ${e.toString()}',
        );
      }
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  // Login user with Firebase + Backend
  Future<AuthResult> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      // Step 1: Login with Firebase (Firebase verifies password securely)
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: usernameOrEmail,
        password: password,
      );
      
      _firebaseUser = userCredential.user;
      
      if (_firebaseUser == null) {
        return AuthResult(
          success: false,
          message: 'Login failed',
        );
      }

      // Step 2: Get Firebase ID token to authenticate with backend
      final idToken = await _firebaseUser!.getIdToken();
      
      if (idToken == null) {
        return AuthResult(
          success: false,
          message: 'Failed to get authentication token',
        );
      }
      
      // Step 3: Login to backend (sends ID token, NOT password)
      try {
        await _apiService.login(idToken);
        
        _currentUserId = _firebaseUser!.uid;
        
        // Load user profile from backend
        final profile = await _apiService.getMyProfile();
        _currentUser = User.fromMap(profile);
        
        // Store credentials
        await _secureStorage.write(key: AppConstants.keyUserId, value: _currentUserId);
        await _secureStorage.write(key: AppConstants.keyUsername, value: _currentUser?.username ?? '');

        return AuthResult(
          success: true,
          message: 'Login successful',
          userId: _currentUserId,
          user: _currentUser,
        );
      } catch (e) {
        return AuthResult(
          success: false,
          message: 'Backend login failed: ${e.toString()}',
        );
      }
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Logout user from Firebase + Backend
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _apiService.logout();
      await _secureStorage.delete(key: AppConstants.keyUserId);
      await _secureStorage.delete(key: AppConstants.keyUsername);
      await _secureStorage.delete(key: AppConstants.keyAuthToken);
      
      _firebaseUser = null;
      _currentUserId = null;
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Change password in Firebase
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_firebaseUser == null) {
      return AuthResult(success: false, message: 'Not authenticated');
    }

    try {
      // Re-authenticate before changing password
      final email = _firebaseUser!.email;
      if (email == null) {
        return AuthResult(success: false, message: 'Email not found');
      }

      final credential = firebase.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      await _firebaseUser!.reauthenticateWithCredential(credential);
      await _firebaseUser!.updatePassword(newPassword);

      return AuthResult(success: true, message: 'Password changed successfully');
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Password change failed: ${e.toString()}',
      );
    }
  }

  // Delete account from Firebase
  Future<AuthResult> deleteAccount(String password) async {
    if (_firebaseUser == null) {
      return AuthResult(success: false, message: 'Not authenticated');
    }

    try {
      // Re-authenticate before deleting
      final email = _firebaseUser!.email;
      if (email == null) {
        return AuthResult(success: false, message: 'Email not found');
      }

      final credential = firebase.EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      await _firebaseUser!.reauthenticateWithCredential(credential);
      
      // Delete from Firebase
      await _firebaseUser!.delete();
      
      // Logout to clear all data
      await logout();

      return AuthResult(success: true, message: 'Account deleted');
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Account deletion failed: ${e.toString()}',
      );
    }
  }

  // Refresh current user profile from backend
  Future<User?> refreshCurrentUser() async {
    if (_firebaseUser == null) return null;
    
    try {
      final profile = await _apiService.getMyProfile();
      _currentUser = User.fromMap(profile);
      return _currentUser;
    } catch (e) {
      print('Refresh user error: $e');
      return null;
    }
  }

  // Send password reset email
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        message: 'Password reset email sent',
      );
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e),
      );
    }
  }

  // Get Firebase error message
  String _getFirebaseErrorMessage(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
      print('FirebaseAuthException: ${e.code} - ${e.message}');
        return 'Authentication error: ${e.message}';
    }
  }
}

class AuthResult {
  final bool success;
  final String message;
  final String? userId;
  final User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.userId,
    this.user,
  });
}
