import '../../contracts/text_to_speech_provider.dart';

class FakeTextToSpeechProvider implements TextToSpeechProvider {
  @override
  Future<void> speak(String text, {required String languageCode}) async {}

  @override
  Future<void> stop() async {}
}
