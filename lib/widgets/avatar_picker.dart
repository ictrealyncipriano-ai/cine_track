import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class AvatarPicker extends StatelessWidget {
  final void Function(String base64, String mimeType) onPicked;

  const AvatarPicker({super.key, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Change Profile Picture',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            _option(
              context,
              icon: Icons.camera_alt,
              label: 'Take Photo',
              onTap: () => _pick(context, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _option(
              context,
              icon: Icons.photo_library,
              label: 'Choose from Gallery',
              onTap: () => _pick(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            _option(
              context,
              icon: Icons.delete_outline,
              label: 'Remove Current Photo',
              color: Theme.of(context).colorScheme.error,
              onTap: () {
                Navigator.pop(context);
                onPicked('', '');
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, {required IconData icon, required String label, VoidCallback? onTap, Color? color}) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        label: Text(label, style: GoogleFonts.inter(color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: (color ?? theme.colorScheme.onSurface).withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64 = base64Encode(bytes);
      final mimeType = picked.name.endsWith('.png') ? 'image/png'
          : picked.name.endsWith('.webp') ? 'image/webp'
          : picked.name.endsWith('.gif') ? 'image/gif'
          : 'image/jpeg';

      onPicked(base64, mimeType);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }
}
