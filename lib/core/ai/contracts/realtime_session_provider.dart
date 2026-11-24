abstract interface class RealtimeSessionProvider {
  Future<void> connect();
  Future<void> disconnect();
  Stream<Object> get events;
}
