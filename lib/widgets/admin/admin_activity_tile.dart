import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single row in the admin activity feed.
class AdminActivityTile extends StatelessWidget {
  final String userName;
  final String? userAvatar;
  final String actionType;
  final String description;
  final String? movieTitle;
  final String createdAt;

  const AdminActivityTile({
    super.key,
    required this.userName,
    this.userAvatar,
    required this.actionType,
    required this.description,
    this.movieTitle,
    required this.createdAt,
  });

  IconData _iconForAction() {
    switch (actionType) {
      case 'favorite':
        return Icons.favorite;
      case 'watch':
        return Icons.visibility;
      case 'review':
        return Icons.rate_review;
      case 'watchlist':
        return Icons.bookmark;
      default:
        return Icons.circle;
    }
  }

  Color _colorForAction(ThemeData theme) {
    switch (actionType) {
      case 'favorite':
        return Colors.red;
      case 'watch':
        return theme.colorScheme.primary;
      case 'review':
        return Colors.amber;
      case 'watchlist':
        return Colors.blue;
      default:
        return theme.colorScheme.onSurface.withValues(alpha: 0.38);
    }
  }

  String _relativeTime() {
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionColor = _colorForAction(theme);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: actionColor.withValues(alpha: 0.15),
            child: Icon(_iconForAction(), size: 16, color: actionColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
                ),
                children: [
                  TextSpan(
                    text: userName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeTime(),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }
}
