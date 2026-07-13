import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/responsive.dart';
import '../../models/admin/banner.dart' as banner_model;
import '../../providers/admin/banner_management_provider.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BannerManagementProvider>().fetchBanners();
    });
  }

  Future<void> _showBannerDialog({banner_model.AppBanner? banner}) async {
    final titleCtrl = TextEditingController(text: banner?.title ?? '');
    final imageCtrl = TextEditingController(text: banner?.imageUrl ?? '');
    final linkCtrl = TextEditingController(text: banner?.linkUrl ?? '');
    final sortCtrl = TextEditingController(text: banner?.sortOrder.toString() ?? '0');
    bool active = banner?.active ?? true;

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(banner != null ? 'Edit Banner' : 'Add Banner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title'), textInputAction: TextInputAction.next),
                const SizedBox(height: 12),
                TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL'), textInputAction: TextInputAction.next),
                const SizedBox(height: 12),
                TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Link URL (optional)'), textInputAction: TextInputAction.next),
                const SizedBox(height: 12),
                TextField(controller: sortCtrl, decoration: const InputDecoration(labelText: 'Sort Order'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: active,
                  onChanged: (v) => setDialogState(() => active = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isEmpty || imageCtrl.text.isEmpty) return;
                final b = banner_model.AppBanner(
                  id: banner?.id ?? 0,
                  title: titleCtrl.text,
                  imageUrl: imageCtrl.text,
                  linkUrl: linkCtrl.text.isNotEmpty ? linkCtrl.text : null,
                  sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                  active: active,
                );
                if (banner != null) {
                  context.read<BannerManagementProvider>().updateBanner(b);
                } else {
                  context.read<BannerManagementProvider>().addBanner(b);
                }
                Navigator.pop(ctx, true);
              },
              child: Text(banner != null ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBanner(banner_model.AppBanner banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Banner'),
        content: Text('Delete "${banner.title}"?'),
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
      context.read<BannerManagementProvider>().deleteBanner(banner.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BannerManagementProvider>();
    final isDesk = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Banners', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBannerDialog(),
        child: const Icon(Icons.add),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? Center(child: Text('Error: ${prov.error}'))
              : prov.banners.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_carousel_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text('No banners yet', style: GoogleFonts.inter(fontSize: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
                          const SizedBox(height: 8),
                          Text('Tap + to add a banner', style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.38))),
                        ],
                      ),
                    )
                  : isDesk
                      ? _buildDesktop(prov, theme)
                      : _buildMobile(prov, theme),
    );
  }

  Widget _buildDesktop(BannerManagementProvider prov, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Image')),
          DataColumn(label: Text('Link')),
          DataColumn(label: Text('Order')),
          DataColumn(label: Text('Active')),
          DataColumn(label: Text('Actions')),
        ],
        rows: prov.banners.map((b) => DataRow(cells: [
          DataCell(Text(b.title, style: GoogleFonts.inter(fontSize: 13))),
          DataCell(SizedBox(
            width: 80,
            child: Text(b.imageUrl, style: GoogleFonts.inter(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          DataCell(Text(b.linkUrl ?? '-', style: GoogleFonts.inter(fontSize: 11))),
          DataCell(Text('${b.sortOrder}', style: GoogleFonts.inter(fontSize: 13))),
          DataCell(Icon(b.active ? Icons.check_circle : Icons.cancel, color: b.active ? Colors.green : Colors.grey, size: 18)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showBannerDialog(banner: b)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18), color: theme.colorScheme.error, onPressed: () => _deleteBanner(b)),
            ],
          )),
        ])).toList(),
      ),
    );
  }

  Widget _buildMobile(BannerManagementProvider prov, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: prov.banners.length,
      itemBuilder: (_, i) {
        final b = prov.banners[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(b.active ? Icons.check_circle : Icons.cancel, color: b.active ? Colors.green : Colors.grey),
            title: Text(b.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Order: ${b.sortOrder}', style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showBannerDialog(banner: b)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18), color: theme.colorScheme.error, onPressed: () => _deleteBanner(b)),
              ],
            ),
          ),
        );
      },
    );
  }
}
