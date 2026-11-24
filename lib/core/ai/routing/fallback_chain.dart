/// Placeholder for routing, retries and circuit-breaker policies.
/// Implement only after provider capabilities and failure semantics are defined.
class FallbackChain<T> {
  const FallbackChain(this.providers);

  final List<T> providers;
}
