class ApiEndpoints {
  static const dashboard = '/admin/dashboard.php';
  static const users = '/admin/users.php';
  static const updateUserRole = '/admin/users/update_role.php';
  static const toggleBan = '/admin/users/toggle_ban.php';
  static const deleteUser = '/admin/users/delete.php';
  static const reviews = '/admin/reviews.php';
  static const moderateReview = '/admin/reviews/moderate.php';
  static const bulkModerateReview = '/admin/reviews/bulk_moderate.php';
  static const deleteReview = '/admin/reviews/delete.php';
  static const movies = '/admin/movies.php';
  static const movieAdd = '/admin/movies/add.php';
  static const movieUpdate = '/admin/movies/update.php';
  static const movieDelete = '/admin/movies/delete.php';
  static const movieSearchTmdb = '/admin/movies/search_tmdb.php';
  static const activity = '/admin/activity.php';
  static const loginAudit = '/admin/activity/login_audit.php';
  static const settings = '/admin/settings.php';
  static const settingsUpdate = '/admin/settings/update.php';
  // Banners
  static const banners = '/admin/banners.php';
  static const bannerAdd = '/admin/banners/add.php';
  static const bannerUpdate = '/admin/banners/update.php';
  static const bannerDelete = '/admin/banners/delete.php';
  static const publicBanners = '/banners.php';
  // Featured movies
  static const featuredMovies = '/movies/featured.php';
  // Review replies
  static const reviewReplies = '/reviews/replies.php';
  static const reviewReply = '/reviews/reply.php';
  static const deleteReviewReply = '/admin/reviews/delete_reply.php';
  // Analytics
  static const analyticsOverview = '/admin/analytics/overview.php';
  static const analyticsTrends = '/admin/analytics/trends.php';
  static const analyticsExport = '/admin/analytics/export.php';
}
