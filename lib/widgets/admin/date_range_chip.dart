import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DateRangeChip extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const DateRangeChip({super.key, required this.selected, required this.onSelected});

  static const options = ['7d', '14d', '30d', '90d'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: options.map((opt) {
        final active = selected == opt;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelected(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                opt,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
