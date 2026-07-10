import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single row in the admin activity feed with a cleaner, more modern design.
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

  (IconData, Color) _actionMeta(ThemeData theme) {
    switch (actionType) {
      case 'favorite':
        return (Icons.favorite, Colors.red);
      case 'watch':
        return (Icons.visibility, theme.colorScheme.primary);
      case 'review':
        return (Icons.rate_review, Colors.amber);
      case 'watchlist':
        return (Icons.bookmark, Colors.blue);
      default:
        return (Icons.circle, theme.colorScheme.onSurface.withValues(alpha: 0.3));
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
    final (icon, color) = _actionMeta(theme);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.35,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                    children: [
                      TextSpan(
                        text: userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: ' $description',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (movieTitle != null && movieTitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      movieTitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time
          Text(
            _relativeTime(),
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
