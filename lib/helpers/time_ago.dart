String timeAgo(String? dateStr) {
  if (dateStr == null) return '\u2014';
  try {
    final dt = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 60) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  } catch (_) {
    return dateStr;
  }
}
