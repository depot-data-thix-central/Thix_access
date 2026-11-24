/// TODO: implement platform camera access behind a testable interface.
abstract interface class CameraService {
  Future<void> initialize();
  Future<void> dispose();
}
