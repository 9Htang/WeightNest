import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 新 key（主设置）
const _kStartHour = 'work_start_hour';
const _kStartMin = 'work_start_min';
const _kEndHour = 'work_end_hour';
const _kEndMin = 'work_end_min';

/// 旧 key（喂药插件，迁移用）
const _kOldStartHour = 'medication_config_window_start_hour';
const _kOldStartMin = 'medication_config_window_start_min';
const _kOldEndHour = 'medication_config_window_end_hour';
const _kOldEndMin = 'medication_config_window_end_min';

/// 用户工作时间配置（多插件共享）
class WorkHoursConfig {
  final TimeOfDay workStart;
  final TimeOfDay workEnd;

  const WorkHoursConfig({
    this.workStart = const TimeOfDay(hour: 8, minute: 0),
    this.workEnd = const TimeOfDay(hour: 22, minute: 0),
  });

  /// 是否跨午夜（结束时间 <= 起始时间）
  bool get crossesMidnight {
    final s = workStart.hour * 60 + workStart.minute;
    final e = workEnd.hour * 60 + workEnd.minute;
    return e <= s;
  }

  /// 窗口总分钟数
  int get windowMinutes {
    final s = workStart.hour * 60 + workStart.minute;
    final e = workEnd.hour * 60 + workEnd.minute;
    if (crossesMidnight) {
      return (24 * 60 - s) + e;
    }
    return e - s;
  }

  /// 在工作窗口内均分时间点
  List<TimeOfDay> distributeDoses(int doses) {
    if (doses <= 0) return [];
    if (doses == 1) {
      final mid =
          (workStart.hour * 60 + workStart.minute + windowMinutes ~/ 2) %
              (24 * 60);
      return [TimeOfDay(hour: mid ~/ 60, minute: mid % 60)];
    }
    final interval = windowMinutes / (doses - 1);
    final startMin = workStart.hour * 60 + workStart.minute;
    return List.generate(doses, (i) {
      final m = (startMin + (interval * i).round()) % (24 * 60);
      return TimeOfDay(hour: m ~/ 60, minute: m % 60);
    });
  }

  String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// 工作开始前 30 分钟的时间点
  TimeOfDay get taskReadyTime {
    final total = workStart.hour * 60 + workStart.minute - 30;
    if (total < 0) {
      // 前一天 23:30+
      return TimeOfDay(hour: 23, minute: 60 + total);
    }
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  // ── 持久化 ──

  static Future<WorkHoursConfig> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 先读新 key
    final sh = prefs.getInt(_kStartHour);
    final sm = prefs.getInt(_kStartMin);

    if (sh != null) {
      // 新 key 存在，直接读
      return WorkHoursConfig(
        workStart: TimeOfDay(hour: sh, minute: sm ?? 0),
        workEnd: TimeOfDay(
          hour: prefs.getInt(_kEndHour) ?? 22,
          minute: prefs.getInt(_kEndMin) ?? 0,
        ),
      );
    }

    // 新 key 不存在 → 尝试从旧喂药 key 迁移
    final oh = prefs.getInt(_kOldStartHour);
    if (oh != null) {
      final config = WorkHoursConfig(
        workStart:
            TimeOfDay(hour: oh, minute: prefs.getInt(_kOldStartMin) ?? 0),
        workEnd: TimeOfDay(
          hour: prefs.getInt(_kOldEndHour) ?? 22,
          minute: prefs.getInt(_kOldEndMin) ?? 0,
        ),
      );
      await config.save(); // 写入新 key
      return config;
    }

    return const WorkHoursConfig(); // 默认
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStartHour, workStart.hour);
    await prefs.setInt(_kStartMin, workStart.minute);
    await prefs.setInt(_kEndHour, workEnd.hour);
    await prefs.setInt(_kEndMin, workEnd.minute);
  }

  WorkHoursConfig copyWith({TimeOfDay? workStart, TimeOfDay? workEnd}) {
    return WorkHoursConfig(
      workStart: workStart ?? this.workStart,
      workEnd: workEnd ?? this.workEnd,
    );
  }

  static const WorkHoursConfig defaults = WorkHoursConfig();
}
