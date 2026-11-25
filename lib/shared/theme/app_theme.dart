// lib/shared/theme/app_theme.dart
//
// =============================================================================
// THIX ACCESS — design system (§3 : moderne, minimaliste, accessible)
// -----------------------------------------------------------------------------
// Contraintes d'accessibilité appliquées ICI, pas dans les écrans :
//  * cible tactile minimale 48 dp (moteur de sélection, tremblement, gants) ;
//  * contraste texte/fond >= 4.5:1 en clair comme en sombre ;
//  * aucune information portée par la couleur seule -> toujours icône + texte ;
//  * les tokens d'état servent le pipeline (§3.2 : écouter, reconnaître,
//    traduire, animer, lire) et resteront lisibles en daltonisme.
//
// Compatibilité : AppTheme.light reste exposé (thix_access_app.dart l'utilise).
// =============================================================================

import 'package:flutter/material.dart';

/// Jetons d'espacement. Aucune valeur magique dans les écrans.
class AppSpacing {
  const AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Cible tactile minimale recommandée (accessibilité motrice).
  static const double minTapTarget = 48;

  /// Largeur de lecture maximale : évite les lignes trop longues sur tablette.
  static const double contentMaxWidth = 640;
}

class AppRadii {
  const AppRadii._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius field = BorderRadius.all(Radius.circular(sm));
}

class AppDurations {
  const AppDurations._();
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);

  /// Respecter MediaQuery.disableAnimations : toute animation doit être
  /// contournable (sensibilité vestibulaire, §3 interface accessible).
  static Duration of(BuildContext context, Duration value) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : value;
}

/// Couleurs sémantiques d'état du pipeline de communication.
@immutable
class AppStatusTokens extends ThemeExtension<AppStatusTokens> {
  const AppStatusTokens({
    required this.idle,
    required this.listening,
    required this.processing,
    required this.success,
    required this.warning,
    required this.danger,
    required this.onStatus,
  });

  final Color idle;
  final Color listening;
  final Color processing;
  final Color success;
  final Color warning;
  final Color danger;
  final Color onStatus;

  static const AppStatusTokens light = AppStatusTokens(
    idle: Color(0xFF6B7A88),
    listening: Color(0xFF0B6E99),
    processing: Color(0xFF6B4E9B),
    success: Color(0xFF1B7F4B),
    warning: Color(0xFF8A5A00),
    danger: Color(0xFFB3261E),
    onStatus: Color(0xFFFFFFFF),
  );

  static const AppStatusTokens dark = AppStatusTokens(
    idle: Color(0xFF9AA7B2),
    listening: Color(0xFF57B6E0),
    processing: Color(0xFFB69AE8),
    success: Color(0xFF57C98A),
    warning: Color(0xFFE0B252),
    danger: Color(0xFFF2857C),
    onStatus: Color(0xFF0E1519),
  );

  @override
  AppStatusTokens copyWith({
    Color? idle,
    Color? listening,
    Color? processing,
    Color? success,
    Color? warning,
    Color? danger,
    Color? onStatus,
  }) =>
      AppStatusTokens(
        idle: idle ?? this.idle,
        listening: listening ?? this.listening,
        processing: processing ?? this.processing,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        onStatus: onStatus ?? this.onStatus,
      );

  @override
  AppStatusTokens lerp(ThemeExtension<AppStatusTokens>? other, double t) {
    if (other is! AppStatusTokens) return this;
    return AppStatusTokens(
      idle: Color.lerp(idle, other.idle, t)!,
      listening: Color.lerp(listening, other.listening, t)!,
      processing: Color.lerp(processing, other.processing, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onStatus: Color.lerp(onStatus, other.onStatus, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  /// Couleur de marque historique du dépôt, conservée.
  static const Color brandSeed = Color(0xFF176B87);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  /// Accès aux tokens d'état avec repli : jamais de null dans un écran.
  static AppStatusTokens statusOf(BuildContext context) =>
      Theme.of(context).extension<AppStatusTokens>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? AppStatusTokens.dark
          : AppStatusTokens.light);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: brightness,
    );
    final status = isLight ? AppStatusTokens.light : AppStatusTokens.dark;

    final baseText = isLight
        ? Typography.material2021(colorScheme: scheme).black
        : Typography.material2021(colorScheme: scheme).white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isLight ? const Color(0xFFF7FAFC) : const Color(0xFF0E1519),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: <ThemeExtension<dynamic>>[status],

      // Corps de texte légèrement agrandi : lecture rapide en situation
      // de conversation, souvent debout, en extérieur.
      textTheme: baseText.copyWith(
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontSize: 28,
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
        bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
        labelLarge: baseText.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget + 4),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.field),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.field),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTapTarget, AppSpacing.minTapTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.field),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSpacing.minTapTarget),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.field),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            Radius.circular(AppRadii.lg),
          ),
        ),
        constraints: BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 15),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.field),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.xl,
      ),

      listTileTheme: const ListTileThemeData(
        minVerticalPadding: AppSpacing.md,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
