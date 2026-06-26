class Review {
  final int id;
  final int userId;
  final String userName;
  final int movieId;
  final int rating;
  final String reviewText;
  final String createdAt;
  final String updatedAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.movieId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      userName: json['user_name'] as String? ?? 'Anonymous',
      movieId: json['movie_id'] is int ? json['movie_id'] as int : int.parse(json['movie_id'].toString()),
      rating: json['rating'] is int ? json['rating'] as int : int.parse(json['rating'].toString()),
      reviewText: json['review_text'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}
