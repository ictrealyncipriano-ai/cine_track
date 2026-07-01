class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? dateOfBirth;
  final String? country;
  final bool marketingOptIn;
  final String role;
  final bool emailVerified;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.country,
    this.marketingOptIn = false,
    required this.role,
    required this.emailVerified,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      country: json['country'] as String?,
      marketingOptIn: json['marketing_opt_in'] == true,
      role: json['role'] as String? ?? 'user',
      emailVerified: json['email_verified'] == true,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? country,
    bool? marketingOptIn,
    String? role,
    bool? emailVerified,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
