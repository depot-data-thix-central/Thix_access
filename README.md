# Thix_access
thix_access
CAHIER DES CHARGES FONCTIONNEL ET TECHNIQUE

THIX ACCESS

Application mobile intelligente d'assistance à la communication par intelligence artificielle

Version : 1.0
Plateforme principale : Android
Technologie principale : Flutter / Dart
Nature du projet : Application mobile basée sur l'intelligence artificielle
Périmètre : Version 1 – Communication entre personnes sourdes ou malentendantes et personnes entendantes
Éditeur du projet : À définir

---

1. PRÉSENTATION GÉNÉRALE DU PROJET

1.1. Contexte

La communication représente encore un obstacle important pour les personnes sourdes ou malentendantes dans leurs interactions quotidiennes avec les personnes entendantes.

Les échanges nécessitent souvent un interprète, des messages écrits ou des solutions qui ne permettent pas une communication naturelle et instantanée.

THIX ACCESS est un projet d'application mobile qui ambitionne de réduire cette barrière grâce à l'intelligence artificielle, à la reconnaissance des gestes, au traitement de la voix et à un avatar numérique animé en 3D.

L'application doit permettre à deux personnes ne partageant pas le même mode de communication d'échanger naturellement, sans devoir nécessairement maîtriser la langue de l'autre.

1.2. Vision du projet

Développer un assistant intelligent capable de fonctionner comme un interprète numérique en temps réel.

L'application doit comprendre les gestes d'une personne sourde et les convertir en parole audible. Inversement, elle doit comprendre la parole d'une personne entendante et la traduire en langue des signes à travers un personnage animé en 3D.

1.3. Objectifs principaux

- Faciliter la communication entre personnes sourdes et entendantes.
- Réduire la dépendance aux interprètes humains pour les échanges simples.
- Traduire les gestes en texte et en voix.
- Traduire la parole en langue des signes animée.
- Permettre des conversations aussi naturelles que possible.
- Construire une intelligence artificielle qui pourra être améliorée progressivement.
- Préparer une architecture permettant d'ajouter d'autres langues des signes.

---

2. PÉRIMÈTRE FONCTIONNEL

La première version comprend deux fonctionnalités majeures :

A. Signes vers parole : la personne sourde effectue des gestes devant la caméra. L'application les reconnaît et les transforme en texte et en voix.

B. Parole vers signes : la personne entendante parle devant le téléphone. L'application reconnaît sa voix, traduit le message et le reproduit à travers un avatar 3D.

Les deux fonctionnalités doivent pouvoir fonctionner pendant une même conversation, avec une gestion intelligente des flux audio et vidéo.

---

3. INTERFACE UTILISATEUR

3.1. Écran d'accueil

L'interface doit être moderne, minimaliste, intuitive et accessible.

Elle doit s'inspirer des interfaces conversationnelles modernes telles que Gemini et ChatGPT.

Éléments attendus :

- Logo THIX ACCESS.
- Présentation de l'assistant.
- Mascotte ou avatar numérique.
- Bouton principal « Démarrer une conversation ».
- Accès à l'historique des conversations.
- Accès aux paramètres.
- Sélection de la langue des signes.

L'écran d'accueil doit rester épuré. L'avatar peut apparaître discrètement, sans animation permanente.

3.2. Écran de conversation

Après activation de la conversation, l'utilisateur accède à un espace dédié à l'interprétation.

Cet écran doit comporter :

- Avatar 3D animé.
- Indicateur d'écoute du microphone.
- Indicateur de reconnaissance des gestes.
- Aperçu ou retour de la caméra.
- Texte reconnu.
- Bouton d'activation et de désactivation du microphone.
- Bouton de pause.
- Bouton de reprise.
- Bouton de fin de conversation.
- Possibilité de corriger une phrase mal reconnue.

L'interface doit présenter clairement l'état de chaque fonction : écoute, reconnaissance, traduction, animation et lecture vocale.

---

4. FONCTIONNALITÉ 1 : RECONNAISSANCE DES GESTES

4.1. Description

La caméra avant du téléphone doit permettre de détecter les mouvements effectués par une personne sourde utilisant la langue des signes sélectionnée.

Le système doit analyser :

- Les positions des mains.
- Les mouvements des doigts.
- Les déplacements des mains.
- La position des bras.
- Les expressions faciales.
- Les mouvements du corps.
- Le contexte et l'enchaînement des signes.

4.2. Fonctionnement

1. L'utilisateur démarre une conversation.
2. La caméra avant s'active après autorisation.
3. MediaPipe analyse les mouvements et extrait les informations corporelles pertinentes.
4. Le moteur de reconnaissance interprète les séquences de gestes.
5. Le système transforme les signes reconnus en texte.
6. Le moteur de synthèse vocale prononce le texte.
7. Le résultat apparaît également à l'écran.

4.3. Fonctionnement automatique

La reconnaissance doit être continue pendant la conversation.

L'utilisateur ne doit pas appuyer sur un bouton pour chaque geste ou chaque phrase.

Le système doit détecter les débuts et les fins de séquences gestuelles afin d'éviter les traductions répétitives ou incomplètes.

4.4. Gestion des incertitudes

Lorsque le système n'arrive pas à interpréter correctement un geste, il doit :

- Éviter d'inventer une traduction.
- Signaler que le geste n'est pas reconnu.
- Demander une répétition si nécessaire.
- Permettre une correction manuelle.
- Enregistrer, avec consentement, les exemples destinés à l'amélioration du modèle.

---

5. FONCTIONNALITÉ 2 : RECONNAISSANCE VOCALE

5.1. Description

L'application doit permettre à une personne entendante de communiquer oralement avec une personne sourde.

Le microphone capte la voix de la personne entendante lorsque le mode écoute est activé.

5.2. Fonctionnement

1. La personne entendante active le microphone.
2. Le système capte la parole.
3. Le moteur Speech-to-Text convertit la parole en texte.
4. Le moteur de traduction prépare une représentation adaptée à la langue des signes sélectionnée.
5. L'avatar 3D reproduit les gestes correspondants.
6. La personne sourde comprend le message à travers l'animation.

5.3. Commandes audio

L'application doit disposer d'un bouton permettant de contrôler l'écoute.

Fonctions :

- Activer le microphone.
- Désactiver le microphone.
- Mettre l'écoute en pause.
- Reprendre l'écoute.
- Afficher le texte reconnu.
- Signaler les erreurs de reconnaissance.

La reconnaissance des gestes doit pouvoir continuer indépendamment de l'état du microphone, selon les capacités du téléphone.

---

6. FONCTIONNALITÉ 3 : AVATAR NUMÉRIQUE 3D

6.1. Objectif

L'avatar constitue l'un des éléments centraux de THIX ACCESS.

Il doit fonctionner comme un interprète numérique capable de reproduire les gestes de la langue des signes.

6.2. Caractéristiques

- Personnage humain numérique en 3D.
- Apparence accueillante et professionnelle.
- Mouvements naturels des mains et des doigts.
- Animation des bras et du corps.
- Expressions faciales adaptées.
- Synchronisation des mouvements avec les phrases traduites.
- Possibilité d'améliorer les animations au fil des versions.

6.3. Comportement

Lorsque l'application est inactive, l'avatar reste dans un état neutre.

Lorsque la personne entendante parle, l'avatar commence à signer le message traduit.

Il doit pouvoir interrompre une animation, reprendre ou afficher une nouvelle traduction.

6.4. Technologies envisageables

- Unity avec intégration Flutter.
- Modèles 3D au format compatible, notamment glTF/GLB.
- Système d'animation squelettique.
- Blend shapes pour les expressions faciales.
- Bibliothèque d'animations de langue des signes.
- Moteur de synchronisation des gestes.

L'avatar ne doit pas simplement produire des mouvements décoratifs. Ses animations doivent correspondre à une véritable traduction linguistique.

---

7. INTELLIGENCE ARTIFICIELLE ET APPRENTISSAGE

7.1. Architecture IA

Le projet doit utiliser plusieurs composants spécialisés plutôt qu'une seule intelligence artificielle pour toutes les opérations.

7.2. Technologies proposées

MediaPipe

- Détection des mains.
- Détection du corps.
- Détection des points du visage.
- Extraction des mouvements.

TensorFlow / TensorFlow Lite

- Entraînement des modèles personnalisés.
- Classification des gestes.
- Reconnaissance des séquences gestuelles.
- Exécution de modèles sur le téléphone.

Gemini ou OpenAI

- Compréhension linguistique.
- Assistance conversationnelle.
- Interprétation de textes.
- Aide à la normalisation des phrases.

Speech-to-Text

- Reconnaissance vocale.
- Conversion de la parole en texte.

Text-to-Speech

- Production de la voix.
- Lecture automatique des phrases reconnues.

7.3. Apprentissage progressif

L'application doit être conçue pour permettre l'amélioration progressive de son intelligence artificielle.

Lorsqu'un geste n'est pas reconnu ou qu'une traduction est incorrecte :

1. Le système signale l'incertitude.
2. L'utilisateur peut proposer une correction.
3. Un exemple peut être enregistré avec son consentement.
4. Les données sont envoyées dans un espace sécurisé.
5. Les exemples sont vérifiés et annotés.
6. Un nouveau modèle est entraîné.
7. Le modèle est testé.
8. Après validation, il peut être distribué aux utilisateurs.

L'application ne doit pas modifier automatiquement son modèle de production sans contrôle.

7.4. Objectif à long terme

Construire progressivement une intelligence artificielle propriétaire, entraînée à partir de données représentatives de la langue des signes choisie.

---

8. TEMPS RÉEL ET SYNCHRONISATION

La conversation doit être aussi fluide que possible.

Le système doit gérer simultanément :

- La caméra.
- La reconnaissance gestuelle.
- Le microphone.
- La reconnaissance vocale.
- La traduction.
- L'animation 3D.
- La synthèse vocale.

Gestion des interruptions

Lorsqu'une nouvelle personne commence à parler, le système doit pouvoir interrompre ou mettre en attente une animation précédente.

Il doit également éviter que la voix synthétique de l'application soit reconnue comme une nouvelle intervention humaine.

La reconnaissance des gestes et la reconnaissance vocale doivent avoir des états indépendants.

Communication réseau

L'application doit privilégier les traitements locaux pour la détection des mouvements et les fonctions qui peuvent être exécutées sans connexion.

Les API distantes seront utilisées pour les opérations nécessitant davantage de puissance de calcul.

Agora peut être intégré si une communication audio ou vidéo distante est nécessaire, mais il n'est pas obligatoire pour une conversation entre deux personnes présentes devant le même téléphone.

---

9. BACKEND ET GESTION DES DONNÉES

Supabase

Supabase pourra gérer :

- Les comptes utilisateurs.
- L'authentification.
- Les préférences linguistiques.
- L'historique des conversations si l'utilisateur l'autorise.
- Les corrections de traduction.
- Les exemples de gestes consentis.
- Les versions des modèles IA.
- Les paramètres de l'application.

Backend personnalisé

Un backend sécurisé sera prévu pour :

- Gérer les appels aux API IA.
- Protéger les clés secrètes.
- Gérer les modèles de reconnaissance.
- Organiser les données d'entraînement.
- Distribuer les nouvelles versions des modèles.
- Centraliser les statistiques techniques.

Les clés des fournisseurs IA ne doivent jamais être directement exposées dans le code Flutter.

---

10. SÉCURITÉ ET CONFIDENTIALITÉ

L'application doit respecter les principes suivants :

- Demander les autorisations caméra et microphone.
- Informer l'utilisateur des traitements réalisés.
- Chiffrer les communications avec les services distants.
- Limiter la conservation des données personnelles.
- Permettre de désactiver l'enregistrement des conversations.
- Demander un consentement distinct pour l'utilisation des données à des fins d'entraînement.
- Permettre la suppression des données personnelles.
- Sécuriser les accès au backend.
- Ne pas transmettre systématiquement les vidéos brutes aux serveurs.

Les vidéos et données biométriques éventuelles doivent faire l'objet de protections particulières.

---

11. ARCHITECTURE TECHNIQUE DU PROJET

Application mobile

Flutter / Dart.

Reconnaissance des gestes

MediaPipe + modèle personnalisé TensorFlow Lite.

Intelligence linguistique

Gemini ou OpenAI, selon les tests de qualité, de coût et de latence.

Reconnaissance vocale

Service Speech-to-Text compatible avec les langues vocales ciblées.

Synthèse vocale

Service Text-to-Speech.

Avatar

Moteur 3D et animations spécialisées.

Base de données

Supabase PostgreSQL.

Backend

API sécurisée, fonctions serveur et gestion des modèles IA.

Temps réel

Traitement local et flux asynchrones. Agora reste une option pour les besoins de communication distante.

---

12. EXIGENCES NON FONCTIONNELLES

L'application doit répondre aux exigences suivantes :

- Interface rapide et accessible.
- Compatibilité avec les smartphones Android ciblés.
- Gestion de la consommation de batterie.
- Optimisation de l'utilisation de la caméra.
- Faible latence entre le geste, sa reconnaissance et la voix.
- Traductions fiables et compréhensibles.
- Gestion des connexions Internet instables.
- Possibilité d'exécuter certaines fonctions hors ligne.
- Architecture modulaire et évolutive.
- Compatibilité future avec iOS.

La précision et la latence devront être mesurées sur des jeux de tests représentatifs, plutôt que considérées comme garanties avant validation.

---

13. PHASAGE DU DÉVELOPPEMENT

Phase 1 : Prototype fonctionnel

- Création de l'interface Flutter.
- Activation de la caméra et du microphone.
- Intégration de MediaPipe.
- Reconnaissance d'un premier ensemble de signes.
- Conversion des signes en texte et en voix.
- Reconnaissance vocale.
- Première traduction vocale vers des animations.

Phase 2 : Avatar 3D

- Création du personnage.
- Modélisation des mains.
- Développement des animations.
- Synchronisation avec les traductions.
- Optimisation des performances.

Phase 3 : Intelligence artificielle

- Constitution du jeu de données.
- Entraînement des modèles.
- Évaluation des traductions.
- Système de correction.
- Pipeline d'amélioration des modèles.

Phase 4 : Version bêta

- Tests avec des personnes sourdes.
- Tests avec des personnes entendantes.
- Corrections techniques.
- Optimisation de la batterie et de la latence.
- Tests de sécurité.

Phase 5 : Publication

- Préparation de la version stable.
- Tests de compatibilité.
- Préparation des fiches de store.
- Publication sur Google Play.
- Suivi des performances et retours utilisateurs.

---

14. CRITÈRES DE VALIDATION

La première version sera considérée comme fonctionnellement validée lorsque :

1. L'utilisateur peut démarrer et arrêter une conversation.
2. La caméra détecte correctement les informations gestuelles nécessaires.
3. Le système reconnaît un ensemble de signes défini.
4. Les signes reconnus sont convertis en texte.
5. Le texte peut être prononcé automatiquement.
6. La voix peut être transformée en texte.
7. Le texte peut être traduit en animations de langue des signes.
8. L'avatar reproduit les animations correctement.
9. Les deux sens de communication peuvent être utilisés dans une même session.
10. Le microphone peut être contrôlé indépendamment.
11. Les erreurs de reconnaissance peuvent être signalées et corrigées.
12. Les données personnelles sont traitées conformément aux règles de confidentialité.

---

15. ÉVOLUTION FUTURE : MODE PERSONNES MALVOYANTES

Cette fonctionnalité ne fait pas partie de la première version.

Elle constituera une deuxième phase indépendante, avec notamment :

- Reconnaissance des objets.
- Lecture des textes présents dans l'environnement.
- Description vocale de l'environnement.
- Détection des obstacles.
- Assistance à la navigation.
- Alertes sonores.
- Reconnaissance des situations potentiellement dangereuses.

Un module spécifique de perception et de navigation devra être développé. Il ne devra pas être considéré comme un simple prolongement de la reconnaissance des signes.

---

16. LIVRABLES ATTENDUS

Le développement devra fournir :

- Code source complet Flutter.
- Architecture technique documentée.
- Backend et API documentés.
- Modèles IA et procédures d'entraînement.
- Avatar 3D et bibliothèque d'animations.
- Base de données et scripts nécessaires.
- Documentation d'installation.
- Documentation de déploiement.
- Version APK de test.
- Version Android prête à publier.
- Rapport de tests fonctionnels et techniques.

---

17. CONCLUSION

THIX ACCESS ambitionne de devenir un outil technologique d'inclusion permettant aux personnes sourdes ou malentendantes de communiquer plus facilement avec leur entourage.

Le projet repose sur une combinaison de vision artificielle, d'intelligence artificielle, de reconnaissance vocale, de synthèse vocale et d'animation 3D.

Sa conception doit privilégier la modularité, l'accessibilité, la confidentialité et l'amélioration continue.

La priorité de la première version est de fournir un interprète numérique capable de traduire les gestes en parole et la parole en langue des signes, avec une expérience de conversation fluide et naturelle.
