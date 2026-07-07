import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_clock.dart';
import '../../database/database.dart';
import '../../core/plugin_registry.dart';
import '../../providers.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/weight_repository.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/enclosure_repository.dart';
import '../../plugins/weight/weight_plugin.dart';
import '../../repositories/room_repository.dart';

/// 表格列中的编组 — 容器标题 + 下属鸟列表
class BirdGroup {
  final EnclosureWithCount? enclosure; // null = 无容器
  final List<BirdWithDetails> birds;

  const BirdGroup({this.enclosure, required this.birds});

  String get label => enclosure?.enclosure.name ?? '无容器';
}

/// 表格中的一列
class RoomColumn {
  final Room? room; // null = 未分配房间
  final List<BirdGroup> groups;

  const RoomColumn({this.room, required this.groups});

  String get title => room?.name ?? '未分配';
  bool get isEmpty => groups.every((g) => g.birds.isEmpty);
}

/// 称重表格状态
class WeighGridState {
  final List<RoomColumn> columns;
  final List<int> birdOrder;
  final int? selectedBirdId;
  final String weightText;
  final bool isFasting;
  final bool isSaving;
  final String? message;
  final Weight? lastWeigh;
  final int todayCompleted;
  final Map<int, AbnormalDirection> abnormalDirections; // 体重异常方向
  final Set<int> weighedTodayBirdIds; // 今日已称
  final Set<int> overdueBirdIds; // 超期未称
  final Set<int> weaningBirdIds;
  final Map<int, Weight?> latestWeights;
  final Map<int, BirdWithDetails> birdById;
  final bool isInitialized;

  const WeighGridState({
    this.columns = const [],
    this.birdOrder = const [],
    this.selectedBirdId,
    this.weightText = '',
    this.isFasting = true,
    this.isSaving = false,
    this.message,
    this.lastWeigh,
    this.todayCompleted = 0,
    this.abnormalDirections = const {},
    this.weighedTodayBirdIds = const {},
    this.overdueBirdIds = const {},
    this.weaningBirdIds = const {},
    this.latestWeights = const {},
    this.birdById = const {},
    this.isInitialized = false,
  });

  /// 向后兼容：任意方向的异常鸟 ID 集合
  Set<int> get abnormalBirdIds => abnormalDirections.keys.toSet();

  WeighGridState copyWith({
    List<RoomColumn>? columns,
    List<int>? birdOrder,
    int? selectedBirdId,
    String? weightText,
    bool? isFasting,
    bool? isSaving,
    String? message,
    Weight? lastWeigh,
    int? todayCompleted,
    Map<int, AbnormalDirection>? abnormalDirections,
    Set<int>? weighedTodayBirdIds,
    Set<int>? overdueBirdIds,
    Set<int>? weaningBirdIds,
    Map<int, Weight?>? latestWeights,
    Map<int, BirdWithDetails>? birdById,
    bool? isInitialized,
    bool clearSelected = false,
    bool clearLastWeigh = false,
  }) =>
      WeighGridState(
        columns: columns ?? this.columns,
        birdOrder: birdOrder ?? this.birdOrder,
        selectedBirdId:
            clearSelected ? null : (selectedBirdId ?? this.selectedBirdId),
        weightText: weightText ?? this.weightText,
        isFasting: isFasting ?? this.isFasting,
        isSaving: isSaving ?? this.isSaving,
        message: message,
        lastWeigh: clearLastWeigh ? null : (lastWeigh ?? this.lastWeigh),
        todayCompleted: todayCompleted ?? this.todayCompleted,
        abnormalDirections: abnormalDirections ?? this.abnormalDirections,
        weighedTodayBirdIds: weighedTodayBirdIds ?? this.weighedTodayBirdIds,
        overdueBirdIds: overdueBirdIds ?? this.overdueBirdIds,
        weaningBirdIds: weaningBirdIds ?? this.weaningBirdIds,
        latestWeights: latestWeights ?? this.latestWeights,
        birdById: birdById ?? this.birdById,
        isInitialized: isInitialized ?? this.isInitialized,
      );
}

/// 称重表格控制器
class WeighGridNotifier extends StateNotifier<WeighGridState> {
  final AppDatabase _db;
  int? _userId;
  final void Function(int birdId)? _onWeightSaved;

  WeighGridNotifier(this._db, {void Function(int birdId)? onWeightSaved})
      : _onWeightSaved = onWeightSaved,
        super(const WeighGridState());

  void setUserId(int? id) => _userId = id;

  // ═══════════════════════════════════════════════
  // 初始化
  // ═══════════════════════════════════════════════

  Future<void> init({
    int? initialRoomId,
    int? initialEnclosureId,
    int? initialBirdId,
  }) async {
    // 1. 并行加载全部基础数据（三表无依赖，Future.wait 消除串行等待）
    final results = await Future.wait([
      _db.getAllWithDetails(),
      _db.getAllRooms(),
      _db.getAllEnclosureCounts(),
    ]);
    final allBirds = results[0] as List<BirdWithDetails>;
    final allRooms = (results[1] as List<Room>)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final allEnclosures = results[2] as Map<int, List<EnclosureWithCount>>;
    for (final r in allRooms) {
      allEnclosures.putIfAbsent(r.id, () => []);
    }

    // 2. 构建列结构
    final columns = <RoomColumn>[];
    final birdOrder = <int>[];

    // 辅助：按容器分组的函数
    List<BirdGroup> buildGroups(List<BirdWithDetails> birds, int? roomId) {
      final encs = roomId != null
          ? (allEnclosures[roomId] ?? [])
          : <EnclosureWithCount>[];
      final encMap = <int, EnclosureWithCount>{
        for (final e in encs) e.enclosure.id: e
      };

      // 分组：无容器 + 各容器
      final noEnc = birds.where((b) => b.bird.enclosureId == null).toList();
      noEnc.sort((a, b) => a.bird.sortOrder.compareTo(b.bird.sortOrder));

      final byEnc = <int, List<BirdWithDetails>>{};
      for (final b in birds) {
        if (b.bird.enclosureId != null) {
          byEnc.putIfAbsent(b.bird.enclosureId!, () => []).add(b);
        }
      }

      // 容器按 sortOrder 排序
      final sortedEncIds = byEnc.keys.toList()
        ..sort((a, b) {
          final ea = encMap[a]?.enclosure.sortOrder ?? 0;
          final eb = encMap[b]?.enclosure.sortOrder ?? 0;
          return ea.compareTo(eb);
        });

      final groups = <BirdGroup>[];
      if (noEnc.isNotEmpty) {
        groups.add(BirdGroup(birds: noEnc));
      }
      for (final eid in sortedEncIds) {
        final list = byEnc[eid]!;
        list.sort((a, b) => a.bird.sortOrder.compareTo(b.bird.sortOrder));
        groups.add(BirdGroup(enclosure: encMap[eid], birds: list));
      }
      return groups;
    }

    // 未分配列
    final unassigned = allBirds.where((b) => b.bird.roomId == null).toList();
    if (unassigned.isNotEmpty) {
      final groups = buildGroups(unassigned, null);
      columns.add(RoomColumn(groups: groups));
    }

    // 各房间列
    for (final room in allRooms) {
      final roomBirds =
          allBirds.where((b) => b.bird.roomId == room.id).toList();
      final groups = buildGroups(roomBirds, room.id);
      columns.add(RoomColumn(room: room, groups: groups));
    }

    // 构建鸟顺序
    for (final col in columns) {
      for (final group in col.groups) {
        for (final bird in group.birds) {
          birdOrder.add(bird.bird.id);
        }
      }
    }

    final birdById = {for (final b in allBirds) b.bird.id: b};
    state = state.copyWith(
        columns: columns, birdOrder: birdOrder, birdById: birdById);

    // 3. 批量计算异常方向 / 断奶期 / 今日已称 / 超期
    final now = AppClock.now;
    final todayDay = DateTime(now.year, now.month, now.day);
    final cutoff = now.subtract(const Duration(days: 90));
    final weightsByBird = await _db.getByBirdsInRange(
      allBirds.map((b) => b.bird.id).toList(),
      from: cutoff,
      to: now,
    );

    final abnormalDirections = <int, AbnormalDirection>{};
    final weaningIds = <int>{};
    final weighedTodayIds = <int>{};
    final overdueIds = <int>{};

    for (final bird in allBirds) {
      final weights = weightsByBird[bird.bird.id] ?? const <Weight>[];

      // 异常方向
      if (weights.isNotEmpty) {
        final dir = isLatestAbnormalDirection(bird, weights.reversed.toList());
        if (dir != AbnormalDirection.none) {
          abnormalDirections[bird.bird.id] = dir;
        }
      }

      // 断奶期
      if (isWeaningPhase(bird, weights)) {
        weaningIds.add(bird.bird.id);
      }

      // 今日已称：最新称重日期 == 今天
      if (weights.isNotEmpty) {
        final latestDay = DateTime(
          weights.last.recordedAt.year,
          weights.last.recordedAt.month,
          weights.last.recordedAt.day,
        );
        if (latestDay == todayDay) {
          weighedTodayIds.add(bird.bird.id);
        }
      }

      // 超期：距上次称重 > 间隔 × 1.5
      if (weights.isNotEmpty) {
        final daysSince = now.difference(weights.last.recordedAt).inDays;
        final interval = bird.effectiveWeighIntervalDays;
        if (interval > 0 && daysSince > interval * 1.5) {
          overdueIds.add(bird.bird.id);
        }
      } else {
        // 90 天无数据也视为超期
        overdueIds.add(bird.bird.id);
      }
    }

    state = state.copyWith(
      abnormalDirections: abnormalDirections,
      weaningBirdIds: weaningIds,
      weighedTodayBirdIds: weighedTodayIds,
      overdueBirdIds: overdueIds,
    );

    // 3.5 批量加载最新体重
    if (birdOrder.isNotEmpty) {
      final latestMap = await _db.getLatestByBirds(birdOrder);
      state = state.copyWith(latestWeights: latestMap);
    }

    // 4. 确定初始选中鸟
    int? targetBirdId = initialBirdId;
    if (targetBirdId == null && initialEnclosureId != null) {
      // 容器称重入口 → 选中该容器第一只鸟
      for (final col in columns) {
        for (final g in col.groups) {
          if (g.enclosure?.enclosure.id == initialEnclosureId) {
            targetBirdId = g.birds.firstOrNull?.bird.id;
            break;
          }
        }
      }
    }
    if (targetBirdId == null && initialRoomId != null) {
      // 房间称重入口 → 选中该房间第一只鸟
      for (final col in columns) {
        if (col.room?.id == initialRoomId) {
          for (final g in col.groups) {
            targetBirdId = g.birds.firstOrNull?.bird.id;
            if (targetBirdId != null) break;
          }
          break;
        }
      }
    }

    if (targetBirdId != null) {
      await _loadAndSelectBird(targetBirdId);
    }

    // 5. 标记初始化完成（用于 UI 区分加载中 / 无数据）
    state = state.copyWith(isInitialized: true);
  }

  // ═══════════════════════════════════════════════
  // 选中 / 取消
  // ═══════════════════════════════════════════════

  Future<void> selectBird(int birdId) async {
    if (state.selectedBirdId == birdId) {
      deselectBird();
      return;
    }
    await _loadAndSelectBird(birdId);
  }

  Future<void> _loadAndSelectBird(int birdId) async {
    // 乐观 UI：立即写入 selectedBirdId，让面板展开动画与 DB 查询并行。
    // 查询未回填前 lastWeigh=null / weightText=''，面板会显示占位（见 WeighDisplay）。
    state = state.copyWith(
      selectedBirdId: birdId,
      lastWeigh: null,
      weightText: '',
      isFasting: true,
      message: null,
    );
    // 动画期间（约 250ms）并行查最新体重，完成后再回填输入态。
    final lastW = await _db.getLatestByBird(birdId);
    // 用户在查询期间可能已切到别的鸟或取消，丢弃过期结果。
    if (state.selectedBirdId != birdId) return;
    state = state.copyWith(
      lastWeigh: lastW,
      weightText: lastW != null ? lastW.weightG.toStringAsFixed(1) : '',
    );
  }

  void deselectBird() {
    state = state.copyWith(
      clearSelected: true,
      clearLastWeigh: true,
      weightText: '',
      isFasting: true,
      message: null,
    );
  }

  // ═══════════════════════════════════════════════
  // 输入
  // ═══════════════════════════════════════════════

  void appendDigit(String digit) {
    if (digit == '.' && state.weightText.contains('.')) return;
    if (state.weightText.length >= 6) return;
    // 只允许一位小数
    final dot = state.weightText.indexOf('.');
    if (dot >= 0 && state.weightText.length - dot > 1) return;
    state = state.copyWith(weightText: state.weightText + digit, message: null);
  }

  void deleteDigit() {
    if (state.weightText.isEmpty) return;
    state = state.copyWith(
        weightText: state.weightText.substring(0, state.weightText.length - 1),
        message: null);
  }

  void clearWeight() {
    state = state.copyWith(weightText: '', isFasting: true, message: null);
  }

  void setFasting(bool v) => state = state.copyWith(isFasting: v);

  void adjustWeight(double delta) {
    final current = double.tryParse(state.weightText) ?? 0;
    final newVal =
        (current + delta).clamp(0.0, double.infinity).toStringAsFixed(1);
    state = state.copyWith(weightText: newVal, message: null);
  }

  // ═══════════════════════════════════════════════
  // 保存
  // ═══════════════════════════════════════════════

  Future<void> saveWeight() async {
    final birdId = state.selectedBirdId;
    if (birdId == null) return;
    final w = double.tryParse(state.weightText);
    if (w == null || w <= 0) {
      state = state.copyWith(message: '请输入有效体重');
      return;
    }

    state = state.copyWith(isSaving: true);

    final now = AppClock.now;

    // 定向查找该鸟今日待完成称重任务（单表 WHERE，不 JOIN 5 表）
    final pendingTask = await _db.getTodayPendingTask(birdId, 'weigh');

    // 原子写入：Weights + ActivityLogs + 完成任务（单事务，防崩溃不一致）
    late final Weight savedWeight;
    await _db.transaction(() async {
      savedWeight = await _db.addWeight(
        birdId: birdId,
        weightG: w,
        recordedAt: now,
        recordedBy: _userId,
        isFasting: state.isFasting,
      );

      await pluginRegistry.operationService.recordInTransaction(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        birdId: birdId,
        summary: '称重: ${w.toStringAsFixed(1)}g',
        details: {
          'weightG': w,
          'isFasting': state.isFasting,
          'weightId': savedWeight.id,
        },
        relatedTaskId: pendingTask?.id,
        operatedBy: _userId,
      );
    });

    _onWeightSaved?.call(birdId);

    final done = await _db.getTodayCompletedCount() +
        (pendingTask != null ? 1 : 0);

    // 即时更新最新体重显示，无需重新加载整个页面
    final updatedLatestWeights = Map<int, Weight?>.from(state.latestWeights);
    updatedLatestWeights[birdId] = savedWeight;

    // 即时更新"今日已称" + 移除"超期"
    final updatedWeighedToday = Set<int>.from(state.weighedTodayBirdIds)
      ..add(birdId);
    final updatedOverdue = Set<int>.from(state.overdueBirdIds)..remove(birdId);

    state = state.copyWith(
      isSaving: false,
      todayCompleted: done,
      latestWeights: updatedLatestWeights,
      weighedTodayBirdIds: updatedWeighedToday,
      overdueBirdIds: updatedOverdue,
    );

    // 自动跳下一只
    _advanceToNext();
  }

  void _advanceToNext() {
    final currentId = state.selectedBirdId;
    if (currentId == null || state.birdOrder.isEmpty) return;

    final curIdx = state.birdOrder.indexOf(currentId);
    if (curIdx < 0 || curIdx >= state.birdOrder.length - 1) {
      // 全部完成
      state = state.copyWith(
        clearSelected: true,
        clearLastWeigh: true,
        weightText: '',
        isFasting: true,
        message: '✅ 全部完成！',
      );
      return;
    }

    final nextId = state.birdOrder[curIdx + 1];
    // 异步选中下一只（不阻塞当前保存返回）
    Future.microtask(() => _loadAndSelectBird(nextId));
  }
}

/// Riverpod Provider
final weighGridProvider =
    StateNotifierProvider<WeighGridNotifier, WeighGridState>((ref) {
  final db = ref.watch(databaseProvider);

  // debounce 计时器：连续保存时合并为一次 alert 检测
  Timer? alertDebounce;
  // 记录 debounce 窗口内保存过的 birdId 集合
  final debouncedBirdIds = <int>{};

  return WeighGridNotifier(db, onWeightSaved: (int birdId) {
    // 1) 细粒度通知：标记该鸟变化
    ref.read(weightSavedBirdsProvider.notifier).notifySaved(birdId);

    // 2) debounce alert 检测：连续保存只触发一次全量 alert 刷新
    debouncedBirdIds.add(birdId);
    alertDebounce?.cancel();
    alertDebounce = Timer(const Duration(seconds: 2), () {
      alertDebounce = null;
      if (debouncedBirdIds.isNotEmpty) {
        debouncedBirdIds.clear();
        ref.invalidate(rawAlertsProvider);
      }
    });
  });
});
