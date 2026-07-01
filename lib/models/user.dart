class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool emailVerified;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.emailVerified,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      emailVerified: json['email_verified'] == true,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    bool? emailVerified,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
