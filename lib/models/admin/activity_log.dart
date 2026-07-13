class ActivityLog {
  final int id;
  final String? adminName;
  final String actionType;
  final String targetType;
  final int? targetId;
  final String? description;
  final String createdAt;

  const ActivityLog({
    required this.id,
    this.adminName,
    required this.actionType,
    required this.targetType,
    this.targetId,
    this.description,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: (json['id'] as num).toInt(),
      adminName: json['admin_name'] as String?,
      actionType: json['action_type'] as String? ?? json['action'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetId: (json['target_id'] as num?)?.toInt(),
      description: json['description'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
