import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _userKey = 'user_id';
  static const _usernameKey = 'username';
  static const _emailKey = 'email';
  static const _phoneKey = 'phone';
  static const _avatarKey = 'avatar_path';

  static String? _currentUserId;
  static String? _currentUsername;
  static String? _currentEmail;
  static String? _currentPhone;
  static String? _currentAvatarPath;

  static String? get currentUserId => _currentUserId;
  static String? get currentUsername => _currentUsername;
  static String? get currentEmail => _currentEmail;
  static String? get currentPhone => _currentPhone;
  static String? get currentAvatarPath => _currentAvatarPath;

  /// Get current user as User object
  static User? get currentUser {
    if (_currentUserId == null) return null;
    return User(
      id: _currentUserId,
      username: _currentUsername ?? '',
      email: _currentEmail ?? '',
      phone: _currentPhone,
      avatarPath: _currentAvatarPath,
    );
  }

  /// Check if user is logged in by reading from secure storage
  static Future<bool> isLoggedIn() async {
    _currentUserId = await _storage.read(key: _userKey);
    _currentUsername = await _storage.read(key: _usernameKey);
    _currentEmail = await _storage.read(key: _emailKey);
    _currentPhone = await _storage.read(key: _phoneKey);
    _currentAvatarPath = await _storage.read(key: _avatarKey);
    return _currentUserId != null;
  }

  /// Mock login
  static Future<bool> login(String email, String password) async {
    // Mock validation
    if (email.contains('@') && password.length >= 6) {
      _currentUserId = 'mock_user_${DateTime.now().millisecondsSinceEpoch}';
      _currentUsername = email.split('@')[0];
      _currentEmail = email;

      await _storage.write(key: _userKey, value: _currentUserId);
      await _storage.write(key: _usernameKey, value: _currentUsername);
      await _storage.write(key: _emailKey, value: _currentEmail);
      return true;
    }
    return false;
  }

  /// Mock register
  static Future<bool> register(String email, String password) async {
    // Mock registration (same as login for this demo)
    return await login(email, password);
  }

  /// Update user profile
  static Future<bool> updateProfile({
    String? username,
    String? email,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      // Validate email if provided
      if (email != null && !User.isValidEmail(email)) {
        return false;
      }

      // Validate phone if provided
      if (phone != null && !User.isValidPhone(phone)) {
        return false;
      }

      // Update local state
      if (username != null) {
        _currentUsername = username;
        await _storage.write(key: _usernameKey, value: username);
      }

      if (email != null) {
        _currentEmail = email;
        await _storage.write(key: _emailKey, value: email);
      }

      if (phone != null) {
        _currentPhone = phone.isEmpty ? null : phone;
        if (phone.isEmpty) {
          await _storage.delete(key: _phoneKey);
        } else {
          await _storage.write(key: _phoneKey, value: phone);
        }
      }

      if (avatarPath != null) {
        _currentAvatarPath = avatarPath.isEmpty ? null : avatarPath;
        if (avatarPath.isEmpty) {
          await _storage.delete(key: _avatarKey);
        } else {
          await _storage.write(key: _avatarKey, value: avatarPath);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save avatar image to local storage
  static Future<String?> saveAvatar(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${directory.path}/avatars');

      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = 'avatar_${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await imageFile.copy('${avatarDir.path}/$fileName');

      // Delete old avatar if exists
      if (_currentAvatarPath != null && _currentAvatarPath!.isNotEmpty) {
        try {
          final oldFile = File(_currentAvatarPath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }

      _currentAvatarPath = savedFile.path;
      await _storage.write(key: _avatarKey, value: savedFile.path);

      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Delete avatar
  static Future<bool> deleteAvatar() async {
    try {
      if (_currentAvatarPath != null && _currentAvatarPath!.isNotEmpty) {
        final file = File(_currentAvatarPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentAvatarPath = null;
      await _storage.delete(key: _avatarKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout
  static Future<void> logout() async {
    _currentUserId = null;
    _currentUsername = null;
    _currentEmail = null;
    _currentPhone = null;
    _currentAvatarPath = null;
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _avatarKey);
  }
}
