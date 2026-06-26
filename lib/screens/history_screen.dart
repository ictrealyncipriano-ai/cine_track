import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/history_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _initialized = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HistoryProvider>();
    final history = hp.history;

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
                          '(${history.length})',
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.white38),
                        ),
                      ),
                  ],
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
            else if (history.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.history,
                  title: 'No watch history yet',
                  subtitle: 'Movies you watch will appear here',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= history.length) {
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return MovieCard(movie: history[index]);
                    },
                    childCount: history.length + (hp.isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
