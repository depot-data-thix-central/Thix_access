import '../contracts/speech_to_text_provider.dart';
import '../contracts/text_to_speech_provider.dart';

class AiProviderRegistry {
  const AiProviderRegistry({
    required this.speechToText,
    required this.textToSpeech,
  });

  final SpeechToTextProvider speechToText;
  final TextToSpeechProvider textToSpeech;
}
