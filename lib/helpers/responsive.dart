import 'package:flutter/material.dart';

/// Breakpoints for responsive layout adaptation.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double large = 1600;
}

/// Runtime screen-size classification.
enum ScreenType { mobile, tablet, desktop, largeDesktop }

/// Shared responsive helpers used across all screens.
class Responsive {
  Responsive._();

  // ── Screen type queries ──────────────────────────────────────

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context) => width(context) < Breakpoints.mobile;
  static bool isTablet(BuildContext context) =>
      width(context) >= Breakpoints.mobile && width(context) < Breakpoints.tablet;
  static bool isDesktop(BuildContext context) =>
      width(context) >= Breakpoints.tablet;
  static bool isWide(BuildContext context) =>
      width(context) >= Breakpoints.desktop;
  static bool isLarge(BuildContext context) =>
      width(context) >= Breakpoints.large;

  static ScreenType screenType(BuildContext context) {
    final w = width(context);
    if (w >= Breakpoints.large) return ScreenType.largeDesktop;
    if (w >= Breakpoints.desktop) return ScreenType.desktop;
    if (w >= Breakpoints.tablet) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  // ── Layout helpers ───────────────────────────────────────────

  /// Returns a value tuned to mobile vs wider screens.
  static T value<T>(BuildContext context, {required T mobile, required T desktop}) =>
      isDesktop(context) ? desktop : mobile;

  /// Horizontal padding that scales with screen width.
  static double horizontalPadding(BuildContext context) {
    if (isLarge(context)) return 48;
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }

  /// Responsive font size – scales up on wide screens.
  static double font(BuildContext context, double mobileSize) {
    if (isLarge(context)) return mobileSize * 1.3;
    if (isWide(context)) return mobileSize * 1.15;
    return mobileSize;
  }

  /// Responsive grid column count based on available width.
  /// Define an `itemWidth` to approximate how many columns fit.
  static int gridColumns(BuildContext context, {double itemWidth = 180}) {
    final available = width(context) - horizontalPadding(context) * 2;
    final count = (available / itemWidth).floor();
    if (isLarge(context)) return count.clamp(4, 8);
    if (isWide(context)) return count.clamp(3, 6);
    if (isTablet(context)) return count.clamp(3, 5);
    return count.clamp(2, 4);
  }

  // ── Predefined column counts for specific contexts ───────────

  static int movieGridColumns(BuildContext context) {
    if (isLarge(context)) return 7;
    if (isDesktop(context)) return 5;
    if (isTablet(context)) return 4;
    return 3;
  }

  static int compactGridColumns(BuildContext context) {
    if (isLarge(context)) return 5;
    if (isWide(context)) return 4;
    return 3;
  }
}

/// Centers content on wide screens and constrains max width.
/// On mobile the constraints are no-ops so the child fills available space.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}
