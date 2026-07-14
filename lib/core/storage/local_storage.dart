import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/jobseeker_model.dart';
import '../../models/recruiter_model.dart';
import '../../models/user_model.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token storage
  Future<void> setToken(String token) async {
    print('LocalStorage: Setting token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    await _secureStorage.write(key: 'access_token', value: token);
    // Also mirror to prefs as fallback
    await _prefs?.setString('access_token_backup', token);
    print('LocalStorage: Token set successfully');
  }

  Future<String?> getToken() async {
    final token = await _secureStorage.read(key: 'access_token');
    print('LocalStorage: Token from secure storage: ${token != null ? "exists" : "null"}');
    if (token != null && token.isNotEmpty) {
      print('LocalStorage: Returning token from secure storage');
      return token;
    }
    // Fallback to prefs mirror if secure storage fails
    final backupToken = _prefs?.getString('access_token_backup');
    print('LocalStorage: Token from backup prefs: ${backupToken != null ? "exists" : "null"}');
    return backupToken;
  }

  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: 'refresh_token', value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  // User type storage
  Future<void> setUserType(String userType) async {
    await _prefs?.setString('user_type', userType);
    // Mirror to secure storage as fallback
    await _secureStorage.write(key: 'user_type', value: userType);
  }

  String? getUserType() {
    return _prefs?.getString('user_type');
  }

  Future<String?> getUserTypeAsync() async {
    final fromPrefs = _prefs?.getString('user_type');
    if (fromPrefs != null) return fromPrefs;
    print(
      'Getting userType from local storage:${await _secureStorage.read(key: 'user_type')}',
    );
    return await _secureStorage.read(key: 'user_type');
  }

  // Jobseeker storage
  Future<void> setJobseeker(JobseekerModel jobseeker) async {
    await _prefs?.setString('jobseeker_data', jsonEncode(jobseeker.toJson()));
  }

  JobseekerModel? getJobseeker() {
    final jsonString = _prefs?.getString('jobseeker_data');
    if (jsonString == null) return null;

    try {
      final jsonData = jsonDecode(jsonString);
      return JobseekerModel.fromJson(jsonData);
    } catch (e) {
      print('Error decoding jobseeker data: $e');
      return null;
    }
  }

  // Recruiter storage
  Future<void> setRecruiter(RecruiterModel recruiter) async {
    await _prefs?.setString('recruiter_data', jsonEncode(recruiter.toJson()));
  }

  RecruiterModel? getRecruiter() {
    final jsonString = _prefs?.getString('recruiter_data');
    if (jsonString == null) return null;

    try {
      final jsonData = jsonDecode(jsonString);
      return RecruiterModel.fromJson(jsonData);
    } catch (e) {
      print('Error decoding recruiter data: $e');
      return null;
    }
  }

  // Admin user storage
  Future<void> setAdminUser(UserModel adminUser) async {
    await _prefs?.setString('admin_user_data', jsonEncode(adminUser.toJson()));
  }

  UserModel? getAdminUser() {
    final jsonString = _prefs?.getString('admin_user_data');
    if (jsonString == null) return null;

    try {
      final jsonData = jsonDecode(jsonString);
      return UserModel.fromJson(jsonData);
    } catch (e) {
      print('Error decoding admin user data: $e');
      return null;
    }
  }

  // Clear all auth data
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_type');
    await _prefs?.remove('user_type');
    await _prefs?.remove('access_token_backup');
    await _prefs?.remove('jobseeker_data');
    await _prefs?.remove('recruiter_data');
    await _prefs?.remove('admin_user_data');
  }
}