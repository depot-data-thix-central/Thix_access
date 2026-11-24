# Frontend Flutter — guide de démarrage

## Portée

Ce dépôt contient le squelette de l'application cliente THIX ACCESS. Il fournit une navigation minimale, un thème, des contrats de fournisseurs IA, des écrans d'accueil et de conversation, ainsi que les dossiers Android et Web.

Les fournisseurs réels, la reconnaissance de langue des signes, Supabase, les autorisations et l'avatar ne sont pas encore connectés. Les fonctions de traduction ne doivent pas être présentées comme opérationnelles tant qu'elles n'ont pas été validées pour la langue des signes cible.

## Commandes

```bash
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Pour Android : connecter un appareil ou démarrer un émulateur, puis `flutter run`. Après installation/configuration d'un SDK Flutter différent, vous pouvez régénérer les fichiers de plateforme :

```bash
flutter create --platforms=android,web .
```

Examiner le diff avant de conserver cette génération, car elle peut remplacer des fichiers de plateforme.

## Configuration

Les valeurs non secrètes peuvent être passées via `--dart-define`, par exemple :

```bash
flutter run --dart-define=APP_ENV=development --dart-define=SUPABASE_URL=https://example.supabase.co
```

Ne jamais placer de clé secrète de fournisseur IA dans l'application Flutter. Les appels nécessitant une clé doivent passer par un backend sécurisé. `SUPABASE_ANON_KEY` est une clé publique destinée au client et doit être protégée par les politiques RLS côté Supabase.

## Git

Le dossier `.git` est la métadonnée interne du dépôt GitHub existant : il n'est pas versionné comme fichier. Le fichier `.gitignore` ajouté à la racine exclut les artefacts Flutter, Android, IDE et les fichiers locaux.
