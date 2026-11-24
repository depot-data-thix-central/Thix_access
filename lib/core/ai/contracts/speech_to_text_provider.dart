import '../../../models/translation.dart';

abstract interface class SpeechToTextProvider {
  Stream<String> listen();
  Future<void> start();
  Future<void> stop();
}

abstract interface class SpeechRecognitionResultProvider {
  Stream<Translation> recognizeSpeech();
}
