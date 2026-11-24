/// TODO: connect a validated hand/body landmark provider.
abstract interface class MediaPipeService {
  Future<void> initialize();
  Future<void> dispose();
}
