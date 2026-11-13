import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admivida/common/constants/app_colors.dart';

/// 🌌 Custom transition: Premium Combined Effect (Slide + Fade)
/// Simulates fluid physics of high-end operating systems.
class PremiumPageTransitionBuilder extends PageTransitionsBuilder {
  const PremiumPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    // Position animation (Enters from the right with an eased curve)
    final slideTween = Tween<Offset>(
      begin: const Offset(0.08, 0.0), // Subtle lateral push
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.fastOutSlowIn));

    // Opacity animation (Smooth fade)
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut));

    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
    );
  }
}

/// ⚡ Subtle micro-fade transition for Desktop & Web so view switches feel fluid and instantaneous
class DesktopFadeTransitionBuilder extends PageTransitionsBuilder {
  const DesktopFadeTransitionBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic));
    final slideTween = Tween<Offset>(
      begin: const Offset(0.0, 0.012),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: animation.drive(fadeTween),
      child: SlideTransition(
        position: animation.drive(slideTween),
        child: child,
      ),
    );
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.kPrimary500,
      scaffoldBackgroundColor: AppColors.kBackgroundColor,
      dividerColor: AppColors.kNeutral200,
      splashFactory: InkSparkle.splashFactory,

      // 🔄 Intelligent global transitions control (Native navigation / Named Routes)
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: kIsWeb ? const DesktopFadeTransitionBuilder() : const PremiumPageTransitionBuilder(),
          TargetPlatform.iOS: kIsWeb ? const DesktopFadeTransitionBuilder() : const PremiumPageTransitionBuilder(),
          TargetPlatform.windows: const DesktopFadeTransitionBuilder(),
          TargetPlatform.macOS: const DesktopFadeTransitionBuilder(),
          TargetPlatform.linux: const DesktopFadeTransitionBuilder(),
        },
      ),

      // 🎨 Material 3 Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.kPrimary500,
        secondary: AppColors.kSecondaryColor,
        tertiary: AppColors.kTertiaryColor,
        surface: AppColors.kWhiteColor,
        error: AppColors.kError,
        onPrimary: AppColors.kWhiteColor,
        onSecondary: AppColors.kWhiteColor,
        onSurface: AppColors.kNeutral900,
      ),

      // ⚡ Top Bar Configuration (AppBar)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.kWhiteColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.kNeutral800, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.kNeutral800, size: 22),
        titleTextStyle: GoogleFonts.poppins(color: AppColors.kNeutral900, fontSize: 18, fontWeight: FontWeight.w600),
      ),

      // 📝 Scaled Typography with Poppins aligned to the correct neutrals
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
        headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.kNeutral900),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.kNeutral900),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.kNeutral900),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.kNeutral800),
        titleSmall: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.kNeutral700),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.kNeutral900),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.kNeutral800),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.kNeutral600),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.kPrimary500),
      ),

      // 🔲 Stylized Text Fields (Automatic TextFormFields for Login/Register)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kWhiteColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: GoogleFonts.poppins(color: AppColors.kNeutral500, fontSize: 13.5),
        hintStyle: GoogleFonts.poppins(color: AppColors.kNeutral400, fontSize: 13.5),
        errorStyle: GoogleFonts.poppins(color: AppColors.kError, fontSize: 12, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kNeutral200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kNeutral200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kPrimary500, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kError, width: 1.8),
        ),
      ),

      // 🪟 Dialog & BottomSheet Themes
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.kWhiteColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.kWhiteColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),

      // 🔘 Primary Buttons Configuration (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kPrimary500,
          foregroundColor: AppColors.kWhiteColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // 🔄 Secondary Bordered Buttons Configuration (OutlinedButton)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kPrimary500,
          side: const BorderSide(color: AppColors.kPrimary500, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // 📦 App Containers and Cards Configuration (Card)
      // cardTheme: CardTheme(
      //   color: AppColors.kWhiteColor,
      //   elevation: 0,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16),
      //     side: const BorderSide(color: AppColors.kNeutral200, width: 1),
      //   ),
      //   margin: EdgeInsets.zero,
      // ),

      // 📊 Data Tables Theme (POS lists and transaction balances)
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.kNeutral50),
        headingTextStyle: GoogleFonts.poppins(color: AppColors.kNeutral800, fontWeight: FontWeight.w600, fontSize: 14),
        dataTextStyle: GoogleFonts.poppins(color: AppColors.kNeutral900, fontSize: 14),
        horizontalMargin: 16,
      ),

      // 📅 Date Pickers and Schedules Theme
      datePickerTheme: DatePickerThemeData(
        headerBackgroundColor: AppColors.kPrimary500,
        headerForegroundColor: AppColors.kWhiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
