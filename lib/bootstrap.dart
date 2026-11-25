// lib/bootstrap.dart
//
// =============================================================================
// THIX ACCESS — amorçage de l'application
// -----------------------------------------------------------------------------
// Rôle : point d'entrée unique appelé par main.dart. Tout ce qui doit exister
// AVANT le premier widget est initialisé ici, et nulle part ailleurs.
//
// Principes (cahier v1.1) :
//  §11  Aucune donnée personnelle dans les logs : on journalise des NOMS de
//       providers et des TYPES, jamais des valeurs (landmarks, texte reconnu,
//       transcripts, tokens).
//  §18.4 Aucune clé secrète ici. Seules des valeurs publiques via dart-define.
//  §18.9 Une fonctionnalité indisponible est SIGNALÉE, jamais masquée : le
//       StartupReport alimente un bandeau "mode dégradé" dans l'UI.
//  §14  Démarrage NON BLOQUANT : réseau instable => l'app ouvre quand même.
//
// Injection de dépendances :
//  - Ici : `Provider` manuels, car ce sont des singletons d'infrastructure
//    surchargés à la racine (valeurs calculées pendant l'amorçage).
//  - Partout ailleurs (features/) : `@riverpod` / `@Riverpod(keepAlive: true)`
//    avec codegen. Pas de StateProvider / StateNotifierProvider (legacy 3.x).
// =============================================================================

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/env.dart';
import 'config/feature_flags.dart';
import 'thix_access_app.dart';

// =============================================================================
// 1. RAPPORT DE DÉMARRAGE
// =============================================================================

/// État de l'amorçage, exposé à l'UI.
///
/// Une application d'accessibilité ne doit jamais échouer silencieusement :
/// si Supabase est injoignable, l'utilisateur doit le voir, pas le deviner.
@immutable
class StartupReport {
  const StartupReport({
    required this.environment,
    required this.supabaseReady,
    required this.degradedReasons,
    required this.startupDurationMs,
  });

  final AppEnvironment environment;
  final bool supabaseReady;

  /// Messages courts, en français, affichables tels quels à l'utilisateur.
  final List<String> degradedReasons;

  final int startupDurationMs;

  bool get isDegraded => degradedReasons.isNotEmpty;
  bool get isProduction => environment == AppEnvironment.production;

  @override
  String toString() =>
      'StartupReport(env: ${environment.name}, supabase: $supabaseReady, '
      'degraded: $degradedReasons, startupMs: $startupDurationMs)';
}

// =============================================================================
// 2. PROVIDERS D'INFRASTRUCTURE (surchargés à la racine)
// =============================================================================

/// Configuration applicative non secrète.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.current);

/// Environnement typé : réactive l'enum `AppEnvironment` de config/env.dart.
final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  final raw = Env.environment;
  return AppEnvironment.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => AppEnvironment.development,
  );
});

/// Drapeaux de fonctionnalité, résolus à la compilation.
///
/// Tout est à `false` par défaut : une fonctionnalité non validée au PoC
/// (Phase 1) ne peut pas se retrouver active par accident en production.
final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => _flagsFromEnvironment(),
);

/// Rempli pendant l'amorçage. Lire ce provider sans override est une erreur
/// de câblage : on échoue bruyamment plutôt que de renvoyer un faux rapport.
final startupReportProvider = Provider<StartupReport>(
  (ref) => throw StateError(
    'startupReportProvider doit être surchargé dans bootstrap(). '
    'En test : ProviderScope(overrides: [startupReportProvider.overrideWithValue(...)]).',
  ),
);

/// `null` = Supabase non configuré ou injoignable.
///
/// Volontairement nullable : les repositories doivent gérer explicitement le
/// mode local (§9 : Supabase est la source métier, mais pas une dépendance
/// bloquante au démarrage).
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

/// Remplaçable par Sentry / Crashlytics en Phase 6 sans toucher au reste.
final crashReporterProvider =
    Provider<CrashReporter>((ref) => const _DeveloperCrashReporter());

// =============================================================================
// 3. REMONTÉE D'ERREURS
// =============================================================================

/// Contrat unique de remontée d'erreurs.
///
/// Implémentations futures : SentryCrashReporter, CrashlyticsReporter.
/// Règle §11 : ne JAMAIS y faire transiter de média brut, de transcript,
/// de landmark ou de jeton d'authentification.
abstract interface class CrashReporter {
  void capture(
    Object error,
    StackTrace? stack, {
    String? context,
    bool fatal = false,
  });
}

/// Implémentation par défaut : journalisation locale via dart:developer.
/// (`avoid_print` est actif dans analysis_options.yaml.)
class _DeveloperCrashReporter implements CrashReporter {
  const _DeveloperCrashReporter();

  @override
  void capture(
    Object error,
    StackTrace? stack, {
    String? context,
    bool fatal = false,
  }) {
    dev.log(
      fatal ? 'FATAL' : 'ERROR',
      name: 'thix.error${context == null ? '' : '.$context'}',
      error: error,
      stackTrace: stack,
      level: fatal ? 1200 : 1000,
    );
  }
}

/// Observabilité du cycle de vie des providers.
///
/// Riverpod 3 : les méthodes reçoivent un `ProviderObserverContext` (et non
/// plus `provider + container`). On ne journalise QUE l'identité du provider.
final class AppProviderObserver extends ProviderObserver {
  AppProviderObserver();

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (!kDebugMode) return;
    dev.log('+ ${_label(context)}', name: 'thix.riverpod', level: 500);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (!kDebugMode) return;
    dev.log('- ${_label(context)}', name: 'thix.riverpod', level: 500);
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    dev.log(
      'provider en échec : ${_label(context)}',
      name: 'thix.riverpod',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  static String _label(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();
}

// =============================================================================
// 4. AMORÇAGE
// =============================================================================

/// Appelé par `main.dart`. Ne lève jamais : toute étape en échec est consignée
/// dans le rapport de démarrage et l'application s'ouvre quand même.
Future<void> bootstrap() async {
  final watch = Stopwatch()..start();
  final degraded = <String>[];
  const reporter = _DeveloperCrashReporter();

  await runZonedGuarded<Future<void>>(() async {
    // Dans la zone gardée : évite les avertissements de zone discordante.
    WidgetsFlutterBinding.ensureInitialized();

    _installErrorHandlers(reporter);
    _configureErrorWidget();
    _configurePlatform();
    _limitImageCache();

    final environment = _resolveEnvironment();
    final flags = _flagsFromEnvironment();

    SupabaseClient? supabase;
    if (flags.supabase) {
      supabase = await _initSupabase(degraded, reporter);
    } else {
      degraded.add('Backend désactivé — mode local uniquement.');
    }

    if (environment == AppEnvironment.production && supabase == null) {
      dev.log(
        'PRODUCTION sans backend : historique, corrections et '
        'journalisation de consommation indisponibles.',
        name: 'thix.bootstrap',
        level: 1000,
      );
    }

    final report = StartupReport(
      environment: environment,
      supabaseReady: supabase != null,
      degradedReasons: List.unmodifiable(degraded),
      startupDurationMs: watch.elapsedMilliseconds,
    );
    dev.log(report.toString(), name: 'thix.bootstrap', level: 800);

    runApp(
      ProviderScope(
        observers: [AppProviderObserver()],
        retry: _retryPolicy,
        overrides: [
          startupReportProvider.overrideWithValue(report),
          supabaseClientProvider.overrideWithValue(supabase),
          crashReporterProvider.overrideWithValue(reporter),
        ],
        child: const ThixAccessApp(),
      ),
    );

    unawaited(_logFirstFrame(watch));
  }, (error, stack) {
    // Filet de sécurité : erreurs asynchrones hors du pipeline Flutter.
    reporter.capture(error, stack, context: 'zone', fatal: true);
  });
}

// =============================================================================
// 5. ÉTAPES INTERNES
// =============================================================================

void _installErrorHandlers(CrashReporter reporter) {
  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    reporter.capture(
      details.exception,
      details.stack,
      context: 'flutter',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.capture(error, stack, context: 'platform', fatal: true);
    return true; // erreur traitée : ne pas tuer l'isolate
  };
}

/// En release, jamais d'écran rouge : message court et actionnable.
/// L'accessibilité passe avant le confort du développeur.
void _configureErrorWidget() {
  if (!kReleaseMode) return;
  ErrorWidget.builder = (details) => Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFFF7FAFC),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Une erreur est survenue.\nRelancez la conversation.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF1F2933),
                ),
              ),
            ),
          ),
        ),
      );
}

void _configurePlatform() {
  final isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  if (isMobile) {
    // V1 : portrait, cadrage caméra reproductible pour la prise de signes.
    // Le mode paysage (cadrage buste entier) sera évalué au PoC.
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }

  unawaited(SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF7FAFC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  ));
}

/// Plafond mémoire images : caméra + avatar + micro simultanés sur un appareil
/// à 3 Go de RAM ne laissent pas de marge au cache par défaut.
void _limitImageCache() {
  final cache = PaintingBinding.instance.imageCache;
  cache.maximumSizeBytes = 40 << 20; // 40 Mio
  cache.maximumSize = 120;
}

/// Initialise Supabase sans jamais bloquer ni faire échouer le démarrage.
Future<SupabaseClient?> _initSupabase(
  List<String> degraded,
  CrashReporter reporter,
) async {
  if (!Env.hasSupabaseConfig) {
    degraded.add(
      'Backend non configuré — historique et synchronisation désactivés.',
    );
    return null;
  }

  try {
    final supabase = await Supabase.initialize(
      url: Env.supabaseUrl,
      // Clé PUBLIQUE. La sécurité repose sur RLS, jamais sur le secret (§9).
      publishableKey: Env.supabaseAnonKey,
      debug: kDebugMode,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      // Évite de recréer un socket + réautoriser chaque canal à chaque pause
      // (coût réseau et latence en conversation).
      realtimeLifecycleOptions: const RealtimeLifecycleOptions(
        disconnectAfterPause: Duration(minutes: 1),
      ),
    ).timeout(const Duration(seconds: 10));

    return supabase.client;
  } catch (error, stack) {
    reporter.capture(error, stack, context: 'supabase.init');
    degraded.add(
      'Backend injoignable — mode local, nouvelle tentative au prochain écran.',
    );
    return null;
  }
}

/// Riverpod 3 retente par défaut jusqu'à 10 fois (200 ms -> 6,4 s).
/// On borne à 3 essais (200/400/800 ms) : au-delà, l'utilisateur attend devant
/// un écran muet, ce qui contredit l'exigence de fluidité (§8).
///
/// ⚠️ Les providers caméra / micro / permissions doivent désactiver
///    individuellement la retente : `@Riverpod(retry: _neverRetry)`.
Duration? _retryPolicy(int retryCount, Object error) {
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}

AppEnvironment _resolveEnvironment() => AppEnvironment.values.firstWhere(
      (e) => e.name == Env.environment,
      orElse: () => AppEnvironment.development,
    );

FeatureFlags _flagsFromEnvironment() => const FeatureFlags(
      signRecognition: bool.fromEnvironment('FF_SIGN_RECOGNITION'),
      speechRecognition: bool.fromEnvironment('FF_SPEECH_RECOGNITION'),
      avatar: bool.fromEnvironment('FF_AVATAR'),
      supabase: bool.fromEnvironment('FF_SUPABASE', defaultValue: true),
      devTools: bool.fromEnvironment('FF_DEVTOOLS'),
    );

Future<void> _logFirstFrame(Stopwatch watch) async {
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  dev.log(
    'first_frame_ms=${watch.elapsedMilliseconds}',
    name: 'thix.perf',
    level: 800,
  );
}
