import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable stat card for the admin dashboard showing an icon, count, and label.
class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color? color;
  final double? trend;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: cardColor),
              ),
              const SizedBox(height: 16),
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                      ),
                    ),
                  ),
                  if (trend != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: trend! >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
