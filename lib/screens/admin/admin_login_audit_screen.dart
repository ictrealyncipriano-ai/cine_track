import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/responsive.dart';
import '../../helpers/time_ago.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';
import '../../widgets/pagination_bar.dart';

class AdminLoginAuditScreen extends StatefulWidget {
  const AdminLoginAuditScreen({super.key});

  @override
  State<AdminLoginAuditScreen> createState() => _AdminLoginAuditScreenState();
}

class _AdminLoginAuditScreenState extends State<AdminLoginAuditScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _logs = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;
  final _emailController = TextEditingController();
  String? _successFilter;
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  Future<void> _fetch({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = page;
    });
    try {
      final q = <String, String>{
        'page': page.toString(),
        'per_page': '30',
      };
      if (_emailController.text.isNotEmpty) q['email'] = _emailController.text;
      if (_successFilter != null) q['success'] = _successFilter!;
      if (_dateFromController.text.isNotEmpty) q['date_from'] = _dateFromController.text;
      if (_dateToController.text.isNotEmpty) q['date_to'] = _dateToController.text;
      final qs = ApiService.buildQueryString(q);
      final data = await _api.get('${ApiEndpoints.loginAudit}?$qs');
      _logs = (data['logs'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      _total = data['total'] as int? ?? 0;
    } catch (e) {
      debugPrint('Failed to load login audit: $e');
      _error = 'Failed to load login audit. Please try again.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesk = Responsive.isDesktop(context);
    final theme = Theme.of(context);



    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Login Audit',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Column(
        children: [
          _buildFilters(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _logs.isEmpty
                        ? _buildEmpty()
                        : _buildList(theme, isDesk),
          ),
          if (_total > 30)
            PaginationBar(
              currentPage: _page,
              totalPages: (_total / 30).ceil(),
              onPageChanged: (p) => _fetch(page: p),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Search email...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _fetch(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _successFilter,
                hint: const Text('All'),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: '1', child: Text('Success')),
                  DropdownMenuItem(value: '0', child: Text('Failed')),
                ],
                onChanged: (v) {
                  setState(() => _successFilter = v);
                  _fetch();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateFromController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'From date',
                    prefixIcon: const Icon(Icons.calendar_today, size: 18),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 7)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      _dateFromController.text =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      _fetch();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dateToController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'To date',
                    prefixIcon: const Icon(Icons.calendar_today, size: 18),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      _dateToController.text =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      _fetch();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme, bool isDesk) {
    if (isDesk) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('IP')),
            DataColumn(label: Text('Provider')),
            DataColumn(label: Text('Date')),
          ],
          rows: _logs.map((log) {
            final success = log['success'] == 1 || log['success'] == '1';
            return DataRow(cells: [
              DataCell(Text(log['email'] ?? '', style: GoogleFonts.inter(fontSize: 13))),
              DataCell(Text(log['user_name']?.toString() ?? '-', style: GoogleFonts.inter(fontSize: 12))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(success ? Icons.check_circle : Icons.cancel, size: 16, color: success ? Colors.green : Colors.red),
                  const SizedBox(width: 4),
                  Text(success ? 'Success' : 'Failed', style: GoogleFonts.inter(fontSize: 12)),
                ],
              )),
              DataCell(Text(log['ip'] ?? '', style: GoogleFonts.inter(fontSize: 12))),
              DataCell(Text(log['provider'] ?? 'email', style: GoogleFonts.inter(fontSize: 12))),
              DataCell(Text(timeAgo(log['created_at'] as String? ?? ''), style: GoogleFonts.inter(fontSize: 12))),
            ]);
          }).toList(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _logs.length,
      itemBuilder: (_, i) {
        final log = _logs[i];
        final success = log['success'] == 1 || log['success'] == '1';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: (success ? Colors.green : Colors.red).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(success ? Icons.check_circle : Icons.cancel, size: 18, color: success ? Colors.green : Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(log['email'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (success ? Colors.green : Colors.red).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(success ? 'SUCCESS' : 'FAILED', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: success ? Colors.green : Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${log['provider'] ?? 'email'} · ${log['ip'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      Text(log['user_agent'] as String? ?? '', style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(timeAgo(log['created_at'] as String? ?? ''), style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.38))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load login audit. Please try again.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _fetch(),
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
          Icon(Icons.login, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No login attempts found', style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
        ],
      ),
    );
  }
}
