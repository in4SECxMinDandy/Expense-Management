import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  /// Save avatar image from file path (non-web only)
  static Future<String?> saveAvatarFromPath(String imagePath) async {
    if (kIsWeb) return null;

    try {
      // Sử dụng conditional import để tránh lỗi web
      return await _saveAvatarNative(imagePath);
    } catch (e) {
      debugPrint('Error saving avatar: $e');
      return null;
    }
  }

  /// Delete avatar
  static Future<bool> deleteAvatar() async {
    try {
      if (!kIsWeb && _currentAvatarPath != null && _currentAvatarPath!.isNotEmpty) {
        await _deleteAvatarNative(_currentAvatarPath!);
      }
      _currentAvatarPath = null;
      await _storage.delete(key: _avatarKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Native file operations (non-web)
  static Future<String?> _saveAvatarNative(String imagePath) async {
    if (kIsWeb) return null;
    try {
      // Sử dụng dart:io chỉ trên non-web
      // ignore: avoid_dynamic_calls
      return await _AuthServiceNative.saveAvatar(imagePath, _currentUserId, _currentAvatarPath);
    } catch (e) {
      return null;
    }
  }

  static Future<void> _deleteAvatarNative(String path) async {
    if (kIsWeb) return;
    try {
      await _AuthServiceNative.deleteAvatar(path);
    } catch (_) {}
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

/// Native file operations helper (chỉ dùng trên non-web)
class _AuthServiceNative {
  static Future<String?> saveAvatar(
    String imagePath,
    String? userId,
    String? oldAvatarPath,
  ) async {
    if (kIsWeb) return null;

    try {
      // Sử dụng dart:io thông qua dynamic import
      return await _saveAvatarWithIo(imagePath, userId, oldAvatarPath);
    } catch (e) {
      debugPrint('Error in _AuthServiceNative.saveAvatar: $e');
      return null;
    }
  }

  static Future<void> deleteAvatar(String path) async {
    if (kIsWeb) return;
    try {
      await _deleteAvatarWithIo(path);
    } catch (_) {}
  }
}

// Các hàm này sẽ được override bởi conditional imports
// Trên non-web, chúng sẽ sử dụng dart:io
Future<String?> _saveAvatarWithIo(
  String imagePath,
  String? userId,
  String? oldAvatarPath,
) async {
  // Fallback: trả về path gốc nếu không thể copy
  return imagePath;
}

Future<void> _deleteAvatarWithIo(String path) async {
  // Fallback: không làm gì
}
