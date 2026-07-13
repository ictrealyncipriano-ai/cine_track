class DashboardStats {
  final int totalUsers;
  final int newToday;
  final int newThisWeek;
  final int active7d;
  final int totalReviews;
  final int totalMovies;
  final int pendingReviews;

  const DashboardStats({
    required this.totalUsers,
    required this.newToday,
    required this.newThisWeek,
    required this.active7d,
    required this.totalReviews,
    required this.totalMovies,
    required this.pendingReviews,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: (json['total_users'] as int?) ?? 0,
      newToday: (json['new_today'] as int?) ?? 0,
      newThisWeek: (json['new_this_week'] as int?) ?? 0,
      active7d: (json['active_7d'] as int?) ?? 0,
      totalReviews: (json['total_reviews'] as int?) ?? 0,
      totalMovies: (json['total_movies'] as int?) ?? 0,
      pendingReviews: (json['pending_reviews'] as int?) ?? 0,
    );
  }

  DashboardStats copyWith({
    int? totalUsers,
    int? newToday,
    int? newThisWeek,
    int? active7d,
    int? totalReviews,
    int? totalMovies,
    int? pendingReviews,
  }) {
    return DashboardStats(
      totalUsers: totalUsers ?? this.totalUsers,
      newToday: newToday ?? this.newToday,
      newThisWeek: newThisWeek ?? this.newThisWeek,
      active7d: active7d ?? this.active7d,
      totalReviews: totalReviews ?? this.totalReviews,
      totalMovies: totalMovies ?? this.totalMovies,
      pendingReviews: pendingReviews ?? this.pendingReviews,
    );
  }
}
