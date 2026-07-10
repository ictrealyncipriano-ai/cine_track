import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../helpers/responsive.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String? _roleFilter;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    context.read<AdminProvider>().fetchUsers(
      search: _searchController.text,
      role: _roleFilter,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
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
          'User Management',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Column(
        children: [
          // ── Search & Filter ──
          _buildSearchBar(context),
          // ── Table / List ──
          Expanded(
            child: admin.isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : admin.usersError != null
                    ? _buildError(admin)
                    : admin.users.isEmpty
                        ? _buildEmpty()
                        : _buildUserList(admin, isDesk),
          ),
          // ── Pagination ──
          if (admin.totalUsers > 20)
            _buildPagination(admin),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _roleFilter,
            hint: const Text('All Roles'),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Roles')),
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'moderator', child: Text('Moderator')),
            ],
            onChanged: (v) {
              setState(() => _roleFilter = v);
              _search();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(AdminProvider admin, bool isDesk) {
    if (isDesk) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DataTable(
          sortColumnIndex: _sortBy == 'name' ? 1 : _sortBy == 'email' ? 2 : 0,
          sortAscending: _sortOrder == 'asc',
          columns: [
            DataColumn(label: const Text('User')),
            DataColumn(
              label: const Text('Name'),
              onSort: (_, asc) => _sort('name', asc),
            ),
            DataColumn(
              label: const Text('Email'),
              onSort: (_, asc) => _sort('email', asc),
            ),
            const DataColumn(label: Text('Role')),
            const DataColumn(label: Text('Status')),
            const DataColumn(label: Text('Joined')),
            const DataColumn(label: Text('Actions')),
          ],
          rows: admin.users.map((u) => _buildUserRow(u, context)).toList(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: admin.users.length,
      itemBuilder: (_, i) => _buildUserCard(admin.users[i], context),
    );
  }

  DataRow _buildUserRow(Map<String, dynamic> user, BuildContext context) {
    final theme = Theme.of(context);
    final role = user['role'] as String? ?? 'user';
    final verified = user['email_verified'] == true;
    return DataRow(
      cells: [
        DataCell(_buildAvatar(user)),
        DataCell(Text(user['name'] as String? ?? '', style: GoogleFonts.inter(fontSize: 14))),
        DataCell(Text(user['email'] as String? ?? '', style: GoogleFonts.inter(fontSize: 13))),
        DataCell(_buildRoleChip(role, theme)),
        DataCell(
          verified
              ? Icon(Icons.check_circle, size: 18, color: Colors.green)
              : Icon(Icons.cancel, size: 18, color: Colors.grey),
        ),
        DataCell(Text(_relativeDate(user['created_at'] as String?), style: GoogleFonts.inter(fontSize: 12))),
        DataCell(_buildActions(user, context)),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, BuildContext context) {
    final theme = Theme.of(context);
    final role = user['role'] as String? ?? 'user';
    final verified = user['email_verified'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] as String? ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(user['email'] as String? ?? '', style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildRoleChip(role, theme),
                      const SizedBox(width: 8),
                      Icon(verified ? Icons.check_circle : Icons.cancel, size: 14, color: verified ? Colors.green : Colors.grey),
                      const SizedBox(width: 4),
                      Text(_relativeDate(user['created_at'] as String?), style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.38))),
                    ],
                  ),
                ],
              ),
            ),
            _buildActions(user, context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> user) {
    final avatarUrl = user['avatar_url'] as String?;
    return CircleAvatar(
      radius: 20,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? (avatarUrl.startsWith('data:')
              ? MemoryImage(base64Decode(avatarUrl.split(',').length >= 2 ? avatarUrl.split(',')[1] : ''))
              : NetworkImage(avatarUrl) as ImageProvider)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text((user['name'] as String? ?? '?')[0].toUpperCase())
          : null,
    );
  }

  Widget _buildRoleChip(String role, ThemeData theme) {
    Color color;
    switch (role) {
      case 'admin':
        color = Colors.amber;
        break;
      case 'moderator':
        color = Colors.blue;
        break;
      default:
        color = theme.colorScheme.onSurface.withValues(alpha: 0.38);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildActions(Map<String, dynamic> user, BuildContext context) {
    final userId = user['id'] as int;
    final isBanned = user['banned_at'] != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'View Profile',
          onPressed: () => _showUserDetail(user, context),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (action) => _handleUserAction(action, userId, context),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'promote', child: Text('Promote to Admin')),
            const PopupMenuItem(value: 'demote', child: Text('Demote to User')),
            if (isBanned)
              const PopupMenuItem(value: 'unban', child: Text('Unban User'))
            else
              const PopupMenuItem(value: 'ban', child: Text('Ban User')),
            const PopupMenuItem(value: 'delete', child: Text('Delete Account')),
          ],
        ),
      ],
    );
  }

  void _sort(String column, bool asc) {
    setState(() {
      _sortBy = column;
      _sortOrder = asc ? 'asc' : 'desc';
    });
    _search();
  }

  void _handleUserAction(String action, int userId, BuildContext context) async {
    final admin = context.read<AdminProvider>();
    try {
      switch (action) {
        case 'promote':
          await admin.updateUserRole(userId, 'admin');
          if (context.mounted) _showSnack(context, 'User promoted to admin');
          break;
        case 'demote':
          await admin.updateUserRole(userId, 'user');
          if (context.mounted) _showSnack(context, 'User demoted to member');
          break;
        case 'ban':
          final confirm = await _confirmDialog(context, 'Ban this user?');
          if (confirm == true) {
            await admin.toggleBanUser(userId, true);
            if (context.mounted) _showSnack(context, 'User banned');
          }
          break;
        case 'unban':
          final confirm = await _confirmDialog(context, 'Unban this user?');
          if (confirm == true) {
            await admin.toggleBanUser(userId, false);
            if (context.mounted) _showSnack(context, 'User unbanned');
          }
          break;
        case 'delete':
          final confirm = await _confirmDialog(context, 'Permanently delete this user? This cannot be undone.');
          if (confirm == true) {
            await admin.deleteUser(userId);
            if (context.mounted) _showSnack(context, 'User deleted');
          }
          break;
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Error: $e');
    }
  }

  void _showUserDetail(Map<String, dynamic> user, BuildContext context) {
    final theme = Theme.of(context);
    final role = user['role'] as String? ?? 'user';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(child: _buildAvatar(user)),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user['name'] as String? ?? '',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              Center(
                child: Text(
                  '@${user['username'] as String? ?? ''}',
                  style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.54)),
                ),
              ),
              const SizedBox(height: 16),
              _detailRow(theme, 'Email', user['email'] as String? ?? ''),
              _detailRow(theme, 'Role', role.toUpperCase()),
              _detailRow(theme, 'Email Verified', user['email_verified'] == true ? 'Yes' : 'No'),
              _detailRow(theme, 'Status', user['banned_at'] != null ? '⚠ Banned' : 'Active'),
              _detailRow(theme, 'Phone', user['phone'] as String? ?? '—'),
              _detailRow(theme, 'Country', user['country'] as String? ?? '—'),
              _detailRow(theme, 'Joined', _relativeDate(user['created_at'] as String?)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statChip(theme, 'Favorites', user['favorites_count'] as int? ?? 0)),
                  Expanded(child: _statChip(theme, 'Watchlist', user['watchlist_count'] as int? ?? 0)),
                  Expanded(child: _statChip(theme, 'Reviews', user['reviews_count'] as int? ?? 0)),
                  Expanded(child: _statChip(theme, 'History', user['history_count'] as int? ?? 0)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _statChip(ThemeData theme, String label, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(count.toString(), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
        ],
      ),
    );
  }

  Widget _buildPagination(AdminProvider admin) {
    final totalPages = (admin.totalUsers / 20).ceil();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: admin.usersPage > 1
                ? () => admin.fetchUsers(
                      search: _searchController.text,
                      role: _roleFilter,
                      page: admin.usersPage - 1,
                    )
                : null,
          ),
          Text(
            'Page ${admin.usersPage} of $totalPages',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: admin.usersPage < totalPages
                ? () => admin.fetchUsers(
                      search: _searchController.text,
                      role: _roleFilter,
                      page: admin.usersPage + 1,
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildError(AdminProvider admin) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load users: ${admin.usersError}'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _search(),
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
          Icon(Icons.people_outline, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No users found', style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<bool?> _confirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
  }

  String _relativeDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 60) return '${diff.inDays ~/ 30}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      return 'Today';
    } catch (_) {
      return dateStr;
    }
  }
}
