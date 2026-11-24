import '../../contracts/speech_to_text_provider.dart';

class FakeSpeechToTextProvider implements SpeechToTextProvider {
  @override
  Stream<String> listen() => const Stream<String>.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
