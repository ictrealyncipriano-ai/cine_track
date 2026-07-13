class ReviewReply {
  final int id;
  final int reviewId;
  final String body;
  final String createdAt;
  final int? userId;
  final String? userName;
  final String? userAvatar;

  ReviewReply({
    required this.id,
    required this.reviewId,
    required this.body,
    required this.createdAt,
    this.userId,
    this.userName,
    this.userAvatar,
  });

  factory ReviewReply.fromJson(Map<String, dynamic> json) {
    return ReviewReply(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      reviewId: json['review_id'] is int ? json['review_id'] : int.parse(json['review_id'].toString()),
      body: json['body'] ?? '',
      createdAt: json['created_at'] ?? '',
      userId: json['user_id'] != null ? (json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString())) : null,
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
    );
  }
}
