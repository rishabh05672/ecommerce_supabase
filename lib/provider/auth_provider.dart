import 'package:ecommerce_supabse/utils/constants/supabase_key.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  User? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _user = session.user;
        notifyListeners();
      }
    } catch (e) {
      print('Error initializing auth: $e');
    }
  }

  // Admin Sign Up with role
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
    String role = 'admin', // Default admin role
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Step 1: Create user with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        // Step 2: Insert admin data into users table
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'role': role, // Set admin role
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          print('Admin user inserted successfully');
        } catch (insertError) {
          print('Error inserting admin data: $insertError');
          // Continue even if insert fails
        }

        _user = response.user;
        await _saveUserSession();
        notifyListeners();
        return true;
      }

      _setError('Failed to create account');
      return false;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Registration failed. Please try again.');
      print('Signup error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Admin Sign In
  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        await _saveUserSession();
        notifyListeners();
        return true;
      }

      return false;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Login failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      await _clearUserSession();
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> _saveUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      if (_user != null) {
        await prefs.setString(AppConstants.userIdKey, _user!.id);
        await prefs.setString(AppConstants.userEmailKey, _user!.email ?? '');
      }
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.isLoggedInKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userEmailKey);
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  String _getErrorMessage(String? error) {
    if (error == null) return 'An unexpected error occurred';

    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('User already registered')) {
      return 'Account already exists with this email';
    } else if (error.contains('Password should be at least')) {
      return 'Password should be at least 6 characters';
    } else if (error.contains('Unable to validate email address')) {
      return 'Please enter a valid email address';
    }

    return error;
  }
}
