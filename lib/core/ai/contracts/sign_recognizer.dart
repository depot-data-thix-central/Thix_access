import '../../../models/translation.dart';

abstract interface class SignRecognizer {
  Stream<Translation> recognize();
  Future<void> start();
  Future<void> stop();
}
