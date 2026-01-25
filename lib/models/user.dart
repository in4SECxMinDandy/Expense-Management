/// User model for storing profile information
class User {
  final String? id;
  final String username;
  final String email;
  final String? phone;
  final String? avatarPath;
  final DateTime? createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    this.phone,
    this.avatarPath,
    this.createdAt,
  });

  /// Create User from Map (database)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      avatarPath: map['avatar_path'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar_path': avatarPath,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? avatarPath,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate phone format (Vietnam)
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return true; // Phone is optional
    return RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(phone);
  }
}
