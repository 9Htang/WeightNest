import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_clock.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../providers.dart';
import '../../plugins/medication/medication_repository.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/enclosure_repository.dart';
import '../../repositories/room_repository.dart';
import '../../repositories/species_repository.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/weight_repository.dart';
import '../../utils/app_version.dart';
import 'db_inspector_screen.dart';
import 'plugin_status_screen.dart';
import 'log_viewer_screen.dart';
import 'task_editor_screen.dart';

class DebugDashboardScreen extends ConsumerStatefulWidget {
  const DebugDashboardScreen({super.key});

  @override
  ConsumerState<DebugDashboardScreen> createState() => _DebugDashboardScreenState();
}

class _DebugDashboardScreenState extends ConsumerState<DebugDashboardScreen> {
  bool _overridden = false;

  @override
  void initState() {
    super.initState();
    _overridden = AppClock.isOverridden;
  }

  void _onTimeControlTap() {
    showModalBottomSheet(
      context: context,
      builder: (_) => const _TimeControlSheet(),
    ).then((_) async {
      if (!mounted) return;
      // 只有确实应用了覆盖才触发生成
      if (AppClock.isOverridden) {
        try {
          await ref.read(databaseProvider).generateTodayTasks(force: true);
          ref.invalidate(todayTasksProvider);
          ref.invalidate(overdueTasksProvider);
        } catch (_) {}
      }
      setState(() => _overridden = AppClock.isOverridden);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('调试面板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 时间覆盖 Banner ──
          if (_overridden)
            _OverrideBanner(onReset: () async {
              await AppClock.reset();
              ref.invalidate(todayTasksProvider);
              ref.invalidate(overdueTasksProvider);
              setState(() => _overridden = false);
            }),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _ToolCard(
                  icon: Icons.storage,
                  label: '数据库检查器',
                  color: theme.colorScheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DbInspectorScreen()),
                  ),
                ),
                _ToolCard(
                  icon: Icons.extension,
                  label: '插件状态',
                  color: theme.colorScheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PluginStatusScreen()),
                  ),
                ),
                _ToolCard(
                  icon: Icons.article,
                  label: '日志查看器',
                  color: theme.colorScheme.tertiary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogViewerScreen()),
                  ),
                ),
                _ToolCard(
                  icon: Icons.assignment,
                  label: '任务编辑器',
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TaskEditorScreen()),
                  ),
                ),
                _ToolCard(
                  icon: Icons.access_time,
                  label: '时间控制',
                  color: Colors.orange,
                  onTap: _onTimeControlTap,
                ),
                _ToolCard(
                  icon: Icons.casino,
                  label: '随机生成鸟数据',
                  color: Colors.purple,
                  onTap: () => _onRandomBirdTap(context),
                ),
                _ToolCard(
                  icon: Icons.info_outline,
                  label: '应用信息',
                  color: Colors.teal,
                  onTap: () => _showAppInfo(context),
                ),
                _ToolCard(
                  icon: Icons.delete_forever,
                  label: '清空数据库',
                  color: Colors.red,
                  onTap: () => _onClearDatabaseTap(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<String>(
        future: getAppVersion(),
        builder: (_, snap) => AlertDialog(
          title: const Text('应用信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('版本', snap.data ?? '...'),
              const SizedBox(height: 4),
              _infoRow('构建模式', kDebugMode ? 'Debug' : 'Release'),
              const SizedBox(height: 4),
              _infoRow('插件数', '${pluginRegistry.plugins.length}'),
              const SizedBox(height: 4),
              _infoRow('启用插件数', '${pluginRegistry.enabledPlugins.length}'),
              const SizedBox(height: 4),
              _infoRow('DB 就绪', '${pluginRegistry.db != null}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  void _onRandomBirdTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RandomBirdSheet(
        onGenerated: () {
          ref.invalidate(allBirdsProvider);
          ref.invalidate(allRoomsProvider);
          ref.invalidate(todayTasksProvider);
          ref.invalidate(overdueTasksProvider);
          ref.invalidate(allSpeciesProvider);
        },
      ),
    );
  }

  Future<void> _onClearDatabaseTap(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 清空数据库'),
        content: const Text('这将删除所有数据（鸟、体重、任务、房间、容器、品种、喂药方案、繁育记录等），且不可恢复。\n\n确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final db = pluginRegistry.db;
    if (db == null) return;

    try {
      await db.transaction(() async {
        // 按 FK 安全顺序删除：先子表后父表
        await db.delete(db.activityLogs).go();
        await db.delete(db.alertRecords).go();
        await db.delete(db.syncQueue).go();
        await db.delete(db.breedingRecords).go();
        await db.delete(db.matingEvents).go();
        await db.delete(db.eggs).go();
        await db.delete(db.tasks).go();
        await db.delete(db.weights).go();
        await db.delete(db.medications).go();
        await db.delete(db.breedingPairs).go();
        await db.delete(db.birds).go();
        await db.delete(db.enclosures).go();
        await db.delete(db.rooms).go();
        await db.delete(db.species).go();
        await db.delete(db.users).go();
      });

      // 刷新全部相关 Provider
      ref.invalidate(allBirdsProvider);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(overdueTasksProvider);
      ref.invalidate(allRoomsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据库已清空'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清空失败: $e')),
        );
      }
    }
  }
}

// ── 调试：随机生成鹦鹉及体重数据 ──

class _RandomBirdSheet extends StatefulWidget {
  final VoidCallback? onGenerated;
  const _RandomBirdSheet({this.onGenerated});

  @override
  State<_RandomBirdSheet> createState() => _RandomBirdSheetState();
}

/// 调试生成的鸟角色——每种角色对应一套固定的体重生成策略，
/// 用于稳定触发 WeightPlugin / MedicationPlugin 的对应告警类型，
/// 便于在不依赖真实业务数据的情况下测试告警与任务系统。
enum _BirdRole {
  normalAdult,      // 正常成鸟：基线 ±3% 平稳波动
  overdueAdult,      // 严重超期未称重成鸟：最近记录停在 2.5x 间隔之前
  normalChick,       // 正常雏鸟：稳定增长
  decliningChick,    // 体重下降雏鸟：连续多次下降，触发"体重下降/连续下降"
  slowGrowthChick,   // 生长缓慢雏鸟：增长曲线明显低于正常斜率
  weaningDropJuvenile, // 断奶期骤降：幼鸟阶段末尾体重突然跳水
  baselineDeviationAdult, // 基线偏离成鸟：与手动基线差距过大
  noDataAdult,        // 长期无数据：90 天内无任何体重记录
}

class _RandomBirdSheetState extends State<_RandomBirdSheet> {
  int _birdCount = 12;
  bool _loading = false;
  String? _result;

  static const _names = [
    '小绿', '阿黄', '豆豆', '团子', '奶茶', '糯米', '芝麻', '花花',
    '胡椒', '可可', '布丁', '松饼', '泡芙', '拿铁', '抹茶', '焦糖',
    '雪球', '墨墨', '橘子', '柚子', '汤圆', '栗子', '南瓜', '冬瓜',
  ];
  static const _genders = ['雄', '雌', '未知'];
  static const _drugNames = ['阿莫西林', '恩诺沙星', '甲硝唑', '维生素B', '益生菌'];

  static const _speciesSeed = [
    ('虎皮鹦鹉', 30, 60, 1, 2, 7),
    ('玄凤鹦鹉', 35, 75, 1, 3, 7),
    ('牡丹鹦鹉', 28, 55, 1, 2, 7),
    ('金太阳鹦鹉', 40, 90, 1, 3, 7),
    ('小金刚鹦鹉', 60, 140, 2, 4, 10),
  ];

  Future<void> _generate() async {
    final db = pluginRegistry.db;
    if (db == null) return;
    setState(() { _loading = true; _result = null; });

    try {
      final rng = Random();
      final now = AppClock.now;

      // 1. 确保有足够的物种（仅在为空时播种，避免重复生成）
      var allSpecies = await db.getAllSpecies();
      if (allSpecies.isEmpty) {
        for (final s in _speciesSeed) {
          await db.createSpecies(
            s.$1,
            nestlingEndDays: s.$2,
            juvenileEndDays: s.$3,
            nestlingWeighIntervalDays: s.$4,
            juvenileWeighIntervalDays: s.$5,
            adultWeighIntervalDays: s.$6,
            createdAt: now,
            updatedAt: now,
          );
        }
        allSpecies = await db.getAllSpecies();
      }

      // 2. 按生成数量自适应房间数：避免所有鸟挤进同一个房间
      final roomCount = _birdCount <= 3
          ? 1
          : _birdCount <= 8
              ? 2
              : (3 + rng.nextInt(3)); // 9 只以上：3-5 间
      var allRooms = await db.getAllRooms();
      if (allRooms.length < roomCount) {
        for (int i = allRooms.length; i < roomCount; i++) {
          await db.createRoom('繁殖舍${i + 1}', createdAt: now, updatedAt: now);
        }
        allRooms = await db.getAllRooms();
      }
      // 只使用本次需要的房间数量（不影响用户已有的其它房间）
      final usableRooms = allRooms.take(roomCount).toList();

      // 3. 每个房间下确保有 1-3 个容器
      final roomEnclosures = <int, List<Enclosure>>{};
      const enclosureLabels = ['A区', 'B区', 'C区'];
      for (final room in usableRooms) {
        var encs = await db.getEnclosuresByRoom(room.id);
        if (encs.isEmpty) {
          final n = 1 + rng.nextInt(3); // 1-3 个
          for (int i = 0; i < n; i++) {
            await db.createEnclosure(enclosureLabels[i], room.id, createdAt: now, updatedAt: now);
          }
          encs = await db.getEnclosuresByRoom(room.id);
        }
        roomEnclosures[room.id] = encs;
      }

      // 4. 生成鸟：按角色轮询分布，确保覆盖所有告警类型
      final usedNames = <String>{};
      int birdsCreated = 0;
      int weightsCreated = 0;
      int medsCreated = 0;
      final roles = _BirdRole.values;

      for (int i = 0; i < _birdCount; i++) {
        String name;
        do {
          name = _names[rng.nextInt(_names.length)] +
              (rng.nextInt(9) + 1).toString();
        } while (usedNames.contains(name));
        usedNames.add(name);

        final role = roles[i % roles.length];
        final sp = allSpecies[rng.nextInt(allSpecies.length)];

        // 房间/容器分配：留一点概率不分配，覆盖"未分配"/"无容器"分组
        final unassignedChance = rng.nextDouble();
        Room? room;
        Enclosure? enc;
        if (unassignedChance > 0.08) {
          room = usableRooms[rng.nextInt(usableRooms.length)];
          final encs = roomEnclosures[room.id]!;
          // 5% 概率不放入具体容器，但仍属于该房间
          if (rng.nextDouble() > 0.05) {
            enc = encs[rng.nextInt(encs.length)];
          }
        }

        final birthDate = _birthForRole(role, sp, rng);

        final bird = await db.createBird(
          name: name,
          speciesId: sp.id,
          birthDate: birthDate,
          roomId: room?.id,
          enclosureId: enc?.id,
          gender: _genders[rng.nextInt(_genders.length)],
          createdAt: now,
          updatedAt: now,
        );
        birdsCreated++;

        weightsCreated += await _generateWeights(db, bird, role, sp, rng);

        // 20% 的成鸟角色自动配一个喂药方案（不再依赖手动开关）
        final isAdultRole = role == _BirdRole.normalAdult ||
            role == _BirdRole.overdueAdult ||
            role == _BirdRole.baselineDeviationAdult ||
            role == _BirdRole.noDataAdult;
        if (isAdultRole && rng.nextDouble() < 0.2) {
          final drug = _drugNames[rng.nextInt(_drugNames.length)];
          await db.addMedication(
            birdId: bird.id,
            drugName: drug,
            dosage: '${(rng.nextInt(4) + 1) * 5}mg',
            timesPerDay: rng.nextInt(2) + 1,
            // 4 天前开始，确保至少有一次服药窗口已过期但未标记完成，
            // 配合任务生成可触发"漏服药物"告警
            startDate: now.subtract(const Duration(days: 4)),
            createdAt: now,
            updatedAt: now,
          );
          medsCreated++;
        }
      }

      // 5. 生成今日任务（force=true 跳过节流，立即触发逾期标记）
      await db.generateTodayTasks(force: true);

      // 通知父级刷新所有受影响的 provider
      widget.onGenerated?.call();

      setState(() {
        _result = '完成：$birdsCreated 只鸟（分布于 ${usableRooms.length} 个房间），'
            '$weightsCreated 条体重记录'
            '${medsCreated > 0 ? "，$medsCreated 个喂药方案" : ""}\n'
            '已覆盖 8 种角色场景，告警应在下次检测时触发';
      });
    } catch (e, st) {
      setState(() { _result = '错误：$e\n$st'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  /// 根据角色生成合适的出生日期，使其落入对应的生命阶段。
  DateTime _birthForRole(_BirdRole role, Specy sp, Random rng) {
    int ageDays;
    switch (role) {
      case _BirdRole.normalChick:
      case _BirdRole.decliningChick:
      case _BirdRole.slowGrowthChick:
        // 雏鸟阶段中段，留出前后空间生成多条记录
        ageDays = (sp.nestlingEndDays * 0.4).round() +
            rng.nextInt((sp.nestlingEndDays * 0.4).round().clamp(1, 999));
        break;
      case _BirdRole.weaningDropJuvenile:
        // 幼鸟阶段末尾，靠近断奶节点
        ageDays = sp.juvenileEndDays - rng.nextInt(5) - 2;
        break;
      case _BirdRole.normalAdult:
      case _BirdRole.overdueAdult:
      case _BirdRole.baselineDeviationAdult:
      case _BirdRole.noDataAdult:
        ageDays = sp.juvenileEndDays + 30 + rng.nextInt(300);
        break;
    }
    return AppClock.now.subtract(Duration(days: ageDays.clamp(1, 3650)));
  }

  /// 按角色生成历史体重数据，返回写入的记录数。
  Future<int> _generateWeights(
    AppDatabase db,
    Bird bird,
    _BirdRole role,
    Specy sp,
    Random rng,
  ) async {
    final base = _baseWeight(role, sp, rng);
    int count = 0;

    Future<void> insert(double weightG, DateTime at) async {
      await db.addWeight(
        birdId: bird.id,
        weightG: double.parse(weightG.toStringAsFixed(1)),
        recordedAt: at,
        createdAt: at,
        updatedAt: at,
      );
      count++;
    }

    switch (role) {
      case _BirdRole.normalAdult:
      case _BirdRole.baselineDeviationAdult:
        // 21 天内每 7 天一条，平稳波动 ±3%
        for (int d = 21; d >= 0; d -= 7) {
          final w = base * (0.97 + rng.nextDouble() * 0.06);
          await insert(w, AppClock.now.subtract(Duration(days: d, hours: rng.nextInt(6))));
        }
        break;

      case _BirdRole.overdueAdult:
        // 最近一条停在 2.5x 周间隔之前，制造"超期未称重"
        for (int d = 35; d >= 18; d -= 7) {
          final w = base * (0.97 + rng.nextDouble() * 0.06);
          await insert(w, AppClock.now.subtract(Duration(days: d)));
        }
        break;

      case _BirdRole.normalChick:
        // 每日一条，稳定增长
        for (int d = 14; d >= 0; d -= 1) {
          final grown = base + (14 - d) * (base * 0.04);
          await insert(grown, AppClock.now.subtract(Duration(days: d, hours: rng.nextInt(4))));
        }
        break;

      case _BirdRole.decliningChick:
        // 前期正常增长，最近 4 天连续下降
        for (int d = 10; d >= 5; d -= 1) {
          final grown = base + (10 - d) * (base * 0.05);
          await insert(grown, AppClock.now.subtract(Duration(days: d)));
        }
        var last = base + 5 * (base * 0.05);
        for (int d = 4; d >= 0; d -= 1) {
          last *= (0.93 - rng.nextDouble() * 0.03); // 每次下降 4-7%
          await insert(last, AppClock.now.subtract(Duration(days: d)));
        }
        break;

      case _BirdRole.slowGrowthChick:
        // 增长斜率明显低于正常水平（正常约 4%/天，这里约 1%/天）
        for (int d = 14; d >= 0; d -= 1) {
          final grown = base + (14 - d) * (base * 0.01);
          await insert(grown, AppClock.now.subtract(Duration(days: d, hours: rng.nextInt(4))));
        }
        break;

      case _BirdRole.weaningDropJuvenile:
        // 断奶前正常，断奶节点附近骤降 10-15%
        for (int d = 10; d >= 4; d -= 2) {
          final w = base * (0.98 + rng.nextDouble() * 0.04);
          await insert(w, AppClock.now.subtract(Duration(days: d)));
        }
        for (int d = 3; d >= 0; d -= 1) {
          final w = base * (0.85 - rng.nextDouble() * 0.05);
          await insert(w, AppClock.now.subtract(Duration(days: d)));
        }
        break;

      case _BirdRole.noDataAdult:
        // 仅一条 100 天前的记录，之后再无数据
        await insert(base, AppClock.now.subtract(const Duration(days: 100)));
        break;
    }
    return count;
  }

  /// 角色对应的基线体重（克）。
  double _baseWeight(_BirdRole role, Specy sp, Random rng) {
    switch (role) {
      case _BirdRole.normalChick:
      case _BirdRole.decliningChick:
      case _BirdRole.slowGrowthChick:
        return 10.0 + rng.nextDouble() * 15;
      case _BirdRole.weaningDropJuvenile:
        return 30.0 + rng.nextDouble() * 20;
      case _BirdRole.baselineDeviationAdult:
        // 故意偏离"正常"基线 20% 以上
        return (40.0 + rng.nextDouble() * 60) * (rng.nextBool() ? 1.25 : 0.75);
      case _BirdRole.normalAdult:
      case _BirdRole.overdueAdult:
      case _BirdRole.noDataAdult:
        return 40.0 + rng.nextDouble() * 60;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('随机生成测试数据',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '自动按房间/容器分布，覆盖 8 种角色场景（正常/超期/下降/缓慢生长/'
            '断奶骤降/基线偏离/长期无数据），并按比例生成喂药方案',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // 生成鸟数
          Row(children: [
            const Text('鸟的数量：'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _birdCount,
              items: [1, 3, 8, 12, 20, 30]
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n 只')))
                  .toList(),
              onChanged: (v) => setState(() => _birdCount = v!),
            ),
          ]),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _generate,
              child: _loading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('开始生成'),
            ),
          ),

          if (_result != null) ...[
            const SizedBox(height: 12),
            Text(_result!,
                style: TextStyle(
                    color: _result!.startsWith('错误')
                        ? Colors.red
                        : Colors.green)),
          ],
        ],
      ),
    );
  }
}

class _OverrideBanner extends StatefulWidget {
  final VoidCallback onReset;

  const _OverrideBanner({required this.onReset});

  @override
  State<_OverrideBanner> createState() => _OverrideBannerState();
}

class _OverrideBannerState extends State<_OverrideBanner> {
  late final Timer _timer;
  String _display = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _tick() {
    setState(() => _display = _fmt(AppClock.now));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange.withAlpha(30),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade800, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '时间偏移: $_display',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: widget.onReset,
            icon: Icon(Icons.restore, size: 16, color: theme.colorScheme.error),
            label: Text('Reset', style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final y = dt.year, m = dt.month.toString().padLeft(2, '0'), d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0'), mm = dt.minute.toString().padLeft(2, '0'), ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }
}

class _TimeControlSheet extends StatefulWidget {
  const _TimeControlSheet();

  @override
  State<_TimeControlSheet> createState() => _TimeControlSheetState();
}

class _TimeControlSheetState extends State<_TimeControlSheet> {
  DateTime _picked = AppClock.now;

  void _pick() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _picked,
      firstDate: DateTime(2020),
      lastDate: AppClock.now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_picked),
    );
    if (time == null || !mounted) return;
    setState(() => _picked = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('时间控制', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('当前: ${_fmt(_picked)}', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(180), fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('选择日期时间'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AppClock.advance(const Duration(hours: 1));
                      setState(() => _picked = AppClock.now);
                      final db = pluginRegistry.db;
                      if (db != null) await db.generateTodayTasks(force: true);
                    },
                    icon: const Icon(Icons.fast_forward, size: 16),
                    label: const Text('快进 1h'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AppClock.advance(const Duration(days: 1));
                      setState(() => _picked = AppClock.now);
                      final db = pluginRegistry.db;
                      if (db != null) await db.generateTodayTasks(force: true);
                    },
                    icon: const Icon(Icons.skip_next, size: 16),
                    label: const Text('快进 1d'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AppClock.reset();
                      setState(() => _picked = AppClock.now);
                    },
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('重置为真实时间'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await AppClock.override(_picked);
                      Navigator.pop(context);
                    },
                    child: const Text('应用覆盖'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final y = dt.year, m = dt.month.toString().padLeft(2, '0'), d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0'), mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withAlpha(30),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
