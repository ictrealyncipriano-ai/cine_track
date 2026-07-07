import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../helpers/responsive.dart';
import '../providers/auth_provider.dart';

/// Adaptive app shell that switches between a [NavigationRail] (desktop)
/// and a [BottomNavigationBar] (mobile) depending on screen width.
///
/// Wraps the [body] in an [IndexedStack] to preserve tab state.
class ResponsiveShell extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<Widget> bodies;
  final List<NavigationDestinationData> destinations;

  const ResponsiveShell({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.bodies,
    required this.destinations,
  });

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isDesktop(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Row(
        children: [
          // ── Desktop: NavigationRail sidebar ──
          if (isWide)
            NavigationRail(
              selectedIndex: widget.currentIndex,
              onDestinationSelected: widget.onTabSelected,
              labelType: NavigationRailLabelType.all,
              minWidth: 72,
              leading: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Icon(
                    Icons.movie_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CineTrack',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                ],
              ),
              trailing: auth.isAuthenticated
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: auth.user?.avatarUrl != null &&
                                auth.user!.avatarUrl!.isNotEmpty
                            ? (auth.user!.avatarUrl!.startsWith('data:')
                                ? MemoryImage(
                                    base64Decode(
                                      auth.user!.avatarUrl!.split(',').length >= 2
                                          ? auth.user!.avatarUrl!.split(',')[1]
                                          : '',
                                    ),
                                  )
                                : NetworkImage(auth.user!.avatarUrl!) as ImageProvider)
                            : null,
                        child: auth.user?.avatarUrl == null ||
                                auth.user!.avatarUrl!.isEmpty
                            ? Icon(Icons.person, size: 20)
                            : null,
                      ),
                    )
                  : const SizedBox.shrink(),
              destinations: widget.destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label, style: GoogleFonts.inter(fontSize: 12)),
                      ))
                  .toList(),
            ),

          // ── Content area ──
          Expanded(
            child: IndexedStack(
              index: widget.currentIndex,
              children: widget.bodies,
            ),
          ),
        ],
      ),

      // ── Mobile: BottomNavigationBar ──
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: widget.currentIndex,
              onTap: widget.onTabSelected,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.54),
              items: widget.destinations
                  .map((d) => BottomNavigationBarItem(
                        icon: d.icon,
                        activeIcon: d.selectedIcon ?? d.icon,
                        label: d.label,
                      ))
                  .toList(),
            ),
    );
  }
}

/// Data class for navigation destination items.
class NavigationDestinationData {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;

  const NavigationDestinationData({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}
