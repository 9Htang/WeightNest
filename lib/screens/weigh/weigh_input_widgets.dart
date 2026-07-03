import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_tokens.dart';
import '../../theme/theme.dart';
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
    final sc = AppTheme.statusColors(scheme);
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
                label: Text(isFasting! ? '空腹' : '非空腹',
                    style: const TextStyle(fontSize: 12)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '克',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (isFasting != null) ...[
                const SizedBox(width: 2),
                Text(
                  isFasting! ? ' (空腹)' : ' (非空腹)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isFasting! ? sc.fasting : sc.notFasting,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(
            message!,
            style: TextStyle(
              color: message!.startsWith('✅') ? sc.success : sc.warning,
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
    final r = context.r;
    final a = context.a;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(r.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(a.low),
          ),
          borderRadius: BorderRadius.circular(r.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 转盘输入控件 — 仪表盘式半圆弧
// ═══════════════════════════════════════════════

/// 仪表盘转盘：大圆裁切圆弧 + 固定绿点 + 空腹按钮 + 旋转刻度
///
/// 几何模型（右手）：
///   W = p × SW               转盘横向宽度
///   R = k × W                大圆半径
///   cx = SW + R - W          圆心 x
///   cy = y_bottom - √(W(2R-W))  圆心 y
///   绿点固定在角度 π，位置 (SW - W, cy)
/// 左手模式为水平镜像，绿点固定在角度 0。
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
  final double screenWidth;
  final double screenHeight;
  final double dialWidthPercent;
  final double arcRadiusPercent;
  final double strokeWidth;
  final ValueChanged<double> onDelta;
  final ThemeData theme;

  const WeighDial({
    super.key,
    required this.side,
    required this.screenWidth,
    required this.screenHeight,
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
    this.dialWidthPercent = 0.25,
    this.arcRadiusPercent = 0.25,
    this.strokeWidth = 30,
    required this.onDelta,
    required this.theme,
  });

  @override
  State<WeighDial> createState() => _WeighDialState();
}

class _WeighDialState extends State<WeighDial> {
  double _dialOffset = 0; // 盘面旋转偏移（弧度），顺时针手势减少
  double _lastAngle = 0;
  bool _isTracking = false;
  DateTime? _lastUpdateTime;
  double _accumRaw = 0; // 累积未触发的原始角度
  double _lastClockwiseSign = 0; // 上一帧手势方向（+1/-1/0），用于检测方向反转
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
    final avgSpeed = totalDeg / totalDt; // 时间加权平均速度
    return avgSpeed < widget.speedThreshold ? _kSlowStep : widget.fastStep;
  }

  // ── 大圆裁切几何 ──
  // W = p × SW,  R = k × W
  // cx = rightEdge + R - W (右手), cy 已改为垂直居中 (size.height / 2)

  static double _sweep(double w, double r) {
    if (r <= 0 || w >= 2 * r) return pi; // 半圆兜底
    final ratio = 1 - w / r;
    return 2 * acos(ratio.clamp(-1.0, 1.0));
  }

  // 缓存几何值，避免每次 build/手势回调重算 sqrt/乘法
  double _cachedW = 0;
  double _cachedR = 0;
  double _lastSW = 0;
  double _lastSH = 0;

  double get _w {
    if (_lastSW != widget.screenWidth || _lastSH != widget.screenHeight) {
      _updateGeometry();
    }
    return _cachedW;
  }

  double get _r {
    if (_lastSW != widget.screenWidth || _lastSH != widget.screenHeight) {
      _updateGeometry();
    }
    return _cachedR;
  }

  void _updateGeometry() {
    _lastSW = widget.screenWidth;
    _lastSH = widget.screenHeight;
    _cachedW = widget.screenWidth * widget.dialWidthPercent;
    final r = widget.screenHeight * widget.arcRadiusPercent;
    _cachedR = r >= _cachedW ? r : _cachedW; // R 必须 ≥ W，否则几何不成立
  }

  bool _onArc(Offset pos, Size size, Offset arcCenter, double radius,
      double startA, double sweep) {
    final dist = (pos - arcCenter).distance;
    if ((dist - radius).abs() > 56) return false;
    // 判断角度是否在可见弧段内
    final angle = atan2(pos.dy - arcCenter.dy, pos.dx - arcCenter.dx);
    // 归一化角度差（用 mod 正确处理任意大小的角度偏移）
    var d = (angle - startA) % (2 * pi);
    if (d < 0) d += 2 * pi;
    return d <= sweep + 0.2; // 留一些容差
  }

  void _onPanStart(DragStartDetails d, Size size) {
    final pos = d.localPosition;
    final w = _w;
    final r = _r;
    final isRight = widget.side == DialSide.right;
    final cy = size.height / 2; // 弧线垂直居中
    final cx = isRight ? size.width + r - w : w - r;
    final arcCenter = Offset(cx, cy);
    final sweep = _sweep(w, r);
    final startAngle = isRight ? pi - sweep / 2 : -sweep / 2;

    if (_onArc(pos, size, arcCenter, r, startAngle, sweep)) {
      _isTracking = true;
      _lastAngle = atan2(pos.dy - cy, pos.dx - cx);
      _lastUpdateTime = DateTime.now();
    }
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (!_isTracking) return;
    final pos = d.localPosition;
    final w = _w;
    final r = _r;
    final isRight = widget.side == DialSide.right;
    final cy = size.height / 2; // 弧线垂直居中
    final cx = isRight ? size.width + r - w : w - r;
    final now = DateTime.now();
    final dt = now.difference(_lastUpdateTime!).inMicroseconds / 1e6;
    if (dt <= 0) return;

    final angle = atan2(pos.dy - cy, pos.dx - cx);
    var delta = angle - _lastAngle;
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;

    final deltaDeg = delta * 180 / pi;
    _lastAngle = angle;
    _lastUpdateTime = now;

    // 顺时针手势 → 右手增重 / 左手减重（几何镜像，左侧需取反）
    final clockwise = widget.side == DialSide.right ? deltaDeg : -deltaDeg;

    final sign = clockwise > 0 ? 1.0 : (clockwise < 0 ? -1.0 : 0.0);
    if (sign != 0 && _lastClockwiseSign != 0 && sign != _lastClockwiseSign) {
      _velocityWindow.clear();
    }
    if (sign != 0) _lastClockwiseSign = sign;

    _velocityWindow.add((deg: deltaDeg.abs(), dt: dt));
    if (_velocityWindow.length > widget.windowSize) _velocityWindow.removeAt(0);
    setState(() {
      _dialOffset = (_dialOffset - clockwise * pi / 180) % (2 * pi);
    });

    // 步进触发
    _accumRaw += clockwise;
    final stepDeg = widget.sensitivity;
    while (_accumRaw.abs() >= stepDeg) {
      final dir = _accumRaw > 0 ? 1.0 : -1.0;
      final step = _stepSize;

      widget.onDelta(dir * step);
      HapticFeedback.selectionClick();
      _accumRaw -= dir * stepDeg;

      // 每步回退一个刻度位
      setState(() {
        _dialOffset = (_dialOffset - dir * stepDeg * pi / 180) % (2 * pi);
      });
    }
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() {
      _isTracking = false;
      _lastUpdateTime = null;
      _accumRaw = 0;
      _lastClockwiseSign = 0;
      _velocityWindow.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.theme.colorScheme;
    final sc = AppTheme.statusColors(scheme);
    final isRight = widget.side == DialSide.right;

    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final w = _w;
      final r = _r;
      final cy = size.height / 2; // 弧线垂直居中
      final cx = isRight ? size.width + r - w : w - r;
      final sweepRad = _sweep(w, r);
      final dotAngle = isRight ? pi : 0.0;
      final arcCenter = Offset(cx, cy);

      // 体重文字区域（用于点击切换空腹）
      final dotX = cx + cos(dotAngle) * r;
      final dotY = cy + sin(dotAngle) * r;
      const textW = 80.0;
      const textH = 44.0;
      final textLeft = isRight
          ? (dotX - textW - 10).clamp(0.0, size.width - textW)
          : (dotX + 12).clamp(0.0, size.width - textW);
      final textTop = dotY - textH / 2;

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
                arcRadius: r,
                center: arcCenter,
                isTracking: _isTracking,
                dialOffset: _dialOffset,
                dotAngle: dotAngle,
                sweepAngleRad: sweepRad,
                strokeWidth: widget.strokeWidth,
                weightText: widget.weightText,
                isFasting: widget.isFasting,
                sensitivity: widget.sensitivity,
                color: scheme.primary,
                trackColor: scheme.outlineVariant.withAlpha(context.a.low),
                pointerColor: scheme.primary,
                fastingGreen: sc.fasting,
                fastingRed: sc.notFasting,
              ),
            ),
            // 体重数字区域 — 点击切换空腹
            Positioned(
              left: textLeft,
              top: textTop,
              width: textW,
              height: textH,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggleFasting,
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
  final double arcRadius;
  final Offset center;
  final bool isTracking;
  final double dialOffset;
  final double dotAngle;
  final double sweepAngleRad;
  final double strokeWidth;
  final String weightText;
  final bool isFasting;
  final double sensitivity;
  final Color color;
  final Color trackColor;
  final Color pointerColor;
  final Color fastingGreen;
  final Color fastingRed;

  _DialArcPainter({
    required this.arcRadius,
    required this.center,
    required this.isTracking,
    required this.dialOffset,
    required this.dotAngle,
    required this.sweepAngleRad,
    required this.strokeWidth,
    this.weightText = '',
    this.isFasting = false,
    required this.sensitivity,
    required this.color,
    required this.trackColor,
    required this.pointerColor,
    this.fastingGreen = const Color(0xFF639922),
    this.fastingRed = const Color(0xFFE24B4A),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);

    // 弧线固定在 dotAngle 不动，只有刻度随 dialOffset 旋转
    final startAngle = dotAngle - sweepAngleRad / 2;

    // ── 弧线轨道（统一颜色，不随 tracking 状态变化） ──
    canvas.drawArc(
        arcRect,
        startAngle,
        sweepAngleRad,
        false,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round);

    // ── 车轮纹理：密集小刻度随 dialOffset 旋转，转动时有明显视觉反馈 ──
    final halfSweepDeg = sweepAngleRad * 180 / pi / 2;
    const textureInterval = 3.0; // 每 3° 一条纹理线（比 sensitivity 15° 密 5 倍）
    final textureCount = (halfSweepDeg / textureInterval).round();
    final landmarkStep = sensitivity; // 地标刻度间距（由 sensitivity 决定）
    final landmarkDegs = <double>{};
    for (var d = -halfSweepDeg; d <= halfSweepDeg; d += landmarkStep) {
      landmarkDegs.add((d / landmarkStep).round() * landmarkStep);
    }

    // 先画密集纹理小刻度
    for (var i = -textureCount; i <= textureCount; i++) {
      final angleDeg = i * textureInterval;
      // 跳过地标刻度位置（后面用更长刻度重画）
      if ((angleDeg / landmarkStep).abs() % 1.0 < 1e-9) continue;
      final tickAngle = dotAngle + dialOffset + angleDeg * pi / 180;
      final tickLen = 3.0; // 短纹理线
      final outerR = arcRadius + tickLen / 2;
      final innerR = arcRadius - tickLen / 2;
      final dx = cos(tickAngle);
      final dy = sin(tickAngle);
      canvas.drawLine(
        Offset(center.dx + dx * outerR, center.dy + dy * outerR),
        Offset(center.dx + dx * innerR, center.dy + dy * innerR),
        Paint()
          ..color = trackColor.withAlpha(100)
          ..strokeWidth = 0.8,
      );
    }

    // 再画地标大刻度（每 sensitivity° 一条）
    final landmarkCount = (halfSweepDeg / landmarkStep).round();
    for (var i = -landmarkCount; i <= landmarkCount; i++) {
      final angleDeg = i * landmarkStep;
      final tickAngle = dotAngle + dialOffset + angleDeg * pi / 180;
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
          ..color = isCenter ? color.withAlpha(200) : trackColor.withAlpha(150)
          ..strokeWidth = isCenter ? 2.0 : 1.0,
      );
    }

    // ── 绿点：永远固定在 dotAngle ──
    final dotRadius = 5.0;
    final px = center.dx + cos(dotAngle) * arcRadius;
    final py = center.dy + sin(dotAngle) * arcRadius;
    canvas.drawCircle(
        Offset(px, py),
        dotRadius,
        Paint()
          ..color = pointerColor
          ..style = PaintingStyle.fill);

    // ── 体重数字：颜色根据空腹状态（绿=空腹，红=非空腹） ──
    final textColor = isFasting ? fastingGreen : fastingRed;
    final displayText = weightText.isEmpty ? '0.0' : weightText;
    final tp = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    // 文字靠绿点左侧
    final isLeftSide = dotAngle == 0.0;
    final textX = isLeftSide
        ? (px + 12).clamp(0.0, size.width - tp.width)
        : (px - tp.width - 10).clamp(0.0, double.infinity);
    tp.paint(canvas, Offset(textX, py - tp.height / 2));

    final tpUnit = TextPainter(
      text: TextSpan(
        text: '克',
        style: TextStyle(fontSize: 11, color: textColor.withAlpha(160)),
      ),
      textDirection: TextDirection.ltr,
    );
    tpUnit.layout();
    tpUnit.paint(canvas, Offset(textX, py + tp.height / 2 - 2));

    // 空腹/非空腹标签 — 紧接"克"右侧
    final tpFasting = TextPainter(
      text: TextSpan(
        text: isFasting ? ' (空腹)' : ' (非空腹)',
        style: TextStyle(fontSize: 11, color: textColor.withAlpha(160)),
      ),
      textDirection: TextDirection.ltr,
    );
    tpFasting.layout();
    tpFasting.paint(
        canvas, Offset(textX + tpUnit.width, py + tp.height / 2 - 2));
  }

  @override
  bool shouldRepaint(covariant _DialArcPainter old) =>
      arcRadius != old.arcRadius ||
      center != old.center ||
      isTracking != old.isTracking ||
      dialOffset != old.dialOffset ||
      dotAngle != old.dotAngle ||
      sweepAngleRad != old.sweepAngleRad ||
      strokeWidth != old.strokeWidth ||
      weightText != old.weightText ||
      isFasting != old.isFasting ||
      sensitivity != old.sensitivity ||
      color != old.color ||
      trackColor != old.trackColor ||
      pointerColor != old.pointerColor;
}

// ═══════════════════════════════════════════════
// 滑动条输入控件 — 横向刻度条替代转盘
// ═══════════════════════════════════════════════

/// 横向滑动条：可拖拽的刻度条 + 体重数字 + 空腹按钮
///
/// 手势向左滑减小体重，向右滑增大体重。
/// 速度阈值以上触发快速步进。
class WeighSlider extends StatefulWidget {
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

  const WeighSlider({
    super.key,
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
  State<WeighSlider> createState() => _WeighSliderState();
}

class _WeighSliderState extends State<WeighSlider> {
  double _trackOffset = 0;
  double _lastDx = 0;
  bool _isTracking = false;
  double _accumRaw = 0;
  double _lastSign = 0;
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
    final avgSpeed = totalDeg / totalDt;
    return avgSpeed < widget.speedThreshold ? _kSlowStep : widget.fastStep;
  }

  double _halfRange(double currentWeight) {
    final w = currentWeight.clamp(1.0, double.infinity);
    return switch (widget.growthStage) {
      '雏鸟' => max(5.0, w * 0.30),
      '幼鸟' => max(3.0, w * 0.15),
      _ => max(2.0, w * 0.03),
    };
  }

  void _onPanStart(DragStartDetails d) {
    _isTracking = true;
    _lastDx = d.localPosition.dx;
  }

  void _onPanUpdate(DragUpdateDetails d, double trackWidth) {
    if (!_isTracking || trackWidth <= 0) return;
    final dx = d.localPosition.dx;
    final delta = dx - _lastDx;
    _lastDx = dx;
    if (delta == 0) return;

    // Map pixel delta to "dial degree" equivalent:
    // full track width = 180° of dial range
    final degPerPixel = 180.0 / trackWidth;
    final deltaDeg = delta * degPerPixel;
    final absDeg = deltaDeg.abs();

    // Direction sign
    final sign = deltaDeg > 0 ? 1.0 : -1.0;
    if (_lastSign != 0 && sign != _lastSign) _velocityWindow.clear();
    _lastSign = sign;

    _velocityWindow.add((deg: absDeg, dt: 1 / 60)); // assume ~60fps
    if (_velocityWindow.length > widget.windowSize) _velocityWindow.removeAt(0);

    setState(() => _trackOffset += delta);

    // Step trigger
    final stepDeg = widget.sensitivity;
    _accumRaw += deltaDeg;
    while (_accumRaw.abs() >= stepDeg) {
      final dir = _accumRaw > 0 ? 1.0 : -1.0;
      final step = _stepSize;
      widget.onDelta(dir * step);
      HapticFeedback.selectionClick();
      _accumRaw -= dir * stepDeg;
    }
  }

  void _onPanEnd(DragEndDetails d) {
    _isTracking = false;
    _accumRaw = 0;
    _lastSign = 0;
    _velocityWindow.clear();
    setState(() => _trackOffset = 0); // snap back to center
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.theme.colorScheme;
    final sc = AppTheme.statusColors(scheme);
    final r = context.r;
    final displayText = widget.weightText.isEmpty ? '0.0' : widget.weightText;
    final currentW = double.tryParse(widget.weightText) ?? 0;
    final halfRange = _halfRange(currentW.clamp(1, double.infinity));

    return LayoutBuilder(builder: (context, constraints) {
      final trackWidth = constraints.maxWidth;
      final tickCount = (180 / widget.sensitivity).round();

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: _onPanStart,
        onPanUpdate: (d) => _onPanUpdate(d, trackWidth),
        onPanEnd: _onPanEnd,
        onHorizontalDragStart: _onPanStart,
        onHorizontalDragUpdate: (d) => _onPanUpdate(d, trackWidth),
        onHorizontalDragEnd: _onPanEnd,
        child: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── 体重数字 + 范围 ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (currentW - halfRange).toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 10, color: scheme.onSurfaceVariant),
                  ),
                  Expanded(
                    child: Text(
                      '$displayText g',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    (currentW + halfRange).toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 10, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── 刻度条 ──
              Row(
                children: [
                  Expanded(
                    child: CustomPaint(
                      size: Size(trackWidth, 18),
                      painter: _SliderTrackPainter(
                        tickCount: tickCount,
                        sensitivity: widget.sensitivity,
                        isTracking: _isTracking,
                        trackOffset: _trackOffset,
                        color: scheme.primary,
                        trackColor: scheme.outlineVariant.withAlpha(context.a.low),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 空腹按钮
                  GestureDetector(
                    onTap: widget.onToggleFasting,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r.lg),
                        color: widget.isFasting
                            ? sc.fastingBg
                            : sc.notFastingBg,
                        border: Border.all(
                          color: widget.isFasting
                              ? sc.fasting
                              : sc.notFasting,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isFasting
                                ? Icons.restaurant
                                : Icons.restaurant_menu,
                            size: 16,
                            color: widget.isFasting
                                ? sc.fasting
                                : sc.notFasting,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isFasting ? '空腹' : '非空腹',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.isFasting
                                  ? sc.fasting
                                  : sc.notFasting,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SliderTrackPainter extends CustomPainter {
  final int tickCount;
  final double sensitivity;
  final bool isTracking;
  final double trackOffset;
  final Color color;
  final Color trackColor;

  _SliderTrackPainter({
    required this.tickCount,
    required this.sensitivity,
    required this.isTracking,
    required this.trackOffset,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final trackPaint = Paint()
      ..color = isTracking ? color.withAlpha(100) : trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Horizontal track
    canvas.drawLine(
      Offset(4, midY),
      Offset(size.width - 4, midY),
      trackPaint,
    );

    // Center indicator (thumb)
    final cx = size.width / 2 + trackOffset;
    canvas.drawCircle(
      Offset(cx.clamp(8.0, size.width - 8), midY),
      8.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx.clamp(8.0, size.width - 8), midY),
      8.0,
      Paint()
        ..color = color.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Tick marks
    final spacing = (size.width - 16) / (tickCount * 2 + 1).clamp(1, 999);
    for (var i = -tickCount; i <= tickCount; i++) {
      final tx = cx + i * spacing * widgetSensitivityFactor();
      if (tx < 4 || tx > size.width - 4) continue;
      final isCenter = i == 0;
      final tickH = isCenter ? 14.0 : (i % 3 == 0 ? 9.0 : 6.0);
      canvas.drawLine(
        Offset(tx, midY - tickH / 2),
        Offset(tx, midY + tickH / 2),
        Paint()
          ..color = isCenter
              ? color.withAlpha(200)
              : trackColor.withAlpha(isTracking ? 180 : 120)
          ..strokeWidth = isCenter ? 2.0 : 1.0,
      );
    }
  }

  double widgetSensitivityFactor() => 1.0;

  @override
  bool shouldRepaint(covariant _SliderTrackPainter old) =>
      tickCount != old.tickCount ||
      isTracking != old.isTracking ||
      trackOffset != old.trackOffset ||
      color != old.color ||
      trackColor != old.trackColor;
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
    final sp = context.sp;
    final r = context.r;
    final a = context.a;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sp.lg),
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
              children: row
                  .map((key) => _numKey(context, key,
                      onTap: () => onDigit(key),
                      color: scheme.surfaceContainerHighest.withAlpha(a.medium)))
                  .toList(),
            ),
          // 小数点 + 0 + 退格
          Row(
            children: [
              _numKey(context, '.',
                  onTap: () => onDigit('.'),
                  color: scheme.surfaceContainerHighest.withAlpha(a.medium),
                  textColor: scheme.primary),
              _numKey(context, '0',
                  onTap: () => onDigit('0'),
                  color: scheme.surfaceContainerHighest.withAlpha(a.medium)),
              _numKey(context, null,
                  onTap: onDelete,
                  color: scheme.error.withAlpha(a.subtle)),
            ],
          ),
        ],
      ),
    );
  }

  /// 数字键盘按键。label 为 null 时显示退格图标。
  Widget _numKey(BuildContext context, String? label,
      {required VoidCallback onTap,
      required Color color,
      Color? textColor}) {
    final r = context.r;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SizedBox(
          height: 42,
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(r.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(r.xl),
              onTap: onTap,
              child: Center(
                child: label == null
                    ? const Icon(Icons.backspace_outlined, size: 20)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
