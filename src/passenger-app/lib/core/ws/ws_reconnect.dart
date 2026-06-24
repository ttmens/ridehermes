class ExponentialBackoffReconnect {
  int _attempt = 0;
  static const _maxDelay = 15000;
  static const _baseDelay = 1000;

  int nextDelay() {
    final delay = _baseDelay * (1 << _attempt);
    _attempt++;
    return delay > _maxDelay ? _maxDelay : delay;
  }

  void reset() {
    _attempt = 0;
  }
}
