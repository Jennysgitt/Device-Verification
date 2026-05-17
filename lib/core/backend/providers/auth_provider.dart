import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lightmode/core/backend/models/user_model.dart';
import 'package:lightmode/core/backend/services/auth_service.dart';

import '../models/device_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  UserModel? _currentUser;
  List<DeviceModel> _devices = [];
  bool _isLoading = true;
  bool _isInitialized = false;

  AuthProvider(this._authService) {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  List<DeviceModel> get devices => _devices;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isInitialized && _currentUser != null;

  void _init() {
    _authService.authStateChanges.listen((AuthState state) async {
      if (state.session?.user != null) {
        await _loadUser();
      } else {
        _currentUser = null;
        _devices = [];
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
      }
    });

    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.getCurrentUserProfile();
      _currentUser = user;
      
      if (user != null) {
        _devices = await _authService.getDevices(userId: user.id);
      } else {
        _devices = [];
      }
    } catch (e) {
      _currentUser = null;
      _devices = [];
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadUser() async {
    await _loadUser();
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithEmail(email, password);
      _currentUser = user;
      
      if (user != null) {
        _devices = await _authService.getDevices(userId: user.id);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithStudentId(String studentId, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithStudentId(studentId, password);
      _currentUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      _currentUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithStudentId({
    required String studentId,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signUpWithStudentId(
        studentId: studentId,
        password: password,
        fullName: fullName,
        role: role,
      );
      _currentUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _devices = [];
    notifyListeners();
  }

  String getRedirectPath() {
    return _authService.getRedirectPathByRole(_currentUser?.role);
  }
}

