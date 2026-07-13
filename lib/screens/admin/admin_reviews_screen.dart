import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/responsive.dart';
import '../../models/admin/admin_review.dart';
import '../../providers/admin/review_moderation_provider.dart';
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

  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _clearSelection();
        _fetchReviews();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewModerationProvider>().fetchReviews(status: 'pending');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(int reviewId) {
    setState(() {
      if (_selectedIds.contains(reviewId)) {
        _selectedIds.remove(reviewId);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(reviewId);
      }
    });
  }

  void _toggleSelectAll() {
    final admin = context.read<ReviewModerationProvider>();
    setState(() {
      if (_selectedIds.length == admin.reviews.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(admin.reviews.map((r) => r.id));
        _selectionMode = true;
      }
    });
  }

  Future<void> _fetchReviews() async {
    await context.read<ReviewModerationProvider>().fetchReviews(
      status: _tabStatuses[_tabController.index],
    );
  }

  Future<void> _bulkModerate(String action) async {
    final admin = context.read<ReviewModerationProvider>();
    if (_selectedIds.isEmpty) return;

    String? note;
    if (action == 'reject') {
      note = await _showRejectDialog();
      if (note == null) return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${action == 'approve' ? 'Approve' : 'Reject'} ${_selectedIds.length} reviews?'),
        content: Text('This will ${action == 'approve' ? 'approve' : 'reject'} ${_selectedIds.length} selected reviews.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action == 'approve' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await admin.bulkModerateReviews(_selectedIds.toList(), action, note: note);
      _clearSelection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reviews updated'),
          duration: Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<ReviewModerationProvider>();
    final isDesk = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _selectionMode ? '${_selectedIds.length} selected' : 'Review Moderation',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Toggle select all',
              onPressed: _toggleSelectAll,
            ),
          if (_selectionMode && _selectedIds.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
              tooltip: 'Approve selected',
              onPressed: () => _bulkModerate('approve'),
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Reject selected',
              onPressed: () => _bulkModerate('reject'),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : admin.error != null
              ? _buildError(admin)
              : admin.reviews.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () async {
                        _clearSelection();
                        await _fetchReviews();
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(isDesk ? 24 : 16),
                        itemCount: admin.reviews.length,
                        itemBuilder: (_, i) {
                          final r = admin.reviews[i];
                          final isSelected = _selectedIds.contains(r.id);
                          return AdminReviewCard(
                            review: r,
                            isSelected: isSelected,
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelection(r.id);
                              } else {
                                _selectionMode = true;
                                _selectedIds.add(r.id);
                                setState(() {});
                              }
                            },
                            onLongPress: () => _toggleSelection(r.id),
                            onApprove: () => _moderate(r, 'approve'),
                            onReject: () => _moderate(r, 'reject'),
                            onDismissReport: r.status == 'reported'
                                ? () => _moderate(r, 'dismiss_report')
                                : null,
                            onDelete: () => _deleteReview(r),
                          );
                        },
                      ),
                    ),
    );
  }

  Future<void> _moderate(AdminReview review, String action) async {
    final admin = context.read<ReviewModerationProvider>();
    final id = review.id;
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

  Future<void> _deleteReview(AdminReview review) async {
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
      await context.read<ReviewModerationProvider>().deleteReview(review.id);
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

  Widget _buildError(ReviewModerationProvider admin) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load reviews: ${admin.error}'),
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
