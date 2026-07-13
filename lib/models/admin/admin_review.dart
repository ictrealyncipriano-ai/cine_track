class AdminReview {
  final int id;
  final int userId;
  final int movieId;
  final int rating;
  final String? reviewText;
  final String status;
  final int? moderatedBy;
  final String? moderatedAt;
  final String? moderationNote;
  final String? reportReason;
  final String createdAt;
  final String? updatedAt;
  final String? userName;
  final String? userUsername;
  final String? userAvatar;
  final String? moderatorName;

  const AdminReview({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.rating,
    this.reviewText,
    required this.status,
    this.moderatedBy,
    this.moderatedAt,
    this.moderationNote,
    this.reportReason,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userUsername,
    this.userAvatar,
    this.moderatorName,
  });

  factory AdminReview.fromJson(Map<String, dynamic> json) {
    return AdminReview(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      movieId: (json['movie_id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      reviewText: json['review_text'] as String?,
      status: json['status'] as String? ?? 'pending',
      moderatedBy: (json['moderated_by'] as num?)?.toInt(),
      moderatedAt: json['moderated_at'] as String?,
      moderationNote: json['moderation_note'] as String?,
      reportReason: json['report_reason'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      userName: json['user_name'] as String?,
      userUsername: json['user_username'] as String?,
      userAvatar: json['user_avatar'] as String?,
      moderatorName: json['moderator_name'] as String?,
    );
  }
}
