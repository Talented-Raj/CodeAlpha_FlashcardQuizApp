class UserModel {
  final String name;
  final String email;
  final String currency;
  final double monthlyBudget;

  UserModel({
    required this.name,
    required this.email,
    required this.currency,
    required this.monthlyBudget,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? currency,
    double? monthlyBudget,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'currency': currency,
      'monthlyBudget': monthlyBudget,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      currency: map['currency'] ?? '\$',
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 1000.0,
    );
  }
}
