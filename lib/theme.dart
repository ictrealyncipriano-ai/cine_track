import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFFFFC107);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: Color(0xFF161B22),
        error: Colors.redAccent,
      ),
      cardColor: const Color(0xFF161B22),
      dividerColor: Colors.white12,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        titleTextStyle: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF161B22),
        selectedItemColor: primary,
        unselectedItemColor: Colors.white38,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF161B22),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white54,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF161B22),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF161B22),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.white24),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          return Colors.white54;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.white24;
        }),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF0D1117),
        indicatorColor: primary.withValues(alpha: 0.2),
        labelType: NavigationRailLabelType.all,
        minWidth: 72,
        groupAlignment: -1.0,
        selectedLabelTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        unselectedLabelTextStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
      ),
      tooltipTheme: TooltipThemeData(
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0EFED),
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: Color(0xFFFFFFFF),
        error: Colors.redAccent,
      ),
      cardColor: const Color(0xFFFAFAFA),
      dividerColor: Colors.black12,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        foregroundColor: const Color(0xFF2C2C2C),
        titleTextStyle: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF2C2C2C)),
        iconTheme: const IconThemeData(color: Color(0xFF2C2C2C)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFFF8F8F8),
        selectedItemColor: primary,
        unselectedItemColor: Colors.black38,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: const Color(0xFF2C2C2C),
        displayColor: const Color(0xFF2C2C2C),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black54,
          side: const BorderSide(color: Colors.black26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF333333),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8E8E8),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2C2C2C)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.black26),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2C2C2C)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.black54;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.black26;
        }),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFFF8F8F8),
        indicatorColor: primary.withValues(alpha: 0.2),
        labelType: NavigationRailLabelType.all,
        minWidth: 72,
        groupAlignment: -1.0,
        selectedLabelTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2C2C2C)),
        unselectedLabelTextStyle: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
      ),
      tooltipTheme: TooltipThemeData(
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: const Color(0xFF555555),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
