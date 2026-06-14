import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/work_hours_config.dart';

/// 喂药插件自己的时间窗口 key（覆盖全局工作时间）
const _kMedStartHour = 'medication_work_start_hour';
const _kMedStartMin = 'medication_work_start_min';
const _kMedEndHour = 'medication_work_end_hour';
const _kMedEndMin = 'medication_work_end_min';

/// 默认给药次数 key
const _kDefaultDoses = 'medication_config_default_doses';

/// 喂药插件配置（优先自身时间窗口，未设时回退到全局 WorkHoursConfig）
class MedicationConfig {
  final TimeOfDay windowStart;
  final TimeOfDay windowEnd;
  final int defaultDoses;

  final bool _hasCustomWindow;

  const MedicationConfig({
    this.windowStart = const TimeOfDay(hour: 8, minute: 0),
    this.windowEnd = const TimeOfDay(hour: 22, minute: 0),
    this.defaultDoses = 2,
    bool hasCustomWindow = false,
  }) : _hasCustomWindow = hasCustomWindow;

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

  /// 根据每日次数在工作窗口内均分时间点
  List<TimeOfDay> distributeDoses(int doses) {
    if (doses <= 0) return [];
    if (doses == 1) {
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

  /// 是否有自己的时间窗口（而非回退到全局）
  bool get hasCustomWindow => _hasCustomWindow;

  /// 加载配置：优先喂药插件自身时间窗口，未设时回退到全局 WorkHoursConfig
  static Future<MedicationConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final sh = prefs.getInt(_kMedStartHour);

    TimeOfDay windowStart;
    TimeOfDay windowEnd;
    bool custom = false;

    if (sh != null) {
      // 喂药插件有自己的时间窗口
      windowStart = TimeOfDay(hour: sh, minute: prefs.getInt(_kMedStartMin) ?? 0);
      windowEnd = TimeOfDay(
        hour: prefs.getInt(_kMedEndHour) ?? 22,
        minute: prefs.getInt(_kMedEndMin) ?? 0,
      );
      custom = true;
    } else {
      // 回退到全局工作时间
      final wh = await WorkHoursConfig.load();
      windowStart = wh.workStart;
      windowEnd = wh.workEnd;
    }

    return MedicationConfig(
      windowStart: windowStart,
      windowEnd: windowEnd,
      defaultDoses: prefs.getInt(_kDefaultDoses) ?? 2,
      hasCustomWindow: custom,
    );
  }

  /// 保存配置（时间窗口 + 默认次数，均使用喂药插件独立 key）
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMedStartHour, windowStart.hour);
    await prefs.setInt(_kMedStartMin, windowStart.minute);
    await prefs.setInt(_kMedEndHour, windowEnd.hour);
    await prefs.setInt(_kMedEndMin, windowEnd.minute);
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
      hasCustomWindow: true, // 手动调整时间窗口后标记为自定义
    );
  }

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
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(_kMedStartHour);
              await prefs.remove(_kMedStartMin);
              await prefs.remove(_kMedEndHour);
              await prefs.remove(_kMedEndMin);
              await prefs.setInt(_kDefaultDoses, 2);
              final c = await MedicationConfig.load();
              if (mounted) setState(() => _config = c);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 喂药时间窗口 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('喂药时间窗口', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    // 重置为全局工作时间
                    if (_config.hasCustomWindow)
                      TextButton.icon(
                        icon: const Icon(Icons.restore, size: 14),
                        label: const Text('用全局', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('重置时间窗口'),
                              content: const Text('清除喂药插件的时间窗口，改回使用全局工作时间？'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            await _resetToGlobalWindow();
                          }
                        },
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(_config.hasCustomWindow
                      ? '已设置独立时间窗口，不受全局工作时间影响'
                      : '未单独设置，沿用全局工作时间',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  // 可编辑时间选择
                  Row(
                    children: [
                      Expanded(
                        child: _TimeCard(
                          label: '起始时间',
                          time: _config.formatTime(_config.windowStart),
                          onTap: () => _pickMedTime(true),
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
                          onTap: () => _pickMedTime(false),
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
                        Expanded(child: Text('跨午夜模式，凌晨时间归入次日', style: TextStyle(fontSize: 12, color: Colors.blue))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('此处仅覆盖喂药插件的时间。其他插件仍使用全局工作时间。',
                            style: TextStyle(fontSize: 12, color: Colors.blue)),
                      ),
                    ]),
                  ),
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
                  Text('每日 ${_config.defaultDoses} 次 · $windowLabel',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
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
                  Text('• 此处设置仅影响喂药插件，不影响全局或其他插件\n'
                      '• 未设置时间窗口时，自动沿用全局工作时间\n'
                      '• 添加药品时仍可单独调整每日次数和时间点\n'
                      '• 喂药任务将于预定时间前 30 分钟出现在任务列表中',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _config.windowStart : _config.windowEnd,
      cancelText: '取消',
      confirmText: '确定',
      helpText: isStart ? '喂药起始时间' : '喂药结束时间',
    );
    if (picked != null && mounted) {
      final updated = isStart
          ? _config.copyWith(windowStart: picked)
          : _config.copyWith(windowEnd: picked);
      await updated.save();
      setState(() => _config = updated);
    }
  }

  /// 清除喂药插件自身的时间窗口，改回使用全局工作时间
  Future<void> _resetToGlobalWindow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMedStartHour);
    await prefs.remove(_kMedStartMin);
    await prefs.remove(_kMedEndHour);
    await prefs.remove(_kMedEndMin);
    // 重新加载（此时会回退到全局）
    final c = await MedicationConfig.load();
    if (mounted) setState(() => _config = c);
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback? onTap;
  const _TimeCard({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReadOnly = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: isReadOnly ? Colors.grey.shade100 : theme.colorScheme.surfaceContainerLow,
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(time, style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
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
