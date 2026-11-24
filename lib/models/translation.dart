enum TranslationStatus { pending, recognized, uncertain, failed }

class Translation {
  const Translation({
    required this.text,
    required this.status,
    this.confidence,
  });

  final String text;
  final TranslationStatus status;
  final double? confidence;
}
