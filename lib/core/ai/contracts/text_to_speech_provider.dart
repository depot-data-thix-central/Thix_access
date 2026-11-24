abstract interface class TextToSpeechProvider {
  Future<void> speak(String text, {required String languageCode});
  Future<void> stop();
}
