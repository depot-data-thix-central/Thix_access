// lib/config/env.dart
//
// =============================================================================
// THIX ACCESS — configuration d'environnement (valeurs PUBLIQUES uniquement)
// -----------------------------------------------------------------------------
// §18.4 : AUCUNE clé secrète ne doit être lisible ici. Une valeur passée en
//         --dart-define est compilée dans le binaire et extractible de l'APK.
//         Ce fichier ne lit donc QUE : URL publique, clé publishable Supabase
//         (protégée par RLS), DSN Sentry (public), drapeaux et seuils.
//
// Fourni au build via : flutter run --dart-define-from-file=env/dev.json
//
// Compatibilité : `Env.environment`, `Env.supabaseUrl`, `Env.supabaseAnonKey`
// et `Env.hasSupabaseConfig` conservent leur signature pour ne pas casser
// bootstrap.dart ni config/app_config.dart.
// =============================================================================

import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Environnement d'exécution. Réactive l'enum déclaré mais jamais utilisé
/// dans la version initiale du dépôt.
enum AppEnvironment {
  development,
  staging,
  production;

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;

  static AppEnvironment parse(String? raw) {
    final value = raw?.trim().toLowerCase();
    return AppEnvironment.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppEnvironment.development,
    );
  }
}

enum ConfigIssueSeverity { blocking, warning }

/// Anomalie de configuration. Les anomalies `blocking` font échouer l'assertion
/// en debug ; en release elles sont journalisées et l'app démarre en mode
/// dégradé (§18.9 : signaler, jamais masquer).
@immutable
class ConfigIssue {
  const ConfigIssue(
    this.key,
    this.message, {
    this.severity = ConfigIssueSeverity.blocking,
  });

  final String key;
  final String message;
  final ConfigIssueSeverity severity;

  bool get isBlocking => severity == ConfigIssueSeverity.blocking;

  @override
  String toString() => '${isBlocking ? 'BLOQUANT' : 'ATTENTION'} [$key] $message';
}

class Env {
  const Env._();

  // ---------------------------------------------------------------------------
  // Identité / environnement
  // ---------------------------------------------------------------------------

  /// Conservé en `String` const : `AppConfig.current` en dépend.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get current => AppEnvironment.parse(environment);
  static bool get isProduction => current.isProduction;
  static bool get isDevelopment => current.isDevelopment;
  static bool get isStaging => current.isStaging;

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'THIX ACCESS',
  );

  /// Flavor de build (dev / staging / prod). Doit correspondre au flavor natif.
  static const String appFlavor = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'dev',
  );

  // ---------------------------------------------------------------------------
  // Supabase — backend métier unique (§9, §18.3)
  // ---------------------------------------------------------------------------

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String _publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const String _legacyAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Clé PUBLIQUE destinée au client. La sécurité repose sur RLS, jamais sur
  /// le secret de cette clé.
  static String get supabasePublishableKey =>
      _publishableKey.isNotEmpty ? _publishableKey : _legacyAnonKey;

  /// Alias de compatibilité (bootstrap.dart). Préférer supabasePublishableKey.
  static String get supabaseAnonKey => supabasePublishableKey;

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Deep link d'authentification (magic link / OAuth) — requis par le routeur
  // ---------------------------------------------------------------------------

  static const String authRedirectScheme = String.fromEnvironment(
    'AUTH_REDIRECT_SCHEME',
    defaultValue: 'thixaccess',
  );
  static const String authRedirectHost = String.fromEnvironment(
    'AUTH_REDIRECT_HOST',
    defaultValue: 'login-callback',
  );

  /// Doit être déclarée dans Supabase > Authentication > Redirect URLs,
  /// dans AndroidManifest (intent-filter) et dans ios/Runner/Info.plist.
  static String get authRedirectUrl => '$authRedirectScheme://$authRedirectHost';

  // ---------------------------------------------------------------------------
  // Passerelle IA — l'app ne parle JAMAIS directement à un fournisseur avec
  // une clé longue durée (§10, §18.4).
  // ---------------------------------------------------------------------------

  static const String aiGatewayBaseUrl =
      String.fromEnvironment('AI_GATEWAY_BASE_URL');

  /// Par défaut : les Edge Functions du projet Supabase.
  static String get aiGatewayUrl => aiGatewayBaseUrl.isNotEmpty
      ? aiGatewayBaseUrl
      : (hasSupabaseConfig ? '$supabaseUrl/functions/v1' : '');

  static const int aiTimeoutSeconds =
      int.fromEnvironment('AI_TIMEOUT_SECONDS', defaultValue: 20);

  /// Durée de vie demandée pour un jeton éphémère Realtime/Live.
  /// Courte par principe : une session, des capacités restreintes.
  static const int realtimeTokenTtlSeconds =
      int.fromEnvironment('REALTIME_TOKEN_TTL_SECONDS', defaultValue: 90);

  // ---------------------------------------------------------------------------
  // Seuils de confiance par défaut (§5, §18.9)
  // ---------------------------------------------------------------------------
  // Dart n'expose pas double.fromEnvironment : on transporte des points de
  // base entiers (8000 = 0.80). Ces valeurs sont des DÉFAUTS : la politique
  // effective vient de ai_providers / sign_languages côté backend.

  static const int _acceptBasisPoints =
      int.fromEnvironment('CONFIDENCE_ACCEPT_BP', defaultValue: 8000);
  static const int _abstainBasisPoints =
      int.fromEnvironment('CONFIDENCE_ABSTAIN_BP', defaultValue: 5500);

  /// >= seuil : résultat publié et vocalisé.
  static double get defaultAcceptThreshold => _acceptBasisPoints / 10000;

  /// < seuil : abstention explicite, aucune traduction inventée.
  static double get defaultAbstainThreshold => _abstainBasisPoints / 10000;

  // ---------------------------------------------------------------------------
  // Observabilité / distribution
  // ---------------------------------------------------------------------------

  /// Un DSN Sentry est public par conception (il ne permet que l'envoi).
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static const String otaChannel =
      String.fromEnvironment('OTA_CHANNEL', defaultValue: 'stable');

  static const bool verboseLogs = bool.fromEnvironment('VERBOSE_LOGS');

  // ---------------------------------------------------------------------------
  // Garde anti-secret (§18.4)
  // ---------------------------------------------------------------------------

  /// Préfixes caractéristiques d'une clé qui ne doit JAMAIS vivre dans l'app.
  static const List<String> _forbiddenFragments = <String>[
    'sk-',            // OpenAI
    'service_role',   // Supabase service_role
    'AIza',           // Google API key
    'ghp_',           // GitHub PAT
    '-----BEGIN',     // clé privée PEM
    'Bearer ',
  ];

  /// Valide la configuration. Ne lève jamais : retourne la liste des anomalies.
  static List<ConfigIssue> validate() {
    final issues = <ConfigIssue>[];

    if (AppEnvironment.values.every((e) => e.name != environment.trim())) {
      issues.add(ConfigIssue(
        'APP_ENV',
        'Valeur "$environment" inconnue, repli sur development.',
        severity: ConfigIssueSeverity.warning,
      ));
    }

    if (!hasSupabaseConfig) {
      issues.add(ConfigIssue(
        'SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY',
        isProduction
            ? 'Obligatoires en production : historique, corrections et '
                'journalisation de consommation indisponibles.'
            : 'Absentes : mode local uniquement.',
        severity:
            isProduction ? ConfigIssueSeverity.blocking : ConfigIssueSeverity.warning,
      ));
    }

    if (supabaseUrl.isNotEmpty) {
      final uri = Uri.tryParse(supabaseUrl);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        issues.add(const ConfigIssue('SUPABASE_URL', 'URL invalide.'));
      } else if (uri.scheme != 'https') {
        issues.add(ConfigIssue(
          'SUPABASE_URL',
          'HTTPS obligatoire (§11 : chiffrement des communications).',
          severity: isProduction
              ? ConfigIssueSeverity.blocking
              : ConfigIssueSeverity.warning,
        ));
      }
    }

    for (final fragment in _forbiddenFragments) {
      if (supabasePublishableKey.contains(fragment)) {
        issues.add(ConfigIssue(
          'SUPABASE_PUBLISHABLE_KEY',
          'Ressemble à une clé SECRÈTE ("$fragment"). Retirer immédiatement '
          'du build : toute clé compilée est extractible (§18.4).',
        ));
        break;
      }
    }

    if (aiGatewayBaseUrl.isNotEmpty) {
      final uri = Uri.tryParse(aiGatewayBaseUrl);
      if (uri == null || uri.scheme != 'https') {
        issues.add(const ConfigIssue(
          'AI_GATEWAY_BASE_URL',
          'Doit être une URL HTTPS valide.',
        ));
      }
      if (aiGatewayBaseUrl.contains('key=') ||
          _forbiddenFragments.any(aiGatewayBaseUrl.contains)) {
        issues.add(const ConfigIssue(
          'AI_GATEWAY_BASE_URL',
          'Ne doit contenir aucun secret en query string (§18.4).',
        ));
      }
    }

    if (defaultAbstainThreshold > defaultAcceptThreshold) {
      issues.add(const ConfigIssue(
        'CONFIDENCE_*_BP',
        'Le seuil d\'abstention doit être <= au seuil d\'acceptation.',
      ));
    }

    if (realtimeTokenTtlSeconds > 300) {
      issues.add(const ConfigIssue(
        'REALTIME_TOKEN_TTL_SECONDS',
        'Un jeton éphémère devrait vivre moins de 5 minutes.',
        severity: ConfigIssueSeverity.warning,
      ));
    }

    if (authRedirectScheme.isEmpty || authRedirectHost.isEmpty) {
      issues.add(const ConfigIssue(
        'AUTH_REDIRECT_*',
        'Schéma/hôte de deep link vides : la connexion par lien magique échouera.',
      ));
    }

    return issues;
  }

  /// À appeler au tout début de `bootstrap()`.
  /// En debug : échoue bruyamment. En release : journalise et continue.
  static void assertValid() {
    final issues = validate();
    for (final issue in issues) {
      dev.log(
        issue.toString(),
        name: 'thix.config',
        level: issue.isBlocking ? 1000 : 900,
      );
    }
    assert(
      !issues.any((i) => i.isBlocking),
      'Configuration invalide :\n'
      '${issues.where((i) => i.isBlocking).join('\n')}',
    );
  }

  /// Vue journalisable de la configuration, sans valeur sensible.
  static Map<String, String> describeRedacted() => <String, String>{
        'env': current.name,
        'flavor': appFlavor,
        'supabaseUrl': supabaseUrl.isEmpty ? '(absent)' : supabaseUrl,
        'supabaseKey': _mask(supabasePublishableKey),
        'aiGateway': aiGatewayUrl.isEmpty ? '(absent)' : aiGatewayUrl,
        'authRedirect': authRedirectUrl,
        'accept': defaultAcceptThreshold.toStringAsFixed(2),
        'abstain': defaultAbstainThreshold.toStringAsFixed(2),
        'otaChannel': otaChannel,
        'sentry': sentryDsn.isEmpty ? '(absent)' : 'configuré',
      };

  static String _mask(String value) {
    if (value.isEmpty) return '(absent)';
    final head = value.length <= 6 ? value : value.substring(0, 6);
    return '$head…(${value.length} caractères)';
  }
}
