import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/admin/admin_review.dart';
import '../review_replies_section.dart';

/// A review card for the moderation queue with status and action buttons.
class AdminReviewCard extends StatelessWidget {
  final AdminReview review;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onDismissReport;
  final VoidCallback? onDelete;

  const AdminReviewCard({
    super.key,
    required this.review,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    required this.onApprove,
    required this.onReject,
    this.onDismissReport,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = review.status;
    final rating = review.rating;
    final text = review.reviewText ?? '';
    final userName = review.userName ?? 'Unknown';
    final reportReason = review.reportReason;
    final isReported = status == 'reported';
    final isPending = status == 'pending';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'PENDING';
        break;
      case 'reported':
        statusColor = Colors.red;
        statusLabel = 'REPORTED';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'APPROVED';
        break;
      case 'rejected':
        statusColor = Colors.grey;
        statusLabel = 'REJECTED';
        break;
      default:
        statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.38);
        statusLabel = status.toUpperCase();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
      padding: EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : isReported
              ? Colors.red.withValues(alpha: 0.3)
              : theme.colorScheme.onSurface.withValues(alpha: 0.08),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                ),
              // Star rating
              ...List.generate(5, (i) => Icon(
                i < (rating / 2).ceil() ? Icons.star : Icons.star_border,
                size: 18,
                color: Colors.amber,
              )),
              const Spacer(),
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
              const SizedBox(width: 4),
              Text(
                userName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.movie_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
              const SizedBox(width: 4),
              Text(
                'Movie #${review.movieId}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                ),
              ),
            ],
          ),
          if (reportReason != null && reportReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Report: $reportReason',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          ReviewRepliesSection(reviewId: review.id, isAdmin: true),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onDismissReport != null)
                TextButton.icon(
                  onPressed: onDismissReport,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Dismiss'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              if (isPending || isReported) ...[
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: theme.colorScheme.error,
                  tooltip: 'Delete',
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}
