# Thix Access — Flutter frontend

Squelette initial du frontend Flutter de THIX ACCESS, structuré pour Android et Web. Les intégrations IA, Supabase et l'avatar restent derrière des contrats et sont volontairement laissées en mode prototype.

## Prérequis

- Flutter stable et Dart inclus dans le SDK
- Android Studio / Android SDK pour Android
- Un navigateur compatible pour la cible Web

## Démarrage

```bash
flutter pub get
flutter run -d chrome
# ou choisir un appareil Android connecté
flutter run
```

Pour générer les fichiers de plateforme manquants spécifiques à votre version Flutter (notamment le Gradle Wrapper), depuis la racine :

```bash
flutter create --platforms=android,web .
```

Vérifier ensuite les fichiers Android générés avant de les committer. Aucun secret ni fichier `.env` ne doit être ajouté au dépôt. Voir `docs/FRONTEND_SETUP.md`.
