import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'weigh_input_config.dart';

/// 体重数字显示区 — 大字体体重 + 消息 + 左右 ±1g + 空腹按钮
class WeighDisplay extends StatelessWidget {
  final String weightText;
  final String? message;
  final ThemeData theme;
  final bool showUnit;
  final VoidCallback? onMinus1;
  final VoidCallback? onMinus10;
  final VoidCallback? onPlus1;
  final VoidCallback? onPlus10;
  final bool? isFasting;
  final VoidCallback? onToggleFasting;

  const WeighDisplay({
    super.key,
    required this.weightText,
    this.message,
    required this.theme,
    this.showUnit = true,
    this.onMinus1,
    this.onMinus10,
    this.onPlus1,
    this.onPlus10,
    this.isFasting,
    this.onToggleFasting,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = weightText.isEmpty ? '0.0' : weightText;
    final scheme = theme.colorScheme;
    final showButtons = onMinus1 != null && onPlus1 != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 体重数字行：-1g + 体重 + +1g + 空腹
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showButtons)
              _QuickBtn(
                icon: Icons.remove,
                label: '1g',
                onTap: onMinus1!,
                onLongPress: onMinus10 ?? onMinus1!,
              ),
            if (showButtons) const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            if (showButtons) const SizedBox(width: 4),
            if (showButtons)
              _QuickBtn(
                icon: Icons.add,
                label: '1g',
                onTap: onPlus1!,
                onLongPress: onPlus10 ?? onPlus1!,
              ),
            if (showButtons && isFasting != null) ...[
              const SizedBox(width: 6),
              ActionChip(
                avatar: Icon(
                  isFasting! ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: isFasting! ? Colors.white : null,
                ),
                label: const Text('空腹', style: TextStyle(fontSize: 12)),
                backgroundColor: isFasting! ? scheme.primary : null,
                onPressed: onToggleFasting!,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        if (showUnit) ...[
          const SizedBox(height: 2),
          Text(
            '克 (g)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withAlpha(120),
            ),
          ),
        ],
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(
            message!,
            style: TextStyle(
              color: message!.startsWith('✅') ? Colors.green : Colors.orange,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(60),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 转盘输入控件 — 仪表盘式半圆弧
// ═══════════════════════════════════════════════

/// 仪表盘转盘：半圆弧 + 指针（当前体重固定3点钟）+ 绿点（上次体重）+ 空腹按钮
///
/// 盘面刻度以当前体重为中心，量程按生长阶段自适应。
/// 旋转手势移动绿点在弧上的位置，体重随盘面偏移变化。
class WeighDial extends StatefulWidget {
  final DialSide side;
  final String weightText;
  final String? message;
  final bool isFasting;
  final VoidCallback onToggleFasting;
  final double? lastWeightG;
  final String growthStage;
  final double sensitivity;
  final double speedThreshold;
  final int windowSize;
  final double fastStep;
  final ValueChanged<double> onDelta;
  final ThemeData theme;

  const WeighDial({
    super.key,
    required this.side,
    this.weightText = '',
    this.message,
    this.isFasting = false,
    required this.onToggleFasting,
    this.lastWeightG,
    this.growthStage = '成鸟',
    this.sensitivity = 15.0,
    this.speedThreshold = 170.0,
    this.windowSize = 8,
    this.fastStep = 0.5,
    required this.onDelta,
    required this.theme,
  });

  @override
  State<WeighDial> createState() => _WeighDialState();
}

class _WeighDialState extends State<WeighDial> {
  double _dialOffset = 0;  // 盘面旋转偏移（弧度），顺时针手势减少
  double _lastAngle = 0;
  bool _isTracking = false;
  DateTime? _lastUpdateTime;
  double _accumRaw = 0;  // 累积未触发的原始角度
  double _lastClockwiseSign = 0;  // 上一帧手势方向（+1/-1/0），用于检测方向反转
  // 滑动窗口：记录每帧的 (角度增量, 耗时)，最终按"总角度/总耗时"算时间加权平均速度。
  // 不能直接对每帧瞬时速度(deltaDeg/dt)取算术平均——
  // dt 极小的噪声帧（触屏采样抖动，尤其在反转瞬间手指接近静止时信噪比最差）
  // 会被赋予和正常帧相同的权重，导致单帧噪声就把均值拉过阈值，
  // 即使整体动作很慢也会被误判为"快速"。
  final List<({double deg, double dt})> _velocityWindow = [];

  static const double _kSlowStep = 0.1;

  double get _stepSize {
    if (_velocityWindow.isEmpty) return _kSlowStep;
    var totalDeg = 0.0;
    var totalDt = 0.0;
    for (final sample in _velocityWindow) {
      totalDeg += sample.deg;
      totalDt += sample.dt;
    }
    if (totalDt <= 0) return _kSlowStep;
    final avgSpeed = totalDeg / totalDt;  // 时间加权平均速度
    return avgSpeed < widget.speedThreshold ? _kSlowStep : widget.fastStep;
  }

  double _halfRange(double currentWeight) {
    final w = currentWeight.clamp(1.0, double.infinity);
    return switch (widget.growthStage) {
      '雏鸟' => max(5.0, w * 0.30),
      '幼鸟' => max(3.0, w * 0.15),
      _      => max(2.0, w * 0.03),
    };
  }

  static double _arcRadius(Size size) =>
      (size.shortestSide * 0.38).clamp(100.0, 180.0);

  Offset _center(Size size) => Offset(
    widget.side == DialSide.left ? 0 : size.width,
    size.height / 2,
  );

  bool _inFastingZone(Offset pos, Size size) {
    final radius = _arcRadius(size);
    final btnRadius = (radius - 28.0).clamp(28.0, double.infinity);
    final btnCenter = _center(size);
    return (pos - btnCenter).distance < btnRadius + 2;
  }

  bool _onArc(Offset pos, Size size) {
    final c = _center(size);
    final dist = (pos - c).distance;
    return (dist - _arcRadius(size)).abs() < 56;
  }

  void _onPanStart(DragStartDetails d, Size size) {
    final pos = d.localPosition;
    if (_inFastingZone(pos, size)) return;
    if (_onArc(pos, size)) {
      _isTracking = true;
      _lastAngle = atan2(pos.dy - _center(size).dy, pos.dx - _center(size).dx);
      _lastUpdateTime = DateTime.now();
    }
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (!_isTracking) return;
    final pos = d.localPosition;
    final center = _center(size);
    final now = DateTime.now();
    final dt = now.difference(_lastUpdateTime!).inMicroseconds / 1e6;
    if (dt <= 0) return;

    final angle = atan2(pos.dy - center.dy, pos.dx - center.dx);
    var delta = angle - _lastAngle;
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;

    final deltaDeg = delta * 180 / pi;
    _lastAngle = angle;
    _lastUpdateTime = now;

    // 顺时针手势 → deltaDeg > 0(右弧)/< 0(左弧) → dialOffset 减少 → 绿点相对往上 → 体重相对上次增加
    final clockwise = widget.side == DialSide.right ? deltaDeg : -deltaDeg;

    // 方向反转检测：本帧方向与上一帧不同时，先清空速度窗口——
    // 避免反转前残留的速度样本（哪怕本身是噪声造成的）继续影响反转后的快慢判定，
    // 让反转后的判定尽快只反映新方向上的真实速度。
    final sign = clockwise > 0 ? 1.0 : (clockwise < 0 ? -1.0 : 0.0);
    if (sign != 0 && _lastClockwiseSign != 0 && sign != _lastClockwiseSign) {
      _velocityWindow.clear();
    }
    if (sign != 0) _lastClockwiseSign = sign;

    _velocityWindow.add((deg: deltaDeg.abs(), dt: dt));
    if (_velocityWindow.length > widget.windowSize) _velocityWindow.removeAt(0);
    setState(() => _dialOffset -= clockwise * pi / 180);

    // 步进触发
    _accumRaw += clockwise;
    final stepDeg = widget.sensitivity;
    while (_accumRaw.abs() >= stepDeg) {
      final dir = _accumRaw > 0 ? 1.0 : -1.0;
      final step = _stepSize;
      final currentW = double.tryParse(widget.weightText) ?? 0;
      final halfRange = _halfRange(currentW.clamp(1, double.infinity));

      widget.onDelta(dir * step);
      HapticFeedback.selectionClick();
      _accumRaw -= dir * stepDeg;

      // 体重变化了 step，等效角度变化 = step/halfRange*(π/2)
      // 同步 _dialOffset，避免和 lastWeightAngle 重复计算
      setState(() => _dialOffset += dir * step / halfRange * (pi / 2));
    }
  }

  void _onPanEnd(DragEndDetails d) {
    _isTracking = false;
    _lastUpdateTime = null;
    _accumRaw = 0;
    _lastClockwiseSign = 0;
    _velocityWindow.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.theme.colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final radius = _arcRadius(size);
      final center = _center(size);
      final isLeft = widget.side == DialSide.left;

      // 指针位置（canvas 角度）：左弧 → 0 (3点钟/右侧)，右弧 → π (9点钟/左侧)
      final tickCenter = isLeft ? 0.0 : pi;

      // 空腹按钮 — 与弧共圆心，半径缩进 28px 不重叠弧线
      final btnRadius = (radius - 28.0).clamp(28.0, double.infinity);
      final btnCenter = center; // 与弧共圆心

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (d) => _onPanStart(d, size),
        onPanUpdate: (d) => _onPanUpdate(d, size),
        onPanEnd: _onPanEnd,
        onVerticalDragStart: (d) => _onPanStart(d, size),
        onVerticalDragUpdate: (d) => _onPanUpdate(d, size),
        onVerticalDragEnd: _onPanEnd,
        child: Stack(
          children: [
            CustomPaint(
              size: size,
              painter: _DialArcPainter(
                side: widget.side,
                arcRadius: radius,
                center: center,
                isTracking: _isTracking,
                tickCenter: tickCenter,
                weightText: widget.weightText,
                sensitivity: widget.sensitivity,
                color: scheme.primary,
                trackColor: scheme.outlineVariant.withAlpha(60),
                pointerColor: scheme.primary,
              ),
            ),
            // 空腹按钮
            Positioned(
              left: btnCenter.dx - btnRadius,
              top: btnCenter.dy - btnRadius,
              child: GestureDetector(
                onTap: widget.onToggleFasting,
                child: Container(
                  width: btnRadius * 2,
                  height: btnRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isFasting
                        ? const Color(0xFFEAF3DE)
                        : const Color(0xFFFCEBEB),
                    border: Border.all(
                      color: widget.isFasting
                          ? const Color(0xFF639922)
                          : const Color(0xFFE24B4A),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isFasting
                            ? Icons.restaurant
                            : Icons.restaurant_menu,
                        size: 22,
                        color: widget.isFasting
                            ? const Color(0xFF3B6D11)
                            : const Color(0xFFA32D2D),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isFasting ? '空腹' : '非空腹',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: widget.isFasting
                              ? const Color(0xFF3B6D11)
                              : const Color(0xFFA32D2D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── 弧线绘制器 ─────────────────────────────────

class _DialArcPainter extends CustomPainter {
  final DialSide side;
  final double arcRadius;
  final Offset center;
  final bool isTracking;
  final double tickCenter;
  final String weightText;
  final double sensitivity;
  final Color color;
  final Color trackColor;
  final Color pointerColor;

  _DialArcPainter({
    required this.side,
    required this.arcRadius,
    required this.center,
    required this.isTracking,
    required this.tickCenter,
    this.weightText = '',
    required this.sensitivity,
    required this.color,
    required this.trackColor,
    required this.pointerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isLeft = side == DialSide.left;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);

    // 右弧：底→左→顶 (pi/2 → pi → 3*pi/2)，画在屏幕左侧
    // 左弧：顶→右→底 (3*pi/2 → 0 → pi/2)，画在屏幕右侧
    final startAngle = isLeft ? 3 * pi / 2 : pi / 2;
    const sweepAngle = pi;

    // ── 弧线轨道 ──
    canvas.drawArc(arcRect, startAngle, sweepAngle, false,
      Paint()
        ..color = isTracking ? color.withAlpha(100) : trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round);

    // ── 刻度线（以 tickCenter 为基准展开） ──
    final tickCount = (90 / sensitivity).round();
    for (var i = -tickCount; i <= tickCount; i++) {
      final angleDeg = i * sensitivity;
      final tickAngle = tickCenter + angleDeg * pi / 180;
      final isCenter = i == 0;
      final tickLen = isCenter ? 14.0 : (i % 3 == 0 ? 9.0 : 6.0);
      final outerR = arcRadius + tickLen / 2;
      final innerR = arcRadius - tickLen / 2;
      final dx = cos(tickAngle);
      final dy = sin(tickAngle);

      canvas.drawLine(
        Offset(center.dx + dx * outerR, center.dy + dy * outerR),
        Offset(center.dx + dx * innerR, center.dy + dy * innerR),
        Paint()
          ..color = isCenter
              ? color.withAlpha(200)
              : trackColor.withAlpha(isTracking ? 180 : 120)
          ..strokeWidth = isCenter ? 2.0 : 1.0,
      );
    }

    // ── 指针点 + 体重数字 ──
    final px = center.dx + cos(tickCenter) * arcRadius;
    final py = center.dy + sin(tickCenter) * arcRadius;
    canvas.drawCircle(Offset(px, py), 5.0,
      Paint()..color = pointerColor..style = PaintingStyle.fill);

    final displayText = weightText.isEmpty ? '0.0' : weightText;
    final tp = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: pointerColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    final textX = isLeft ? px + 10 : px - tp.width - 10;
    tp.paint(canvas, Offset(textX, py - tp.height / 2));

    final tpUnit = TextPainter(
      text: TextSpan(
        text: '克',
        style: TextStyle(fontSize: 11, color: pointerColor.withAlpha(160)),
      ),
      textDirection: TextDirection.ltr,
    );
    tpUnit.layout();
    tpUnit.paint(canvas, Offset(textX, py + tp.height / 2 - 2));
  }

  @override
  bool shouldRepaint(covariant _DialArcPainter old) =>
      side != old.side ||
      arcRadius != old.arcRadius ||
      center != old.center ||
      isTracking != old.isTracking ||
      tickCenter != old.tickCenter ||
      weightText != old.weightText ||
      sensitivity != old.sensitivity ||
      color != old.color ||
      trackColor != old.trackColor ||
      pointerColor != old.pointerColor;
}

// ═══════════════════════════════════════════════
// 数字键盘
// ═══════════════════════════════════════════════

/// 数字键盘 — 1-9 / . / 0 / ⌫
class WeighNumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final ThemeData theme;

  const WeighNumPad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 数字键 3×3 网格
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: SizedBox(
                      height: 42,
                      child: Material(
                        color: scheme.surfaceContainerHighest.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onDigit(key),
                          child: Center(
                            child: Text(
                              key,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          // 小数点 + 0 + 退格
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: SizedBox(
                    height: 42,
                    child: Material(
                      color: scheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onDigit('.'),
                        child: Center(
                          child: Text(
                            '.',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: SizedBox(
                    height: 42,
                    child: Material(
                      color: scheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onDigit('0'),
                        child: const Center(
                          child: Text(
                            '0',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: SizedBox(
                    height: 42,
                    child: Material(
                      color: scheme.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onDelete,
                        child: const Center(
                          child: Icon(Icons.backspace_outlined, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
