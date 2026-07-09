class TmdbApiMetrics {
  TmdbApiMetrics();

  int callCount = 0;
  int cacheHitCount = 0;
  int errorCount = 0;
  Duration totalLatency = Duration.zero;

  void recordCall({required Duration latency, bool failed = false}) {
    callCount++;
    totalLatency += latency;
    if (failed) errorCount++;
  }

  void recordCacheHit() => cacheHitCount++;

  Duration get averageLatency =>
      callCount == 0 ? Duration.zero : totalLatency ~/ callCount;
}
