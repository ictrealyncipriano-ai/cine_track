import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/history_provider.dart';
import '../widgets/empty_state.dart';
import 'movie_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _initialized = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final hp = context.read<HistoryProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !hp.isLoadingMore &&
        hp.hasMore) {
      hp.loadMoreHistory();
    }
  }

  Future<void> _load() async {
    if (!_initialized) {
      _initialized = true;
      await context.read<HistoryProvider>().fetchHistory();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<HistoryProvider>().fetchHistory();
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _confirmDelete(BuildContext context, int movieId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text('Remove from history', style: GoogleFonts.inter(color: Colors.white)),
        content: Text('Remove "$title" from your watch history?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<HistoryProvider>().removeFromHistory(movieId);
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text('Clear all history', style: GoogleFonts.inter(color: Colors.white)),
        content: Text('Are you sure you want to remove all watch history? This cannot be undone.', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear All', style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<HistoryProvider>().clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HistoryProvider>();
    final allHistory = hp.history;

    List<dynamic> displayList = allHistory;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      displayList = allHistory.where((m) => m.title.toLowerCase().contains(q)).toList();
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Watch History',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (!hp.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '(${allHistory.length})',
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.white38),
                        ),
                      ),
                    const Spacer(),
                    if (!hp.isEmpty)
                      PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (v) {
                          setState(() => _sortBy = v);
                          context.read<HistoryProvider>().fetchHistory(sortBy: v);
                        },
                        icon: const Icon(Icons.sort, size: 20, color: Colors.white54),
                        color: const Color(0xFF161B22),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'recent', child: Text('Recent', style: TextStyle(color: _sortBy == 'recent' ? Theme.of(context).colorScheme.primary : Colors.white70))),
                          PopupMenuItem(value: 'title', child: Text('Title A-Z', style: TextStyle(color: _sortBy == 'title' ? Theme.of(context).colorScheme.primary : Colors.white70))),
                          PopupMenuItem(value: 'rating', child: Text('Rating', style: TextStyle(color: _sortBy == 'rating' ? Theme.of(context).colorScheme.primary : Colors.white70))),
                        ],
                      ),
                    if (!hp.isEmpty)
                      GestureDetector(
                        onTap: () => _confirmClearAll(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_sweep, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(
                                'Clear All',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!hp.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search history...',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: const Icon(Icons.clear, color: Colors.white38, size: 18),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF161B22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ),
            if (hp.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hp.errorMessage!,
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.redAccent),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => hp.clearError(),
                          child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (hp.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (allHistory.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.history,
                  title: 'No watch history yet',
                  subtitle: 'Movies you watch will appear here',
                ),
              )
            else if (displayList.isEmpty)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        'No results for "$_searchQuery"',
                        style: GoogleFonts.inter(fontSize: 16, color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= displayList.length) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final movie = displayList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey('history_${movie.id}'),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (direction) async {
                            await _confirmDelete(context, movie.id, movie.title);
                            return false;
                          },
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MovieDetailsScreen(movie: movie),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF161B22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 120,
                                    child: movie.posterUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: movie.posterUrl!,
                                            width: 80,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) => Container(color: const Color(0xFF0D1117)),
                                            errorWidget: (_, _, _) => const Icon(Icons.movie, color: Colors.white24),
                                          )
                                        : Container(color: const Color(0xFF0D1117), child: const Icon(Icons.movie, color: Colors.white24)),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            movie.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatDate(movie.watchedAt),
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.white54,
                                            ),
                                          ),
                                          if (movie.watchCount > 1) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.replay, size: 14, color: Color(0xFFFFC107)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Watched ${movie.watchCount} times',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: const Color(0xFFFFC107),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: displayList.length + (hp.isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
