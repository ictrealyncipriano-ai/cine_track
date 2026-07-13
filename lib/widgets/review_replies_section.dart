import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/review_reply_provider.dart';
import '../helpers/time_ago.dart';

class ReviewRepliesSection extends StatelessWidget {
  final int reviewId;
  final bool isAdmin;

  const ReviewRepliesSection({super.key, required this.reviewId, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReviewReplyProvider>();
    final expanded = prov.isExpanded(reviewId);
    final replies = prov.repliesByReview[reviewId] ?? [];
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => prov.toggleExpanded(reviewId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.reply, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  expanded ? 'Hide replies (${replies.length})' : 'Replies (${replies.length})',
                  style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.primary),
                ),
                Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          ...replies.map((r) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    (r.userName ?? 'A')[0].toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(r.userName ?? 'Anonymous', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                          const SizedBox(width: 6),
                          Text(timeAgo(r.createdAt), style: GoogleFonts.inter(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                          if (isAdmin)
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 14, color: theme.colorScheme.error),
                              onPressed: () => prov.deleteReply(r.id),
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(r.body, style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          _ReplyInput(reviewId: reviewId),
        ],
      ],
    );
  }
}

class _ReplyInput extends StatefulWidget {
  final int reviewId;
  const _ReplyInput({required this.reviewId});

  @override
  State<_ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<_ReplyInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.12))),
              ),
              style: GoogleFonts.inter(fontSize: 12),
              textInputAction: TextInputAction.send,
              onSubmitted: _submit,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(Icons.send, size: 16, color: theme.colorScheme.primary),
            onPressed: () => _submit(_ctrl.text),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _submit(String text) {
    if (text.trim().isEmpty) return;
    context.read<ReviewReplyProvider>().addReply(widget.reviewId, text.trim());
    _ctrl.clear();
  }
}
