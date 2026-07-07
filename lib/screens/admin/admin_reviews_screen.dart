import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/responsive.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_review_card.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['Pending', 'Reported', 'Approved', 'All'];
  static const _tabStatuses = ['pending', 'reported', 'approved', 'all'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchReviews();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchReviews(status: 'pending');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    await context.read<AdminProvider>().fetchReviews(
      status: _tabStatuses[_tabController.index],
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesk = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Review Moderation',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: admin.isLoadingReviews
          ? const Center(child: CircularProgressIndicator())
          : admin.reviewsError != null
              ? _buildError(admin)
              : admin.reviews.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => _fetchReviews(),
                      child: ListView.builder(
                        padding: EdgeInsets.all(isDesk ? 24 : 16),
                        itemCount: admin.reviews.length,
                        itemBuilder: (_, i) {
                          final r = admin.reviews[i];
                          return AdminReviewCard(
                            review: r,
                            onApprove: () => _moderate(r, 'approve'),
                            onReject: () => _moderate(r, 'reject'),
                            onDismissReport: r['status'] == 'reported'
                                ? () => _moderate(r, 'dismiss_report')
                                : null,
                            onDelete: () => _deleteReview(r),
                          );
                        },
                      ),
                    ),
    );
  }

  Future<void> _moderate(Map<String, dynamic> review, String action) async {
    final admin = context.read<AdminProvider>();
    final id = review['id'] as int;
    try {
      String? note;
      if (action == 'reject') {
        note = await _showRejectDialog();
        if (note == null) return;
      }
      await admin.moderateReview(id, action, note: note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(action == 'approve'
              ? 'Review approved'
              : action == 'reject'
                  ? 'Review rejected'
                  : 'Report dismissed'),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _deleteReview(Map<String, dynamic> review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Permanently delete this review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<AdminProvider>().deleteReview(review['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Review deleted'),
          duration: Duration(seconds: 2),
        ));
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Review'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Widget _buildError(AdminProvider admin) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load reviews: ${admin.reviewsError}'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _fetchReviews,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined, size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No ${_tabStatuses[_tabController.index]} reviews',
            style: GoogleFonts.inter(fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
          ),
          const SizedBox(height: 8),
          Text(
            'All clear!',
            style: GoogleFonts.inter(fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
          ),
        ],
      ),
    );
  }
}
