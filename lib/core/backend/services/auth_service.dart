import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/device_model.dart';
import 'storage_service.dart';
import 'supabase_service.dart';
import 'package:lightmode/core/backend/models/user_model.dart';

class AuthService {
  final SupabaseService _supabaseService;
  final _storage = StorageService.instance;
  final _supabase = Supabase.instance.client;
  
  SupabaseService get supabaseService => _supabaseService;

  AuthService(this._supabaseService);

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      if (response.session?.accessToken != null) {
        await _storage.setString('auth_token', response.session!.accessToken);
      }

      final userModel = UserModel.fromJson(userProfile);
      await _supabaseService.logActivity(
        activityType: 'login_success',
        officerId: userModel.id,
      );

      return userModel;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  Future<UserModel?> signInWithStudentId(String studentId, String password) async {
    try {
      final user = await _supabaseService.getUserByStudentId(studentId);
      if (user == null) {
        throw Exception('Student ID not found');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: user.email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      if (response.session?.accessToken != null) {
        await _storage.setString('auth_token', response.session!.accessToken);
      }

      return UserModel.fromJson(userProfile);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign in with student ID: ${e.toString()}');
    }
  }

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user == null) {
        throw Exception('Signup failed. Please try again.');
      }

      final userProfile = await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email.trim().toLowerCase(),
        'full_name': fullName,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      if (response.session?.accessToken != null) {
        await _storage.setString('auth_token', response.session!.accessToken);
      }

      final userModel = UserModel.fromJson(userProfile);
      await _supabaseService.logActivity(
        activityType: 'signup_success',
        officerId: userModel.id,
      );

      return userModel;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  Future<UserModel?> signUpWithStudentId({
    required String studentId,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    try {
      final existingUser = await _supabaseService.getUserByStudentId(studentId);
      if (existingUser == null) {
        throw Exception('Student ID not found in system');
      }

      final email = existingUser.email;
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user == null) {
        throw Exception('Signup failed. This student ID may already be registered.');
      }

      await _supabase.from('users').update({
        'full_name': fullName,
        'role': role,
      }).eq('id', response.user!.id);

      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      if (response.session?.accessToken != null) {
        await _storage.setString('auth_token', response.session!.accessToken);
      }

      return UserModel.fromJson(userProfile);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign up with student ID: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
    }
    
    await _storage.remove('auth_token');
    await _storage.remove('user_data');
  }

  Future<List<DeviceModel>> getDevices({String? userId}) async {
    return await _supabaseService.getDevices(userId: userId);
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      
      if (currentUser == null) {
        return null;
      }

      final userProfile = await _supabase
          .from('users')
          .select('*, student_ids(student_id)')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userProfile == null) {
        return null;
      }

      return UserModel.fromJson(userProfile);
    } catch (e) {
      return null;
    }
  }

  String getRedirectPathByRole(String? role) {
    switch (role) {
      case 'student':
      case 'staff':
        return '/student';
      case 'officer':
        return '/officer';
      case 'admin':
        return '/admin';
      default:
        return '/login';
    }
  }
}
