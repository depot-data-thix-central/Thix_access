// lib/core/ai/contracts/ai_contracts.dart
//
// =============================================================================
// THIX ACCESS — contrats de la couche IA (source de vérité unique)
// -----------------------------------------------------------------------------
// Remplace les 5 fichiers de core/ai/contracts/ de la version initiale, dont
// les signatures ne permettaient pas de tenir le cahier des charges :
//   * aucun identifiant de fournisseur ni capacité -> §18.5 inapplicable ;
//   * Translation sans glose -> §6 (grammaire) non représentable ;
//   * aucun état d'abstention -> §5 / §18.9 non tenable ;
//   * UsageReporter(provider, units) -> ai_usage_logs (§9) non alimentable ;
//   * recognize() sans langue ni segment -> pipeline caméra non branchable.
//
// RÈGLES
//  1. Ce fichier ne dépend d'AUCUN fournisseur, d'AUCUN plugin, d'AUCUN accès
//     réseau. Il est testable sans appareil.
//  2. Aucune clé secrète n'apparaît dans un contrat. Un fournisseur reçoit au
//     mieux un jeton éphémère émis par le backend (§18.4).
//  3. Une incertitude se REPRÉSENTE, elle ne se contourne pas : les
//     constructeurs nommés imposent les invariants (§18.9).
//  4. Pas de codegen ici : les contrats doivent rester stables et compilables
//     sans build_runner.
// =============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

// =============================================================================
// 1. CAPACITÉS ET IDENTITÉ DES FOURNISSEURS (§18.5)
// =============================================================================

/// Ce qu'un fournisseur sait faire. Une capacité = une brique remplaçable.
enum AiCapability {
  speechToText,
  textToSpeech,
  realtimeVoice,
  spokenToGloss,
  glossToSpoken,
  signRecognition,
  fingerspelling,
  landmarkDetection,
}

enum AiProviderKind {
  /// Modèle exécuté sur le téléphone : latence faible, coût nul, hors ligne.
  onDevice,

  /// API REST appelée via la passerelle backend.
  cloudRest,

  /// Session temps réel (WebSocket) ouverte avec un jeton éphémère.
  cloudRealtime,

  /// SDK d'un éditeur spécialisé (reconnaissance ou avatar).
  vendorSdk,
}

/// Miroir applicatif de la table `ai_providers` (§9).
///
/// `secretRef` est le NOM d'un secret détenu par le backend, jamais sa valeur.
@immutable
class AiProviderDescriptor {
  const AiProviderDescriptor({
    required this.code,
    required this.displayName,
    required this.kind,
    required this.capabilities,
    this.model,
    this.supportedSignLanguages = const <String>{},
    this.supportedSpokenLocales = const <String>{},
    this.priority = 100,
    this.isEnabled = true,
    this.requiresNetwork = true,
    this.secretRef,
    this.unitCost,
    this.costUnit,
  });

  /// Identifiant stable, ex. `google_stt_v2`, `on_device_tts`, `fake_stt`.
  final String code;
  final String displayName;
  final AiProviderKind kind;
  final Set<AiCapability> capabilities;

  /// Version/modèle exact : indispensable pour comparer deux fournisseurs.
  final String? model;

  /// Codes de langue des signes réellement couverts. Vide = non applicable.
  final Set<String> supportedSignLanguages;

  /// Locales vocales couvertes, ex. `fr-FR`, `fr-CD`.
  final Set<String> supportedSpokenLocales;

  /// Plus petit = prioritaire.
  final int priority;
  final bool isEnabled;
  final bool requiresNetwork;
  final String? secretRef;
  final double? unitCost;
  final String? costUnit;

  bool get isOnDevice => kind == AiProviderKind.onDevice;

  bool supports(
    AiCapability capability, {
    String? signLanguageCode,
    String? spokenLocale,
  }) {
    if (!isEnabled || !capabilities.contains(capability)) return false;
    if (signLanguageCode != null &&
        supportedSignLanguages.isNotEmpty &&
        !supportedSignLanguages.contains(signLanguageCode)) {
      return false;
    }
    if (spokenLocale != null &&
        supportedSpokenLocales.isNotEmpty &&
        !supportedSpokenLocales.contains(spokenLocale)) {
      return false;
    }
    return true;
  }

  AiProviderDescriptor disabled() => AiProviderDescriptor(
        code: code,
        displayName: displayName,
        kind: kind,
        capabilities: capabilities,
        model: model,
        supportedSignLanguages: supportedSignLanguages,
        supportedSpokenLocales: supportedSpokenLocales,
        priority: priority,
        isEnabled: false,
        requiresNetwork: requiresNetwork,
        secretRef: secretRef,
        unitCost: unitCost,
        costUnit: costUnit,
      );
}

/// Tout fournisseur IA expose son identité : sans cela, ni repli, ni
/// journalisation de coût, ni remplacement à chaud ne sont possibles.
abstract interface class AiProvider {
  AiProviderDescriptor get descriptor;

  /// Préparation (chargement de modèle, ouverture de canal). Idempotent.
  Future<void> initialize();

  /// Libération des ressources natives. Idempotent.
  Future<void> dispose();
}

// =============================================================================
// 2. CONFIANCE ET POLITIQUE D'ABSTENTION (§5, §18.9)
// =============================================================================

/// Confiance normalisée. Remplace `models/confidence.dart` dont le seuil 0.8
/// était codé en dur.
@immutable
class Confidence implements Comparable<Confidence> {
  const Confidence(this.value)
      : assert(value >= 0.0 && value <= 1.0, 'Confiance hors [0,1].');

  static const Confidence none = Confidence(0);
  static const Confidence certain = Confidence(1);

  final double value;

  @override
  int compareTo(Confidence other) => value.compareTo(other.value);

  bool operator >=(Confidence other) => value >= other.value;
  bool operator <(Confidence other) => value < other.value;

  @override
  bool operator ==(Object other) =>
      other is Confidence && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toStringAsFixed(3);
}

enum ConfidenceDecision {
  /// Publié et vocalisé automatiquement.
  accepted,

  /// Affiché comme incertain, PAS de vocalisation automatique.
  uncertain,

  /// Aucune traduction produite : on demande une répétition ou une correction.
  abstained,
}

/// Politique de décision. Les valeurs viennent du backend (par langue et par
/// fournisseur) ; `Env` ne fournit que des défauts.
@immutable
class ConfidencePolicy {
  const ConfidencePolicy({
    this.accept = 0.80,
    this.abstain = 0.55,
    this.maxAlternatives = 3,
  })  : assert(accept >= 0 && accept <= 1),
        assert(abstain >= 0 && abstain <= 1),
        assert(abstain <= accept, 'abstain doit être <= accept');

  final double accept;
  final double abstain;
  final int maxAlternatives;

  ConfidenceDecision decide(Confidence confidence) {
    if (confidence.value >= accept) return ConfidenceDecision.accepted;
    if (confidence.value < abstain) return ConfidenceDecision.abstained;
    return ConfidenceDecision.uncertain;
  }

  bool get allowsAutoSpeech => true;

  @override
  String toString() =>
      'ConfidencePolicy(accept: $accept, abstain: $abstain)';
}

// =============================================================================
// 3. PIVOT LINGUISTIQUE : LA GLOSE (§6, §18.6)
// =============================================================================

/// Une unité de langue des signes. `id` est la clé du lexique validé.
@immutable
class Gloss {
  const Gloss({
    required this.id,
    required this.label,
    this.confidence = Confidence.certain,
    this.isFingerspelled = false,
    this.variant,
    this.durationMs,
  });

  /// Identifiant canonique dans `sign_lexicon` / `avatar_animations.gloss`.
  final String id;

  /// Libellé lisible (debug, sous-titres).
  final String label;

  final Confidence confidence;

  /// Épellation (dactylologie) : repli légitime pour un mot hors lexique.
  /// Jamais un geste inventé.
  final bool isFingerspelled;

  /// Variante régionale du signe.
  final String? variant;

  final int? durationMs;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
        'confidence': confidence.value,
        'fingerspelled': isFingerspelled,
        if (variant != null) 'variant': variant,
        if (durationMs != null) 'duration_ms': durationMs,
      };
}

/// Marqueurs non manuels : sans eux, une suite de gestes n'est pas une phrase
/// en langue des signes (§7 : « pas de mouvements décoratifs »).
@immutable
class NonManualMarkers {
  const NonManualMarkers({
    this.eyebrows,
    this.mouth,
    this.head,
    this.gaze,
    this.torso,
  });

  static const NonManualMarkers neutral = NonManualMarkers();

  final String? eyebrows; // ex. raised, furrowed
  final String? mouth; // ex. mm, oo, puffed
  final String? head; // ex. tilt, nod, shake
  final String? gaze;
  final String? torso;

  bool get isNeutral =>
      eyebrows == null &&
      mouth == null &&
      head == null &&
      gaze == null &&
      torso == null;

  Map<String, Object?> toJson() => <String, Object?>{
        if (eyebrows != null) 'eyebrows': eyebrows,
        if (mouth != null) 'mouth': mouth,
        if (head != null) 'head': head,
        if (gaze != null) 'gaze': gaze,
        if (torso != null) 'torso': torso,
      };
}

/// Placement spatial d'un référent (la grammaire des langues des signes est
/// spatiale : une traduction mot-à-mot la perd).
@immutable
class SpatialReference {
  const SpatialReference({required this.entity, required this.locus});

  final String entity;
  final String locus; // ex. left, right, center, forward

  Map<String, Object?> toJson() =>
      <String, Object?>{'entity': entity, 'locus': locus};
}

/// Représentation pivot entre reconnaissance, traduction et avatar.
/// Sérialisée dans `translations.target_gloss` (jsonb, §9).
@immutable
class GlossSentence {
  const GlossSentence({
    required this.signLanguageCode,
    required this.glosses,
    this.nonManual = NonManualMarkers.neutral,
    this.spatialReferences = const <SpatialReference>[],
    this.confidence = Confidence.none,
    this.backTranslation,
    this.unknownTokens = const <String>[],
    this.lexiconVersion,
  });

  final String signLanguageCode;
  final List<Gloss> glosses;
  final NonManualMarkers nonManual;
  final List<SpatialReference> spatialReferences;
  final Confidence confidence;

  /// Retour en français pour contrôle humain et journalisation.
  final String? backTranslation;

  /// Mots fautés en dactylologie faute de signe validé.
  final List<String> unknownTokens;

  final String? lexiconVersion;

  bool get isEmpty => glosses.isEmpty;
  bool get hasFingerspelling =>
      unknownTokens.isNotEmpty || glosses.any((g) => g.isFingerspelled);

  /// Durée totale estimée, pour l'ordonnancement de l'avatar.
  int get estimatedDurationMs =>
      glosses.fold<int>(0, (sum, g) => sum + (g.durationMs ?? 600));

  Map<String, Object?> toJson() => <String, Object?>{
        'sign_language': signLanguageCode,
        'glosses': glosses.map((g) => g.toJson()).toList(),
        'nmm': nonManual.toJson(),
        'spatial_refs': spatialReferences.map((r) => r.toJson()).toList(),
        'confidence': confidence.value,
        if (backTranslation != null) 'back_translation': backTranslation,
        if (unknownTokens.isNotEmpty) 'unknown_tokens': unknownTokens,
        if (lexiconVersion != null) 'lexicon_version': lexiconVersion,
      };
}

/// Vocabulaire autorisé. Un traducteur ne peut produire que ces gloses :
/// c'est la barrière technique contre l'invention de signes (§18.6).
@immutable
class GlossLexicon {
  const GlossLexicon({
    required this.signLanguageCode,
    required this.version,
    required this.glossIds,
  });

  final String signLanguageCode;
  final String version;
  final Set<String> glossIds;

  bool contains(String glossId) => glossIds.contains(glossId);

  /// Retourne les gloses hors lexique : elles doivent être rejetées ou
  /// converties en dactylologie, jamais animées telles quelles.
  List<String> unsupported(List<Gloss> glosses) => glosses
      .where((g) => !g.isFingerspelled && !contains(g.id))
      .map((g) => g.id)
      .toList(growable: false);
}

// =============================================================================
// 4. ENTRÉES / SORTIES VOCALES (§6, §8)
// =============================================================================

@immutable
class AudioChunk {
  const AudioChunk({
    required this.pcm16,
    required this.timestampMs,
    this.sampleRateHz = 16000,
    this.channels = 1,
  });

  final Uint8List pcm16;
  final int timestampMs;
  final int sampleRateHz;
  final int channels;
}

@immutable
class SttConfig {
  const SttConfig({
    required this.locale,
    this.interimResults = true,
    this.automaticPunctuation = true,
    this.maxAlternatives = 1,
    this.profanityFilter = false,
  });

  final String locale;
  final bool interimResults;
  final bool automaticPunctuation;
  final int maxAlternatives;
  final bool profanityFilter;
}

/// Résultat partiel ou final. Les partiels ne doivent JAMAIS déclencher une
/// traduction ni une animation : seul `isFinal` fait autorité.
@immutable
class TranscriptChunk {
  const TranscriptChunk({
    required this.text,
    required this.locale,
    required this.isFinal,
    required this.providerCode,
    this.confidence = Confidence.none,
    this.audioPositionMs,
  });

  final String text;
  final String locale;
  final bool isFinal;
  final String providerCode;
  final Confidence confidence;
  final int? audioPositionMs;

  bool get isEmpty => text.trim().isEmpty;
}

@immutable
class VoiceConfig {
  const VoiceConfig({
    required this.locale,
    this.voiceId,
    this.speakingRate = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
  });

  final String locale;
  final String? voiceId;
  final double speakingRate;
  final double pitch;
  final double volume;
}

/// États de lecture exposés au garde d'écho : le micro doit être mis en
/// sourdine pendant `speaking` (§8 : éviter l'auto-écoute de la voix générée).
enum TtsPlaybackState { idle, speaking, paused, completed, failed }

@immutable
class TtsPlaybackEvent {
  const TtsPlaybackEvent({
    required this.state,
    required this.providerCode,
    this.messageId,
    this.positionMs,
    this.errorCode,
  });

  final TtsPlaybackState state;
  final String providerCode;
  final String? messageId;
  final int? positionMs;
  final String? errorCode;

  bool get isSpeaking => state == TtsPlaybackState.speaking;
}

@immutable
class Utterance {
  const Utterance({
    required this.text,
    required this.locale,
    this.confidence = Confidence.certain,
    this.messageId,
  });

  final String text;
  final String locale;
  final Confidence confidence;
  final String? messageId;

  bool get isEmpty => text.trim().isEmpty;
}

// =============================================================================
// 5. RECONNAISSANCE DE SIGNES (§5)
// =============================================================================

@immutable
class LandmarkPoint {
  const LandmarkPoint(this.x, this.y, this.z, {this.visibility = 1.0});

  final double x;
  final double y;
  final double z;
  final double visibility;
}

/// Trame de points de repère. Ce n'est PAS une image : aucune vidéo brute
/// n'est nécessaire au traitement (§11).
@immutable
class LandmarkFrame {
  const LandmarkFrame({
    required this.timestampMs,
    this.leftHand = const <LandmarkPoint>[],
    this.rightHand = const <LandmarkPoint>[],
    this.pose = const <LandmarkPoint>[],
    this.face = const <LandmarkPoint>[],
  });

  final int timestampMs;
  final List<LandmarkPoint> leftHand;
  final List<LandmarkPoint> rightHand;
  final List<LandmarkPoint> pose;
  final List<LandmarkPoint> face;

  bool get hasHands => leftHand.isNotEmpty || rightHand.isNotEmpty;
}

/// Portion temporelle délimitée par le segmenteur (début/fin de signe).
@immutable
class SignSegment {
  const SignSegment({
    required this.id,
    required this.frames,
    required this.startedAtMs,
    required this.endedAtMs,
    this.quality = Confidence.certain,
  });

  final int id;
  final List<LandmarkFrame> frames;
  final int startedAtMs;
  final int endedAtMs;

  /// Qualité de capture (cadrage, luminosité, occultation des mains).
  final Confidence quality;

  int get durationMs => endedAtMs - startedAtMs;
  bool get isEmpty => frames.isEmpty;
}

enum RecognitionOutcome { recognized, uncertain, abstained }

@immutable
class SignAlternative {
  const SignAlternative({required this.label, required this.confidence});

  final String label;
  final Confidence confidence;
}

/// Résultat de reconnaissance.
///
/// Invariant §18.9 : une hypothèse `abstained` ne porte AUCUNE traduction.
/// Le constructeur nommé le garantit, l'assertion le vérifie en debug.
@immutable
class SignHypothesis {
  const SignHypothesis.recognized({
    required this.signLanguageCode,
    required this.providerCode,
    required this.segmentId,
    required this.confidence,
    required this.spokenText,
    this.glosses,
    this.alternatives = const <SignAlternative>[],
    this.latencyMs,
  })  : outcome = RecognitionOutcome.recognized,
        abstentionReason = null,
        assert(spokenText != '', 'Une hypothèse reconnue doit porter un texte.');

  const SignHypothesis.uncertain({
    required this.signLanguageCode,
    required this.providerCode,
    required this.segmentId,
    required this.confidence,
    required this.spokenText,
    this.glosses,
    this.alternatives = const <SignAlternative>[],
    this.latencyMs,
  }) : outcome = RecognitionOutcome.uncertain,
       abstentionReason = null;

  const SignHypothesis.abstained({
    required this.signLanguageCode,
    required this.providerCode,
    required this.segmentId,
    required this.reason,
    this.confidence = Confidence.none,
    this.alternatives = const <SignAlternative>[],
    this.latencyMs,
  })  : outcome = RecognitionOutcome.abstained,
        spokenText = null,
        glosses = null,
        abstentionReason = reason;

  final String signLanguageCode;
  final String providerCode;
  final int segmentId;
  final RecognitionOutcome outcome;
  final Confidence confidence;

  /// Texte à afficher et, si accepté, à vocaliser. Null si abstention.
  final String? spokenText;
  final GlossSentence? glosses;
  final List<SignAlternative> alternatives;
  final String? abstentionReason;
  final int? latencyMs;

  bool get isAbstained => outcome == RecognitionOutcome.abstained;
  bool get hasTranslation => spokenText != null && spokenText!.isNotEmpty;

  /// Décision finale : la politique tranche, pas le fournisseur.
  bool shouldSpeak(ConfidencePolicy policy) =>
      hasTranslation && policy.decide(confidence) == ConfidenceDecision.accepted;
}

// =============================================================================
// 6. SESSION TEMPS RÉEL (§4, §18.4)
// =============================================================================

/// Jeton émis par la passerelle backend. Le client ne détient jamais de clé
/// longue durée : configuration de session imposée côté serveur.
@immutable
class RealtimeSessionTicket {
  const RealtimeSessionTicket({
    required this.endpoint,
    required this.ephemeralToken,
    required this.expiresAt,
    required this.providerCode,
    this.sessionConfig = const <String, Object?>{},
  });

  final Uri endpoint;
  final String ephemeralToken;
  final DateTime expiresAt;
  final String providerCode;
  final Map<String, Object?> sessionConfig;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

@immutable
class RealtimeSessionConfig {
  const RealtimeSessionConfig({
    required this.spokenLocale,
    required this.capabilities,
    this.signLanguageCode,
    this.conversationId,
  });

  final String spokenLocale;
  final Set<AiCapability> capabilities;
  final String? signLanguageCode;
  final String? conversationId;
}

// =============================================================================
// 7. JOURNALISATION DE CONSOMMATION (§9 : ai_usage_logs, §10)
// =============================================================================

enum UsageStatus { ok, failed, timeout, rateLimited, aborted, skipped }

enum UsageUnit { audioMillisecond, character, token, request, frame }

/// Événement de consommation.
///
/// L'app envoie `providerCode` ; la passerelle résout `provider_id` et écrit la
/// ligne avec le rôle service. Le client ne peut donc pas falsifier ses coûts.
@immutable
class UsageEvent {
  const UsageEvent({
    required this.providerCode,
    required this.capability,
    required this.feature,
    required this.units,
    required this.unit,
    required this.latencyMs,
    required this.status,
    required this.onDevice,
    this.model,
    this.conversationId,
    this.messageId,
    this.costEstimate,
    this.currency = 'USD',
    this.errorCode,
    this.occurredAt,
  });

  final String providerCode;
  final String? model;
  final AiCapability capability;

  /// Fonctionnalité appelante, ex. `conversation.sign_to_voice`.
  final String feature;

  final double units;
  final UsageUnit unit;
  final int latencyMs;
  final UsageStatus status;
  final bool onDevice;
  final String? conversationId;
  final String? messageId;
  final double? costEstimate;
  final String currency;
  final String? errorCode;
  final DateTime? occurredAt;

  bool get isFailure => status != UsageStatus.ok && status != UsageStatus.skipped;

  Map<String, Object?> toJson() => <String, Object?>{
        'provider_code': providerCode,
        if (model != null) 'model': model,
        'capability': capability.name,
        'feature': feature,
        'units': units,
        'unit': unit.name,
        'latency_ms': latencyMs,
        'status': status.name,
        'on_device': onDevice,
        if (conversationId != null) 'conversation_id': conversationId,
        if (messageId != null) 'message_id': messageId,
        if (costEstimate != null) 'cost_est': costEstimate,
        if (costEstimate != null) 'currency': currency,
        if (errorCode != null) 'error_code': errorCode,
        'occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
      };
}

/// Destination des événements. Implémentations : file locale + envoi différé
/// vers l'Edge Function `ai-usage`, ou sink nul en mode local.
abstract interface class UsageSink {
  Future<void> record(UsageEvent event);
}

// =============================================================================
// 8. ÉCHECS TYPIÉS (repli, coupe-circuit, §18.5)
// =============================================================================

sealed class AiFailure implements Exception {
  const AiFailure(
    this.message, {
    this.providerCode,
    this.cause,
    this.retryable = false,
  });

  final String message;
  final String? providerCode;
  final Object? cause;
  final bool retryable;

  /// Un échec qui doit ouvrir le coupe-circuit du fournisseur.
  bool get tripsBreaker => retryable;

  @override
  String toString() =>
      '$runtimeType(${providerCode ?? '?'}): $message${retryable ? ' [retryable]' : ''}';
}

/// Réseau ou service indisponible : on retente, puis on bascule.
final class AiUnavailable extends AiFailure {
  const AiUnavailable(super.message, {super.providerCode, super.cause})
      : super(retryable: true);
}

final class AiTimeout extends AiFailure {
  const AiTimeout(super.message, {super.providerCode, super.cause})
      : super(retryable: true);
}

/// Quota atteint : on bascule immédiatement, sans marteler le fournisseur.
final class AiRateLimited extends AiFailure {
  const AiRateLimited(
    super.message, {
    super.providerCode,
    this.retryAfter,
  });

  final Duration? retryAfter;
}

/// Jeton épuisé ou autorisation refusée : inutile de retenter tel quel.
final class AiUnauthorized extends AiFailure {
  const AiUnauthorized(super.message, {super.providerCode, super.cause});
}

/// Réponse inexploitable : JSON invalide, gloses hors lexique.
/// Ne doit JAMAIS être convertie en traduction approximative (§18.9).
final class AiInvalidResponse extends AiFailure {
  const AiInvalidResponse(super.message, {super.providerCode, super.cause});
}

final class AiUnsupportedLanguage extends AiFailure {
  const AiUnsupportedLanguage(
    this.languageCode, {
    super.providerCode,
  }) : super('Langue non couverte par ce fournisseur.');

  final String languageCode;
}

/// Toute la chaîne de repli a échoué : l'UI affiche une abstention.
final class AiChainExhausted extends AiFailure {
  const AiChainExhausted(this.attemptedProviders)
      : super('Aucun fournisseur disponible.');

  final List<String> attemptedProviders;
}

final class AiCancelled extends AiFailure {
  const AiCancelled({super.providerCode}) : super('Opération annulée.');
}

// =============================================================================
// 9. CONTRATS DES FOURNISSEURS
// =============================================================================

/// Parole -> texte. Les partiels servent l'affichage ; seuls les finaux
/// déclenchent la traduction.
abstract interface class SpeechToTextProvider implements AiProvider {
  Stream<TranscriptChunk> transcribe({
    required Stream<AudioChunk> audio,
    required SttConfig config,
  });
}

/// Texte -> parole. Le flux d'états est obligatoire : c'est lui qui permet le
/// demi-duplex et le garde d'écho (§8).
abstract interface class TextToSpeechProvider implements AiProvider {
  Stream<TtsPlaybackEvent> get playbackStates;

  Future<void> speak(
    String text, {
    required VoiceConfig config,
    String? messageId,
  });

  Future<void> stop();
}

/// Traduction vers/depuis la glose.
///
/// `lexicon` est obligatoire en entrée : le fournisseur n'a pas le droit de
/// produire une glose absente du lexique validé (§18.6).
abstract interface class GlossTranslator implements AiProvider {
  Future<GlossSentence> toGloss(
    Utterance input, {
    required String signLanguageCode,
    required GlossLexicon lexicon,
  });

  Future<Utterance> toSpokenText(
    GlossSentence glosses, {
    required String spokenLocale,
  });
}

/// Signes -> hypothèse. Reçoit des segments, pas un flux vidéo : la
/// segmentation est faite en amont, sur l'appareil (§11).
abstract interface class SignRecognizer implements AiProvider {
  Stream<SignHypothesis> recognize({
    required Stream<SignSegment> segments,
    required String signLanguageCode,
    required ConfidencePolicy policy,
    GlossLexicon? lexicon,
  });
}

/// Session vocale temps réel. Le ticket vient du backend : le contrat ne
/// transporte jamais de secret durable (§18.4).
abstract interface class RealtimeSessionProvider implements AiProvider {
  Future<RealtimeSessionTicket> requestTicket(RealtimeSessionConfig config);

  Future<void> closeSession(String conversationId);
}
