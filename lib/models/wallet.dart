class Wallet {
  final int? id;
  final String name;
  final String type; // 'cash', 'bank', 'credit_card', 'e_wallet'
  final double balance;
  final String? icon;
  final String? color;
  final bool isDefault;
  final String? createdAt;

  Wallet({
    this.id,
    required this.name,
    required this.type,
    this.balance = 0,
    this.icon,
    this.color,
    this.isDefault = false,
    this.createdAt,
  });

  String get typeDisplayName {
    switch (type) {
      case 'cash':
        return 'Tiền mặt';
      case 'bank':
        return 'Ngân hàng';
      case 'credit_card':
        return 'Thẻ tín dụng';
      case 'e_wallet':
        return 'Ví điện tử';
      default:
        return type;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'icon': icon,
      'color': color,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isDefault: (map['is_default'] as int?) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  Wallet copyWith({
    int? id,
    String? name,
    String? type,
    double? balance,
    String? icon,
    String? color,
    bool? isDefault,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }
}
