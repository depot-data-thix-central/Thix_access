/// Placeholder: report aggregate API usage without logging raw audio/video.
abstract interface class UsageReporter {
  Future<void> report({required String provider, required int units});
}
