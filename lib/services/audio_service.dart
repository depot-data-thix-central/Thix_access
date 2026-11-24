/// TODO: implement microphone lifecycle, permission checks and audio focus.
abstract interface class AudioService {
  Future<void> startListening();
  Future<void> stopListening();
}
