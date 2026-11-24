class FeatureFlags {
  const FeatureFlags({
    this.signRecognition = false,
    this.speechRecognition = false,
    this.avatar = false,
    this.supabase = false,
    this.devTools = false,
  });

  final bool signRecognition;
  final bool speechRecognition;
  final bool avatar;
  final bool supabase;
  final bool devTools;
}
