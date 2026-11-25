// lib/shared/router/app_router.dart
//
// =============================================================================
// THIX ACCESS — navigation déclarative (remplace le Navigator manuel : P0-4)
// -----------------------------------------------------------------------------
// Pourquoi ce remplacement :
//  * l'ancien AppRouter était un Navigator imbriqué dans MaterialApp.home :
//    toute route inconnue retombait silencieusement sur l'accueil ;
//  * aucun deep link possible -> lien magique Supabase inutilisable (§9) ;
//  * back Android et URL web incohérents.
//
// Ce fichier expose un PROVIDER (infrastructure), pas un widget.
// Comme bootstrap.dart, il utilise `Provider` manuel : les singletons
// d'infrastructure ne passent pas par le codegen. Les features, elles,
// utilisent @riverpod.
//
// NOTE d'architecture : featureFlagsProvider et supabaseClientProvider sont
// encore déclarés dans bootstrap.dart. À terme, les déplacer vers
// shared/providers/app_providers.dart pour supprimer l'import circulaire
// (légal en Dart, mais peu explicite).
// =============================================================================

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart' show featureFlagsProvider, supabaseClientProvider;
import '../../config/feature_flags.dart';
import '../../features/conversation/presentation/conversation_page.dart';
import '../../features/home/presentation/home_page.dart';

// =============================================================================
// 1. CHEMINS ET NOMS DE ROUTES (source de vérité unique)
// =============================================================================

class RoutePaths {
  const RoutePaths._();

  static const String home = '/';
  static const String conversation = '/conversation';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String language = '/settings/language';
  static const String voice = '/settings/voice';
  static const String privacy = '/settings/privacy';
  static const String consent = '/consent';
  static const String signIn = '/sign-in';
  static const String authCallback = '/auth/callback';
  static const String devTools = '/devtools';
}

class RouteNames {
  const RouteNames._();

  static const String home = 'home';
  static const String conversation = 'conversation';
  static const String history = 'history';
  static const String settings = 'settings';
  static const String language = 'settings-language';
  static const String voice = 'settings-voice';
  static const String privacy = 'settings-privacy';
  static const String consent = 'consent';
  static const String signIn = 'sign-in';
  static const String authCallback = 'auth-callback';
  static const String devTools = 'devtools';
}

/// Routes accessibles sans compte.
///
/// La conversation reste publique : le traitement local doit fonctionner sans
/// authentification (§11 traitement local privilégié, contexte réseau RDC).
/// Seul l'historique serveur exige une session.
const Set<String> _publicPaths = <String>{
  RoutePaths.home,
  RoutePaths.conversation,
  RoutePaths.consent,
  RoutePaths.settings,
  RoutePaths.language,
  RoutePaths.voice,
  RoutePaths.privacy,
  RoutePaths.signIn,
  RoutePaths.authCallback,
};

// =============================================================================
// 2. PROVIDER DU ROUTEUR
// =============================================================================

final appRouterProvider = Provider<GoRouter>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  final supabase = ref.watch(supabaseClientProvider);

  final authRefresh = _AuthRefreshNotifier(supabase);

  final router = GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authRefresh,
    observers: <NavigatorObserver>[_RouteLogger()],
    redirect: (context, state) => _redirect(
      state: state,
      flags: flags,
      supabase: supabase,
    ),
    errorBuilder: (context, state) => _RouteNotFoundPage(
      location: state.uri.toString(),
    ),
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RoutePaths.conversation,
        name: RouteNames.conversation,
        builder: (context, state) => const ConversationPage(),
      ),
      GoRoute(
        path: RoutePaths.history,
        name: RouteNames.history,
        builder: (context, state) => const _PendingPage(
          title: 'Historique',
          description:
              'Lecture des conversations enregistrées dans Supabase, selon '
              'votre autorisation. À connecter.',
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const _PendingPage(
          title: 'Paramètres',
          description:
              'Langue des signes, voix, vitesse de l\'avatar, confidentialité. '
              'À connecter.',
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'language',
            name: RouteNames.language,
            builder: (context, state) => const _PendingPage(
              title: 'Langue des signes',
              description:
                  'Seules les langues dont le lexique et les animations sont '
                  'validés peuvent être sélectionnées. À connecter.',
            ),
          ),
          GoRoute(
            path: 'voice',
            name: RouteNames.voice,
            builder: (context, state) => const _PendingPage(
              title: 'Voix',
              description: 'Choix de la voix et du débit de lecture. À connecter.',
            ),
          ),
          GoRoute(
            path: 'privacy',
            name: RouteNames.privacy,
            builder: (context, state) => const _PendingPage(
              title: 'Confidentialité',
              description:
                  'Consentements, conservation, export et suppression des '
                  'données. À connecter.',
            ),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.consent,
        name: RouteNames.consent,
        builder: (context, state) => const _PendingPage(
          title: 'Consentements',
          description:
              'Autorisations caméra/micro et consentement distinct pour la '
              'contribution de données. À connecter.',
        ),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        name: RouteNames.signIn,
        builder: (context, state) => const _SignInPlaceholderPage(),
      ),
      // Cible du deep link Supabase (thixaccess://login-callback).
      // supabase_flutter traite le jeton ; le routeur ne fait qu'accueillir
      // l'atterrissage puis redirige dès que la session existe.
      GoRoute(
        path: RoutePaths.authCallback,
        name: RouteNames.authCallback,
        builder: (context, state) => const _AuthCallbackPage(),
      ),
      GoRoute(
        path: RoutePaths.devTools,
        name: RouteNames.devTools,
        builder: (context, state) => const _PendingPage(
          title: 'Outils de développement',
          description:
              'Banc de latence, overlay des points de repère, sélection du '
              'fournisseur IA. Réservé aux builds de diagnostic.',
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authRefresh.dispose();
  });

  return router;
});

// =============================================================================
// 3. GARDE DE NAVIGATION
// =============================================================================

String? _redirect({
  required GoRouterState state,
  required FeatureFlags flags,
  required SupabaseClient? supabase,
}) {
  final location = state.matchedLocation;

  // 1. Fonctionnalité non validée : inaccessible, même par URL forcée.
  if (location == RoutePaths.devTools && !flags.devTools) {
    return RoutePaths.home;
  }

  // 2. Mode local (backend absent ou injoignable) : aucune exigence de session.
  //    L'application reste utilisable ; l'UI signale le mode dégradé.
  if (supabase == null) return null;

  final isSignedIn = supabase.auth.currentSession != null;

  // 3. Retour de lien magique / OAuth : la session est établie, on rentre.
  if (location == RoutePaths.authCallback && isSignedIn) {
    return RoutePaths.home;
  }

  // 4. Route protégée sans session.
  if (!isSignedIn && !_publicPaths.contains(location)) {
    return RoutePaths.signIn;
  }

  // 5. Déjà connecté : inutile de réafficher la connexion.
  if (isSignedIn && location == RoutePaths.signIn) {
    return RoutePaths.home;
  }

  return null;
}

/// Pont entre le flux d'authentification Supabase et go_router.
final class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(SupabaseClient? client) {
    if (client == null) return;
    _subscription = client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  StreamSubscription<AuthState>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

/// Journalise la navigation. Aucune donnée personnelle : uniquement des noms
/// de routes (§11).
final class _RouteLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('push', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('pop', route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log('replace', newRoute);
  }

  void _log(String action, Route<dynamic>? route) {
    if (!kDebugMode) return;
    dev.log(
      '$action ${route?.settings.name ?? route?.settings.arguments ?? '?'}',
      name: 'thix.router',
      level: 500,
    );
  }
}

// =============================================================================
// 4. ÉCRANS TECHNIQUES (honnêtes : rien n'est présenté comme fonctionnel)
// =============================================================================

class _PendingPage extends StatelessWidget {
  const _PendingPage({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.construction_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => context.goNamed(RouteNames.home),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour à l\'accueil'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _SignInPlaceholderPage extends StatelessWidget {
  const _SignInPlaceholderPage();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Connexion')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Connexion Supabase à connecter. Elle sert uniquement à '
                      'l\'historique, aux corrections et aux préférences '
                      'synchronisées.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.goNamed(RouteNames.home),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continuer sans compte'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _AuthCallbackPage extends StatelessWidget {
  const _AuthCallbackPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Finalisation de la connexion…'),
            ],
          ),
        ),
      );
}

class _RouteNotFoundPage extends StatelessWidget {
  const _RouteNotFoundPage({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Écran introuvable')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.explore_off_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun écran ne correspond à « $location ».',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.goNamed(RouteNames.home),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Revenir à l\'accueil'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
