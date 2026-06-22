// lib/screens/weigh/weigh_input_config.dart
//
// 称重输入配置 — 输入模式（按键/转盘）、转盘位置、灵敏度
// SharedPreferences 持久化 + Riverpod provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════
// 输入模式枚举
// ═══════════════════════════════════════════════

enum WeighInputMode {
  keypad,
  dial,
}

extension WeighInputModeLabel on WeighInputMode {
  String get label => switch (this) {
    WeighInputMode.keypad => '按键',
    WeighInputMode.dial   => '转盘',
  };
}

// ═══════════════════════════════════════════════
// 转盘位置枚举
// ═══════════════════════════════════════════════

enum DialSide {
  left,
  right,
}

extension DialSideLabel on DialSide {
  String get label => switch (this) {
    DialSide.left  => '左手',
    DialSide.right => '右手',
  };
}

// ═══════════════════════════════════════════════
// 配置数据类
// ═══════════════════════════════════════════════

class WeighInputConfig {
  final WeighInputMode mode;
  final DialSide dialSide;
  final double sensitivity; // 刻度角度（10° ~ 30°），默认 15°
  final double speedThreshold; // 慢/快分界线 (°/s)，默认 70
  final int windowSize;        // 滑动平均帧数，默认 3
  final double fastStep;       // 快速滑动步长 (g)，默认 0.5

  static const double sensitivityMin = 10.0;
  static const double sensitivityMax = 30.0;
  static const double sensitivityDefault = 15.0;

  static const double speedThresholdMin = 150.0;
  static const double speedThresholdMax = 250.0;
  static const double speedThresholdDefault = 170.0;

  static const int windowSizeMin = 6;
  static const int windowSizeMax = 15;
  static const int windowSizeDefault = 8;

  static const double fastStepMin = 0.3;
  static const double fastStepMax = 1.0;
  static const double fastStepDefault = 0.5;

  const WeighInputConfig({
    this.mode = WeighInputMode.keypad,
    this.dialSide = DialSide.right,
    this.sensitivity = sensitivityDefault,
    this.speedThreshold = speedThresholdDefault,
    this.windowSize = windowSizeDefault,
    this.fastStep = fastStepDefault,
  });

  WeighInputConfig copyWith({
    WeighInputMode? mode,
    DialSide? dialSide,
    double? sensitivity,
    double? speedThreshold,
    int? windowSize,
    double? fastStep,
  }) =>
      WeighInputConfig(
        mode: mode ?? this.mode,
        dialSide: dialSide ?? this.dialSide,
        sensitivity: sensitivity ?? this.sensitivity,
        speedThreshold: speedThreshold ?? this.speedThreshold,
        windowSize: windowSize ?? this.windowSize,
        fastStep: fastStep ?? this.fastStep,
      );

  // ── 序列化 ──

  static const _modeKey = 'wic_mode';
  static const _sideKey = 'wic_side';
  static const _sensitivityKey = 'wic_sens';
  static const _speedThresholdKey = 'wic_speed_thr';
  static const _windowSizeKey = 'wic_win_size';
  static const _fastStepKey = 'wic_fast_step';

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_modeKey, mode.name);
    await p.setString(_sideKey, dialSide.name);
    await p.setDouble(_sensitivityKey, sensitivity);
    await p.setDouble(_speedThresholdKey, speedThreshold);
    await p.setInt(_windowSizeKey, windowSize);
    await p.setDouble(_fastStepKey, fastStep);
  }

  static Future<WeighInputConfig> load() async {
    final p = await SharedPreferences.getInstance();

    final modeName = p.getString(_modeKey);
    final mode = WeighInputMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => WeighInputMode.keypad,
    );

    final sideName = p.getString(_sideKey);
    final side = DialSide.values.firstWhere(
      (s) => s.name == sideName,
      orElse: () => DialSide.right,
    );

    final sens = p.getDouble(_sensitivityKey) ?? sensitivityDefault;
    final speedThr = p.getDouble(_speedThresholdKey) ?? speedThresholdDefault;
    final winSize = p.getInt(_windowSizeKey) ?? windowSizeDefault;
    final fastStep = p.getDouble(_fastStepKey) ?? fastStepDefault;

    return WeighInputConfig(
      mode: mode,
      dialSide: side,
      sensitivity: sens.clamp(sensitivityMin, sensitivityMax),
      speedThreshold: speedThr.clamp(speedThresholdMin, speedThresholdMax),
      windowSize: winSize.clamp(windowSizeMin, windowSizeMax),
      fastStep: fastStep.clamp(fastStepMin, fastStepMax),
    );
  }
}

// ═══════════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════════

class WeighInputConfigNotifier extends StateNotifier<WeighInputConfig> {
  WeighInputConfigNotifier() : super(const WeighInputConfig()) {
    _load();
  }

  Future<void> _load() async {
    state = await WeighInputConfig.load();
  }

  Future<void> setMode(WeighInputMode mode) async {
    state = state.copyWith(mode: mode);
    await state.save();
  }

  Future<void> setDialSide(DialSide side) async {
    state = state.copyWith(dialSide: side);
    await state.save();
  }

  Future<void> setSensitivity(double sensitivity) async {
    state = state.copyWith(
      sensitivity: sensitivity.clamp(
        WeighInputConfig.sensitivityMin,
        WeighInputConfig.sensitivityMax,
      ),
    );
    await state.save();
  }

  Future<void> setSpeedThreshold(double value) async {
    state = state.copyWith(
      speedThreshold: value.clamp(
        WeighInputConfig.speedThresholdMin,
        WeighInputConfig.speedThresholdMax,
      ),
    );
    await state.save();
  }

  Future<void> setWindowSize(int value) async {
    state = state.copyWith(
      windowSize: value.clamp(
        WeighInputConfig.windowSizeMin,
        WeighInputConfig.windowSizeMax,
      ),
    );
    await state.save();
  }

  Future<void> setFastStep(double value) async {
    state = state.copyWith(
      fastStep: value.clamp(
        WeighInputConfig.fastStepMin,
        WeighInputConfig.fastStepMax,
      ),
    );
    await state.save();
  }
}

final weighInputConfigProvider =
    StateNotifierProvider<WeighInputConfigNotifier, WeighInputConfig>(
  (ref) => WeighInputConfigNotifier(),
);
