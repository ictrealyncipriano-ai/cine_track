import '../config.dart';

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}

class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String releaseDate;
  final double voteAverage;
  final List<int> genreIds;
  final int? runtime;
  final List<String> genres;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    this.genreIds = const [],
    this.runtime,
    this.genres = const [],
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    List<String> genreNames = [];
    if (json['genres'] != null) {
      genreNames = (json['genres'] as List<dynamic>)
          .map((g) => g['name'] as String)
          .toList();
    }

    return Movie(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String? ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      genreIds: (json['genre_ids'] as List<dynamic>?)?.cast<int>() ?? [],
      runtime: json['runtime'] as int?,
      genres: genreNames,
    );
  }

  factory Movie.fromBackendJson(Map<String, dynamic> json) {
    return Movie(
      id: json['movie_id'] is int
          ? json['movie_id'] as int
          : int.parse(json['movie_id'].toString()),
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String? ?? '',
      voteAverage: double.tryParse(json['vote_average']?.toString() ?? '') ??
          (json['vote_average'] as num?)?.toDouble() ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movie_id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate,
      'vote_average': voteAverage,
    };
  }

  String? get posterUrl => posterPath != null
      ? '${AppConfig.imageBaseUrl}$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null
      ? '${AppConfig.imageBaseUrl}$backdropPath'
      : null;
}
