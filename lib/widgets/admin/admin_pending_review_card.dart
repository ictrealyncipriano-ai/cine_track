import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A compact pending-review card for the admin dashboard showing rating,
/// text excerpt, user info, and a "Review →" action.
class AdminPendingReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onTap;

  const AdminPendingReviewCard({
    super.key,
    required this.review,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = review['rating'] as int? ?? 0;
    final text = review['review_text'] as String? ?? '';
    final userName = review['user_name'] as String? ?? 'Unknown';
    final status = review['status'] as String? ?? 'pending';

    final isReported = status == 'reported';
    final statusColor = isReported ? Colors.red : Colors.orange;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isReported
                  ? Colors.red.withValues(alpha: 0.2)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: rating stars + status badge
              Row(
                children: [
                  ...List.generate(5, (i) => Padding(
                    padding: const EdgeInsets.only(right: 1),
                    child: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      size: 15,
                      color: Colors.amber,
                    ),
                  )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isReported ? 'REPORTED' : 'PENDING',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Review excerpt
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // User name
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userName,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
