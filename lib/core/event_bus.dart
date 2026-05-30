/// Lightweight typed event bus — plugins subscribe to domain events
/// without coupling to each other or to the main app.
///
/// Usage:
/// ```dart
/// eventBus.on<WeightRecorded>((e) => wechatPlugin.notify(e));
/// eventBus.emit(WeightRecorded(birdId: 1, weightG: 45.5));
/// ```
class EventBus {
  final _handlers = <Type, List<Function>>{};

  /// Register a handler for events of type [T].
  void on<T>(void Function(T event) handler) {
    _handlers.putIfAbsent(T, () => []).add(handler);
  }

  /// Emit an event — all registered handlers for [T] are invoked synchronously.
  void emit<T>(T event) {
    final handlers = _handlers[T];
    if (handlers == null) return;
    for (final h in handlers) {
      (h as void Function(T))(event);
    }
  }

  /// Remove all handlers for [T], or all if [T] is omitted.
  void clear<T>() {
    _handlers.remove(T);
  }

  void clearAll() => _handlers.clear();
}
