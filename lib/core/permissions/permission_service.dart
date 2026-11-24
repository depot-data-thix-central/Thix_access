/// TODO: request and explain camera/microphone permissions in the UI.
abstract interface class PermissionService {
  Future<bool> requestCamera();
  Future<bool> requestMicrophone();
}
