import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 喂药窗口配置持久化 key
const _kWindowStartHour = 'medication_config_window_start_hour';
const _kWindowStartMin = 'medication_config_window_start_min';
const _kWindowEndHour = 'medication_config_window_end_hour';
const _kWindowEndMin = 'medication_config_window_end_min';
const _kDefaultDoses = 'medication_config_default_doses';

/// 喂药窗口配置
class MedicationConfig {
  final TimeOfDay windowStart;
  final TimeOfDay windowEnd;
  final int defaultDoses;

  const MedicationConfig({
    this.windowStart = const TimeOfDay(hour: 8, minute: 0),
    this.windowEnd = const TimeOfDay(hour: 22, minute: 0),
    this.defaultDoses = 2,
  });

  bool get crossesMidnight {
    final s = windowStart.hour * 60 + windowStart.minute;
    final e = windowEnd.hour * 60 + windowEnd.minute;
    return e <= s;
  }

  int get windowMinutes {
    final s = windowStart.hour * 60 + windowStart.minute;
    final e = windowEnd.hour * 60 + windowEnd.minute;
    if (crossesMidnight) {
      return (24 * 60 - s) + e;
    }
    return e - s;
  }

  /// 根据每日次数自动均分时间点
  List<TimeOfDay> distributeDoses(int doses) {
    if (doses <= 0) return [];
    if (doses == 1) {
      // 单次放窗口中间
      final mid = (windowStart.hour * 60 + windowStart.minute + windowMinutes ~/ 2) % (24 * 60);
      return [TimeOfDay(hour: mid ~/ 60, minute: mid % 60)];
    }
    final interval = windowMinutes / (doses - 1);
    final startMin = windowStart.hour * 60 + windowStart.minute;
    return List.generate(doses, (i) {
      final m = (startMin + (interval * i).round()) % (24 * 60);
      return TimeOfDay(hour: m ~/ 60, minute: m % 60);
    });
  }

  String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// 加载配置
  static Future<MedicationConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MedicationConfig(
      windowStart: TimeOfDay(
        hour: prefs.getInt(_kWindowStartHour) ?? 8,
        minute: prefs.getInt(_kWindowStartMin) ?? 0,
      ),
      windowEnd: TimeOfDay(
        hour: prefs.getInt(_kWindowEndHour) ?? 22,
        minute: prefs.getInt(_kWindowEndMin) ?? 0,
      ),
      defaultDoses: prefs.getInt(_kDefaultDoses) ?? 2,
    );
  }

  /// 保存配置
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWindowStartHour, windowStart.hour);
    await prefs.setInt(_kWindowStartMin, windowStart.minute);
    await prefs.setInt(_kWindowEndHour, windowEnd.hour);
    await prefs.setInt(_kWindowEndMin, windowEnd.minute);
    await prefs.setInt(_kDefaultDoses, defaultDoses);
  }

  MedicationConfig copyWith({
    TimeOfDay? windowStart,
    TimeOfDay? windowEnd,
    int? defaultDoses,
  }) {
    return MedicationConfig(
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      defaultDoses: defaultDoses ?? this.defaultDoses,
    );
  }

  /// 重置默认值
  static const MedicationConfig defaults = MedicationConfig();
}

/// 喂药插件设置页
class MedicationConfigScreen extends StatefulWidget {
  const MedicationConfigScreen({super.key});

  @override
  State<MedicationConfigScreen> createState() => _MedicationConfigScreenState();
}

class _MedicationConfigScreenState extends State<MedicationConfigScreen> {
  MedicationConfig _config = MedicationConfig.defaults;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await MedicationConfig.load();
    if (mounted) setState(() { _config = c; _loading = false; });
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _config.windowStart : _config.windowEnd,
      cancelText: '取消',
      confirmText: '确定',
      helpText: isStart ? '喂药起始时间' : '喂药结束时间',
    );
    if (picked != null) {
      final updated = isStart
          ? _config.copyWith(windowStart: picked)
          : _config.copyWith(windowEnd: picked);
      setState(() => _config = updated);
      await updated.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('喂药设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final points = _config.distributeDoses(_config.defaultDoses);
    final windowLabel = _config.crossesMidnight
        ? '🌙 ${_config.formatTime(_config.windowStart)} ~ ${_config.formatTime(_config.windowEnd)} (次日)'
        : '${_config.formatTime(_config.windowStart)} ~ ${_config.formatTime(_config.windowEnd)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('喂药设置'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('重置'),
            onPressed: () async {
              await MedicationConfig.defaults.save();
              setState(() => _config = MedicationConfig.defaults);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 喂药窗口 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text('喂药时间窗口', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 4),
                  Text('设置一天内可以喂药的时间段，系统将在此范围内自动分配喂药时间',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeCard(
                          label: '起始时间',
                          time: _config.formatTime(_config.windowStart),
                          onTap: () => _pickTime(true),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('~', style: TextStyle(fontSize: 20, color: Colors.grey)),
                      ),
                      Expanded(
                        child: _TimeCard(
                          label: '结束时间',
                          time: _config.formatTime(_config.windowEnd),
                          onTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  ),
                  if (_config.crossesMidnight) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(children: [
                        Icon(Icons.nightlight_round, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(child: Text('检测到跨午夜窗口，凌晨时间将归入次日', style: TextStyle(fontSize: 12, color: Colors.blue))),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── 每日次数 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('默认每日次数', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('新添加药品时的默认值，可单独调整', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1 次/日'), icon: Icon(Icons.looks_one, size: 16)),
                      ButtonSegment(value: 2, label: Text('2 次/日'), icon: Icon(Icons.looks_two, size: 16)),
                      ButtonSegment(value: 3, label: Text('3 次/日'), icon: Icon(Icons.looks_3, size: 16)),
                      ButtonSegment(value: 4, label: Text('4 次/日'), icon: Icon(Icons.looks_4, size: 16)),
                    ],
                    selected: {_config.defaultDoses},
                    onSelectionChanged: (v) async {
                      final updated = _config.copyWith(defaultDoses: v.first);
                      setState(() => _config = updated);
                      await updated.save();
                    },
                    showSelectedIcon: false,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── 预览 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.preview, size: 20),
                    const SizedBox(width: 8),
                    Text('时间分布预览', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 4),
                  Text('每日 $_config.defaultDoses 次 · $windowLabel',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  // 时间线预览
                  SizedBox(
                    height: 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CustomPaint(
                            size: const Size(double.infinity, 2),
                            painter: _TimelinePainter(
                              points: points,
                              crossesMidnight: _config.crossesMidnight,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 时间标签
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: points.map((t) => Chip(
                      avatar: Icon(Icons.medication, size: 14, color: theme.colorScheme.primary),
                      label: Text(_config.formatTime(t), style: const TextStyle(fontSize: 13)),
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 说明
          Card(
            color: Colors.grey.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Text('说明', style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  SizedBox(height: 8),
                  Text('• 此处为全局默认设置，新添加药品时自动应用\n'
                      '• 添加药品时仍可单独调整每日次数和时间点\n'
                      '• 喂药任务将于预定时间前 30 分钟出现在任务列表中\n'
                      '• 结束时间早于起始时间 = 跨午夜模式',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimeCard({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surfaceContainerLow,
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(time, style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
                const SizedBox(width: 4),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 时间线预览画笔
class _TimelinePainter extends CustomPainter {
  final List<TimeOfDay> points;
  final bool crossesMidnight;
  final Color color;

  _TimelinePainter({required this.points, required this.crossesMidnight, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color.withAlpha(80)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 画线
    final path = Path();
    path.moveTo(8, size.height / 2);
    path.lineTo(size.width - 8, size.height / 2);
    canvas.drawPath(path, paint);

    // 画点
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final frac = points.length > 1 ? i / (points.length - 1) : 0.5;
      final x = 8 + frac * (size.width - 16);
      final y = size.height / 2;
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) =>
      old.points != points || old.color != color || old.crossesMidnight != crossesMidnight;
}
