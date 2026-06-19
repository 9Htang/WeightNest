/// Domain events emitted via [EventBus] for cross-plugin communication.
///
/// Plugins subscribe to these events in [FeaturePlugin.registerEvents] and
/// react without coupling to the emitting plugin.
///
/// {@template OperationRecordedEvent}
/// Emitted by [OperationService] after every recorded operation.
///
/// Plugins can listen for specific [pluginId] / [actionType] combinations:
/// ```dart
/// bus.on<OperationRecordedEvent>((e) {
///   if (e.pluginId == 'medication' && e.actionType == 'medication_given') {
///     // Check for weight impact, etc.
///   }
/// });
/// ```
class OperationRecordedEvent {
  final int logId;
  final String pluginId;
  final String actionType;
  final int? birdId;
  final String summary;
  final Map<String, dynamic>? details;
  final int? relatedTaskId;
  final int? operatedBy;
  final DateTime operatedAt;

  const OperationRecordedEvent({
    required this.logId,
    required this.pluginId,
    required this.actionType,
    required this.summary,
    this.birdId,
    this.details,
    this.relatedTaskId,
    this.operatedBy,
    required this.operatedAt,
  });
}
