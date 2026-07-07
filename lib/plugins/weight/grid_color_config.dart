// lib/plugins/weight/grid_color_config.dart
//
// 称重表格颜色配置 — 数据类 + SharedPreferences 读写 + Provider
// 5 种鸟状态：正常 / 今日已称 / 超期未称 / 体重偏高 / 体重偏低
// 3 种显示模式：仅边框 / 仅填充 / 边框+填充

import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════
// 显示模式
// ═══════════════════════════════════════════════

enum CellDisplayMode {
  border,
  fill,
  borderAndFill,
}

extension CellDisplayModeLabel on CellDisplayMode {
  String get label => switch (this) {
        CellDisplayMode.border => '仅边框',
        CellDisplayMode.fill => '仅填充',
        CellDisplayMode.borderAndFill => '边框+填充',
      };
}

// ═══════════════════════════════════════════════
// 鸟状态枚举
// ═══════════════════════════════════════════════

enum BirdCellState {
  normal, // 正常
  weighedToday, // 今日已称
  overdue, // 超期未称
  abnormalHigh, // 体重偏高
  abnormalLow, // 体重偏低
  weaning, // 断奶期
}

extension BirdCellStateMeta on BirdCellState {
  String get label => switch (this) {
        BirdCellState.normal => '正常',
        BirdCellState.weighedToday => '今日已称',
        BirdCellState.overdue => '超期未称',
        BirdCellState.abnormalHigh => '体重偏高',
        BirdCellState.abnormalLow => '体重偏低',
        BirdCellState.weaning => '断奶期',
      };

  String get emoji => switch (this) {
        BirdCellState.normal => '⬜',
        BirdCellState.weighedToday => '🟢',
        BirdCellState.overdue => '🟤',
        BirdCellState.abnormalHigh => '🟠',
        BirdCellState.abnormalLow => '🔴',
        BirdCellState.weaning => '🟧',
      };
}

// ═══════════════════════════════════════════════
// 默认颜色表
// ═══════════════════════════════════════════════

const _defaults = <BirdCellState, int>{
  BirdCellState.normal: 0xFFE0E0E0, // 浅灰（不显示）
  BirdCellState.weighedToday: 0xFF4CAF50, // 绿
  BirdCellState.overdue: 0xFF795548, // 棕（区分于红/橙，表示"被遗忘"）
  BirdCellState.abnormalHigh: 0xFFFF9800, // 橙
  BirdCellState.abnormalLow: 0xFFEF5350, // 软红
  BirdCellState.weaning: 0xFFFF9800, // 橙（与断奶期边框一致）
};

// ═══════════════════════════════════════════════
// 配置数据类（不可变）
// ═══════════════════════════════════════════════

class GridColorConfig {
  final Map<BirdCellState, Color> colors;
  final CellDisplayMode displayMode;
  final double borderWidth;
  final double fillOpacity;
  final bool showLegend;
  final double minColumnWidth;

  static const double minColumnWidthFloor = 152.0;
  static const double minColumnWidthCeil = 250.0;

  const GridColorConfig({
    required this.colors,
    this.displayMode = CellDisplayMode.borderAndFill,
    this.borderWidth = 2.0,
    this.fillOpacity = 0.12,
    this.showLegend = true,
    this.minColumnWidth = 152.0,
  });

  factory GridColorConfig.defaults() => GridColorConfig(
        colors: {
          for (final e in _defaults.entries) e.key: Color(e.value),
        },
      );

  Color borderColor(BirdCellState state) =>
      colors[state] ?? Color(_defaults[state]!);

  Color fillColor(BirdCellState state) =>
      borderColor(state).withValues(alpha: fillOpacity);

  GridColorConfig copyWith({
    Map<BirdCellState, Color>? colors,
    CellDisplayMode? displayMode,
    double? borderWidth,
    double? fillOpacity,
    bool? showLegend,
    double? minColumnWidth,
  }) =>
      GridColorConfig(
        colors: colors ?? Map<BirdCellState, Color>.from(this.colors),
        displayMode: displayMode ?? this.displayMode,
        borderWidth: borderWidth ?? this.borderWidth,
        fillOpacity: fillOpacity ?? this.fillOpacity,
        showLegend: showLegend ?? this.showLegend,
        minColumnWidth: minColumnWidth ?? this.minColumnWidth,
      );

  // ── 序列化 ──

  static const _modeKey = 'wgc_mode';
  static const _borderWKey = 'wgc_border_w';
  static const _fillOpKey = 'wgc_fill_op';
  static const _legendKey = 'wgc_legend';
  static const _colWKey = 'wgc_col_w';

  static String _colorKey(BirdCellState s) => 'wgc_color_${s.name}';

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_modeKey, displayMode.name);
    await p.setDouble(_borderWKey, borderWidth);
    await p.setDouble(_fillOpKey, fillOpacity);
    await p.setBool(_legendKey, showLegend);
    await p.setDouble(_colWKey, minColumnWidth);
    for (final s in BirdCellState.values) {
      await p.setInt(_colorKey(s), (colors[s] ?? Color(_defaults[s]!)).value);
    }
  }

  static Future<GridColorConfig> load() async {
    final p = await SharedPreferences.getInstance();

    final modeName = p.getString(_modeKey);
    final mode = CellDisplayMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => CellDisplayMode.borderAndFill,
    );

    final colors = <BirdCellState, Color>{};
    for (final s in BirdCellState.values) {
      final v = p.getInt(_colorKey(s));
      colors[s] = v != null ? Color(v) : Color(_defaults[s]!);
    }

    final storedColW = p.getDouble(_colWKey) ?? minColumnWidthFloor;
    final colW = storedColW.clamp(minColumnWidthFloor, minColumnWidthCeil);

    return GridColorConfig(
      colors: colors,
      displayMode: mode,
      borderWidth: p.getDouble(_borderWKey) ?? 2.0,
      fillOpacity: p.getDouble(_fillOpKey) ?? 0.12,
      showLegend: p.getBool(_legendKey) ?? true,
      minColumnWidth: colW,
    );
  }
}

// ═══════════════════════════════════════════════
// Provider（公开 notifier，跨文件共享）
// ═══════════════════════════════════════════════

class GridColorNotifier extends StateNotifier<GridColorConfig> {
  GridColorNotifier() : super(GridColorConfig.defaults()) {
    _load();
  }

  Future<void> _load() async {
    state = await GridColorConfig.load();
  }

  Future<void> update(GridColorConfig cfg) async {
    state = cfg;
    await cfg.save();
  }
}

final gridColorConfigProvider =
    StateNotifierProvider<GridColorNotifier, GridColorConfig>(
  (ref) => GridColorNotifier(),
);
