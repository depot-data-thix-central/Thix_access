import '../../../models/translation.dart';

abstract interface class GlossTranslator {
  Future<Translation> translateText(
    String text, {
    required String signLanguageCode,
  });
}
