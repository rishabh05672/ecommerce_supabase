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
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Insert user into users table
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'role': 'admin',
        });

        _user = response.user;
        await _saveUserSession();
        notifyListeners();
        return true;
      }

      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isLoggedInKey, true);
    if (_user != null) {
      await prefs.setString(AppConstants.userIdKey, _user!.id);
      await prefs.setString(AppConstants.userEmailKey, _user!.email ?? '');
    }
  }

  Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.isLoggedInKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userEmailKey);
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
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
