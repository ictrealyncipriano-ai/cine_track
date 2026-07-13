class AdminUser {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? country;
  final String role;
  final bool emailVerified;
  final String? avatarUrl;
  final String? bannedAt;
  final String createdAt;
  final int favoritesCount;
  final int watchlistCount;
  final int reviewsCount;
  final int historyCount;

  const AdminUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.country,
    required this.role,
    required this.emailVerified,
    this.avatarUrl,
    this.bannedAt,
    required this.createdAt,
    this.favoritesCount = 0,
    this.watchlistCount = 0,
    this.reviewsCount = 0,
    this.historyCount = 0,
  });

  bool get isBanned => bannedAt != null;
  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator' || role == 'admin';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      role: json['role'] as String? ?? 'user',
      emailVerified: json['email_verified'] == true,
      avatarUrl: json['avatar_url'] as String?,
      bannedAt: json['banned_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      favoritesCount: (json['favorites_count'] as num?)?.toInt() ?? 0,
      watchlistCount: (json['watchlist_count'] as num?)?.toInt() ?? 0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      historyCount: (json['history_count'] as num?)?.toInt() ?? 0,
    );
  }

  AdminUser copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? country,
    String? role,
    bool? emailVerified,
    String? avatarUrl,
    String? bannedAt,
    String? createdAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannedAt: bannedAt ?? this.bannedAt,
      createdAt: createdAt ?? this.createdAt,
      favoritesCount: favoritesCount,
      watchlistCount: watchlistCount,
      reviewsCount: reviewsCount,
      historyCount: historyCount,
    );
  }
}
