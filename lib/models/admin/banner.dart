class AppBanner {
  final int id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final int sortOrder;
  final bool active;
  final String? createdAt;
  final String? updatedAt;

  AppBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.sortOrder = 0,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AppBanner.fromJson(Map<String, dynamic> json) {
    return AppBanner(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      linkUrl: json['link_url'],
      sortOrder: json['sort_order'] is int ? json['sort_order'] : int.parse(json['sort_order']?.toString() ?? '0'),
      active: json['active'] == 1 || json['active'] == true || json['active'] == '1',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'sort_order': sortOrder,
      'active': active,
    };
  }
}
