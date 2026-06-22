import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/plugin.dart' show AlertSeverity;
import 'alert_service.dart';

/// 本地通知服务 — 单例。
///
/// Phase 1：任务逾期通知 + 异常告警通知。
/// 调用 [init] 一次后，通过 [showOverdueTasks] / [showAlerts] 发送通知。
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _overdueChannelId = 'task_overdue';
  static const _alertChannelId = 'alert';
  static const _overdueNotifyId = 1000;
  static const _warningAggregateId = 2000;

  Future<void> init() async {
    if (_initialized) return;
    // Web 平台不支持本地通知，跳过初始化
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
    );

    // 注册 Android 通知渠道
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _overdueChannelId,
          '任务逾期',
          description: '任务超过截止时间的提醒',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _alertChannelId,
          '异常提醒',
          description: '体重异常、漏喂等告警',
          importance: Importance.high,
        ),
      );
      // Android 13+ 弹出系统权限对话框
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// 点击通知回调（暂仅唤醒 app）。
  void _onTap(NotificationResponse response) {
    // Phase 2 可根据 payload 导航到具体页面
  }

  // ── 公开方法 ──

  /// 任务逾期通知。
  ///
  /// 聚合为一条通知，显示逾期任务概要。
  Future<void> showOverdueTasks(
    List<({String birdName, String taskType})> items,
  ) async {
    if (!_initialized || kIsWeb || items.isEmpty) return;

    final body = items.length <= 3
        ? items.map((e) => '${e.birdName} — ${e.taskType}').join('\n')
        : '${items.length} 个任务已逾期';

    final typeLabel = items.map((e) => e.taskType).toSet().join('、');
    final title = '任务逾期 — $typeLabel';

    await _plugin.show(
      _overdueNotifyId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _overdueChannelId,
          '任务逾期',
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// 异常告警通知。
  ///
  /// [danger] 级告警逐条发送；[warning] 级聚合为一条。
  Future<void> showAlerts(List<AnomalyAlert> alerts) async {
    if (!_initialized || kIsWeb || alerts.isEmpty) return;

    final dangerAlerts = alerts.where((a) => a.severity == AlertSeverity.danger).toList();
    final warningAlerts = alerts.where((a) => a.severity == AlertSeverity.warning).toList();

    // Danger 逐条通知
    for (final a in dangerAlerts) {
      final id = _alertId(a.bird.bird.id, a.type);
      await _plugin.show(
        id,
        '⚠ ${a.type}',
        '${a.bird.bird.name} — ${a.description}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _alertChannelId,
            '异常提醒',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }

    // Warning 聚合为一条
    if (warningAlerts.isNotEmpty) {
      final types = warningAlerts.map((a) => a.type).toSet().join('、');
      final summary = warningAlerts.length <= 3
          ? warningAlerts.map((a) => '${a.bird.bird.name}: ${a.description}').join('\n')
          : '${warningAlerts.length} 个提醒';
      await _plugin.show(
        _warningAggregateId,
        '提醒 — $types',
        summary,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _alertChannelId,
            '异常提醒',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  /// 基于 birdId + alertType 生成稳定的通知 ID，避免同告警重复弹出。
  int _alertId(int birdId, String type) {
    return 3000 + ('$birdId:$type'.hashCode & 0x7fffffff) % 1000;
  }
}
