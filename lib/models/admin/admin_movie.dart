class AdminMovie {
  final int movieId;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final String? genres;
  final int runtime;
  final String status;
  final bool featured;
  final int reviewCount;
  final int favoriteCount;
  final int watchlistCount;
  final int totalInteractions;
  final String? lastInteraction;

  const AdminMovie({
    required this.movieId,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.releaseDate,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.genres,
    this.runtime = 0,
    this.status = 'published',
    this.featured = false,
    this.reviewCount = 0,
    this.favoriteCount = 0,
    this.watchlistCount = 0,
    this.totalInteractions = 0,
    this.lastInteraction,
  });

  factory AdminMovie.fromJson(Map<String, dynamic> json) {
    return AdminMovie(
      movieId: (json['movie_id'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      genres: json['genres'] as String?,
      runtime: (json['runtime'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'published',
      featured: json['featured'] == true || json['featured'] == 1,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favorite_count'] as num?)?.toInt() ?? 0,
      watchlistCount: (json['watchlist_count'] as num?)?.toInt() ?? 0,
      totalInteractions: (json['total_interactions'] as num?)?.toInt() ?? 0,
      lastInteraction: json['last_interaction'] as String?,
    );
  }

  AdminMovie copyWith({
    int? movieId,
    String? title,
    String? posterPath,
    String? backdropPath,
    String? overview,
    String? releaseDate,
    double? voteAverage,
    int? voteCount,
    String? genres,
    int? runtime,
    String? status,
    bool? featured,
  }) {
    return AdminMovie(
      movieId: movieId ?? this.movieId,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      releaseDate: releaseDate ?? this.releaseDate,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      genres: genres ?? this.genres,
      runtime: runtime ?? this.runtime,
      status: status ?? this.status,
      featured: featured ?? this.featured,
      reviewCount: reviewCount,
      favoriteCount: favoriteCount,
      watchlistCount: watchlistCount,
      totalInteractions: totalInteractions,
      lastInteraction: lastInteraction,
    );
  }
}
