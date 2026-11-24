class Confidence {
  const Confidence(this.value) : assert(value >= 0 && value <= 1);

  final double value;

  bool get isReliable => value >= 0.8;
}
