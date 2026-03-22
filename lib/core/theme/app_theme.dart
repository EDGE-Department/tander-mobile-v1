import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Material 3 theme matching tander-web's warm aesthetic.
///
/// All visual values reference design-system tokens from [AppColors],
/// [AppTypography], and [AppRadius]. No hardcoded colors or sizes.
///
/// Touch targets are elder-friendly: primary buttons are 56 px tall,
/// text buttons are at least 44 px (WCAG 2.2 minimum).
abstract final class AppTheme {
  /// Light theme for the Tander app.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // ── Color scheme ──────────────────────────────────────────
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.card,
          error: AppColors.danger,
          brightness: Brightness.light,
        ),

        // ── Scaffold ──────────────────────────────────────────────
        scaffoldBackgroundColor: AppColors.canvas,

        // ── AppBar ────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: AppTypography.h3,
          iconTheme: const IconThemeData(
            color: AppColors.textStrong,
            size: 24,
          ),
        ),

        // ── Cards ─────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          margin: EdgeInsets.zero,
        ),

        // ── Elevated buttons — primary orange, 56 px elder-friendly ─
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textInverse,
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
            textStyle: AppTypography.label.copyWith(
              color: AppColors.textInverse,
            ),
            elevation: 0,
          ),
        ),

        // ── Outlined buttons ──────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
            side: const BorderSide(color: AppColors.primary),
          ),
        ),

        // ── Text buttons ──────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        // ── Input decoration — card background, warm border ───────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderSm,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderSm,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderSm,
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderSm,
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
          errorStyle: AppTypography.caption.copyWith(color: AppColors.danger),
        ),

        // ── Bottom navigation ─────────────────────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // ── Divider ───────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 0,
        ),

        // ── Snackbar ──────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),

        // ── Bottom sheet ──────────────────────────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
          ),
          showDragHandle: true,
          dragHandleColor: AppColors.border,
        ),

        // ── Dialog ────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
          elevation: 0,
        ),
      );
}
