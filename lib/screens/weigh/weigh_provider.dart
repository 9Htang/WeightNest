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
import '../../repositories/room_repository.dart';

/// 称重流程状态
class WeighState {
  final List<BirdWithDetails> birds;
  final int currentIndex;
  final String weightText;
  final bool isFasting;
  final bool isSaving;
  final String? message;
  final Map<int, Weight?> latestWeights;
  final int todayCompleted;

  // Navigation breadcrumbs (for UI display)
  final String? roomName;
  final String? enclosureName;
  final bool hasPrevRoom;
  final bool hasNextRoom;
  final bool hasPrevEnclosure;
  final bool hasNextEnclosure;

  WeighState({
    required this.birds,
    this.currentIndex = 0,
    this.weightText = '',
    this.isFasting = true,
    this.isSaving = false,
    this.message,
    this.latestWeights = const {},
    this.todayCompleted = 0,
    this.roomName,
    this.enclosureName,
    this.hasPrevRoom = false,
    this.hasNextRoom = false,
    this.hasPrevEnclosure = false,
    this.hasNextEnclosure = false,
  });

  BirdWithDetails? get currentBird =>
      birds.isNotEmpty ? birds[currentIndex] : null;

  bool get hasNext => currentIndex < birds.length - 1;
  bool get hasPrev => currentIndex > 0;

  WeighState copyWith({
    List<BirdWithDetails>? birds,
    int? currentIndex,
    String? weightText,
    bool? isFasting,
    bool? isSaving,
    String? message,
    Map<int, Weight?>? latestWeights,
    int? todayCompleted,
    String? roomName,
    String? enclosureName,
    bool? hasPrevRoom,
    bool? hasNextRoom,
    bool? hasPrevEnclosure,
    bool? hasNextEnclosure,
  }) =>
      WeighState(
        birds: birds ?? this.birds,
        currentIndex: currentIndex ?? this.currentIndex,
        weightText: weightText ?? this.weightText,
        isFasting: isFasting ?? this.isFasting,
        isSaving: isSaving ?? this.isSaving,
        message: message,
        latestWeights: latestWeights ?? this.latestWeights,
        todayCompleted: todayCompleted ?? this.todayCompleted,
        roomName: roomName ?? this.roomName,
        enclosureName: enclosureName ?? this.enclosureName,
        hasPrevRoom: hasPrevRoom ?? this.hasPrevRoom,
        hasNextRoom: hasNextRoom ?? this.hasNextRoom,
        hasPrevEnclosure: hasPrevEnclosure ?? this.hasPrevEnclosure,
        hasNextEnclosure: hasNextEnclosure ?? this.hasNextEnclosure,
      );
}

/// 称重流程控制器 — 支持三层导航（房间 / 容器 / 鸟）
class WeighNotifier extends StateNotifier<WeighState> {
  final AppDatabase _db;
  int? _userId;
  final void Function(int birdId)? _onWeightSaved;

  // ── 层级上下文（不在 state 中，内部使用） ──
  List<Room> _rooms = [];
  Map<int, List<EnclosureWithCount>> _enclosuresByRoom = {};
  int _roomIdx = 0;
  int _enclosureIdx = -1; // -1 = 无容器筛选（该房间全部鸟）

  // ── 搜索状态 ──
  String _searchQuery = '';
  List<int> _filteredIndices = [];

  WeighNotifier(this._db, {void Function(int birdId)? onWeightSaved})
      : _onWeightSaved = onWeightSaved,
        super(WeighState(birds: []));

  void setUserId(int? id) => _userId = id;

  // ═══════════════════════════════════════════════
  // 初始化加载
  // ═══════════════════════════════════════════════

  /// 加载完整层级结构 + 当前鸟列表
  Future<void> loadBirds({
    int? roomId,
    int? enclosureId,
    int? birdId,
  }) async {
    // 1. 加载所有房间（含空房间，确保空房间/空容器称重不跳转）
    _rooms = await _db.getAllRooms();
    _rooms.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // 2. 批量加载所有房间的容器（单条 SQL，含空容器）
    _enclosuresByRoom = await _db.getAllEnclosureCounts();
    for (final r in _rooms) {
      _enclosuresByRoom.putIfAbsent(r.id, () => []);
    }

    // 3. 确定初始位置并加载鸟列表
    if (enclosureId != null) {
      final enc = await _db.getEnclosureById(enclosureId);
      if (enc != null) {
        _roomIdx = _rooms.indexWhere((r) => r.id == enc.roomId);
        if (_roomIdx < 0) _roomIdx = 0;
        final encs = _enclosuresByRoom[_rooms[_roomIdx].id] ?? [];
        _enclosureIdx = encs.indexWhere((e) => e.enclosure.id == enclosureId);
        if (_enclosureIdx < 0) _enclosureIdx = -1;
      } else {
        _roomIdx = 0;
        _enclosureIdx = -1;
      }
    } else if (roomId != null) {
      _roomIdx = _rooms.indexWhere((r) => r.id == roomId);
      if (_roomIdx < 0) _roomIdx = 0;
      _enclosureIdx = -1;
    } else {
      _roomIdx = 0;
      _enclosureIdx = -1;
    }

    await _loadCurrentBirds(birdId: birdId);
  }

  /// 加载当前房间/容器下的鸟列表
  Future<void> _loadCurrentBirds({int? birdId}) async {
    if (_rooms.isEmpty) {
      state = state.copyWith(
          birds: [],
          roomName: null,
          enclosureName: null,
          hasPrevRoom: false,
          hasNextRoom: false,
          hasPrevEnclosure: false,
          hasNextEnclosure: false);
      return;
    }

    final room = _rooms[_roomIdx];
    List<BirdWithDetails> birds;

    if (_enclosureIdx >= 0) {
      // 有容器：加载该容器的鸟
      final encs = _enclosuresByRoom[room.id] ?? [];
      if (encs.isNotEmpty && _enclosureIdx < encs.length) {
        final enc = encs[_enclosureIdx];
        birds = await _db.getByEnclosure(enc.enclosure.id);
      } else {
        birds = await _db.getByRoom(room.id);
      }
    } else {
      // 无容器：加载该房间全部鸟
      birds = await _db.getByRoom(room.id);
    }

    // 获取最新体重
    final weights =
        await _db.getLatestByBirds(birds.map((b) => b.bird.id).toList());

    final enclosureName = _currentEnclosureName();
    final encs = _enclosuresByRoom[room.id] ?? [];
    final hasEncs = encs.isNotEmpty;

    // 搜索过滤
    _searchQuery = '';
    _filteredIndices = [];

    final firstWeight = birds.isNotEmpty ? weights[birds.first.bird.id] : null;

    // 目标鸟索引
    int idx = 0;
    if (birdId != null) {
      final bi = birds.indexWhere((b) => b.bird.id == birdId);
      if (bi >= 0) idx = bi;
    }

    state = state.copyWith(
      birds: birds,
      currentIndex: idx,
      latestWeights: weights,
      weightText:
          firstWeight != null ? firstWeight.weightG.toStringAsFixed(1) : '',
      isFasting: true,
      message: null,
      roomName: room.name,
      enclosureName: enclosureName,
      hasPrevRoom: _roomIdx > 0,
      hasNextRoom: _roomIdx < _rooms.length - 1,
      hasPrevEnclosure: hasEncs && (_enclosureIdx > 0 || _roomIdx > 0),
      hasNextEnclosure: hasEncs &&
          (_enclosureIdx < encs.length - 1 || _roomIdx < _rooms.length - 1),
    );
  }

  String? _currentEnclosureName() {
    if (_rooms.isEmpty || _enclosureIdx < 0) return null;
    final room = _rooms[_roomIdx];
    final encs = _enclosuresByRoom[room.id] ?? [];
    if (_enclosureIdx < encs.length) return encs[_enclosureIdx].enclosure.name;
    return null;
  }

  // ═══════════════════════════════════════════════
  // 导航
  // ═══════════════════════════════════════════════

  void goToBird(int index) {
    if (index < 0 || index >= state.birds.length) return;
    final bird = state.birds[index];
    final lastW = state.latestWeights[bird.bird.id];
    state = state.copyWith(
      currentIndex: index,
      weightText: lastW != null ? lastW.weightG.toStringAsFixed(1) : '',
      isFasting: true,
      message: null,
    );
  }

  void nextBird() {
    if (_searchQuery.isNotEmpty && _filteredIndices.isNotEmpty) {
      final curInFiltered = _filteredIndices.indexOf(state.currentIndex);
      if (curInFiltered >= 0 && curInFiltered < _filteredIndices.length - 1) {
        goToBird(_filteredIndices[curInFiltered + 1]);
        return;
      }
    }
    if (state.hasNext) {
      goToBird(state.currentIndex + 1);
    } else {
      // 自动尝试下一容器
      if (_advanceEnclosure(1)) return;
      _advanceRoom(1);
    }
  }

  void prevBird() {
    if (_searchQuery.isNotEmpty && _filteredIndices.isNotEmpty) {
      final curInFiltered = _filteredIndices.indexOf(state.currentIndex);
      if (curInFiltered > 0) {
        goToBird(_filteredIndices[curInFiltered - 1]);
        return;
      }
    }
    if (state.hasPrev) {
      goToBird(state.currentIndex - 1);
    } else {
      if (_advanceEnclosure(-1)) {
        // 跳转到该容器最后一只鸟
        Future.microtask(() {
          if (state.birds.isNotEmpty) goToBird(state.birds.length - 1);
        });
        return;
      }
      _advanceRoom(-1);
    }
  }

  /// 切换到下一个/上一个容器
  Future<void> nextEnclosure() async {
    if (_advanceEnclosure(1)) return;
    await _advanceRoom(1);
  }

  Future<void> prevEnclosure() async {
    if (_advanceEnclosure(-1)) return;
    await _advanceRoom(-1);
  }

  /// 切换到下一个/上一个房间
  Future<void> nextRoom() async => _advanceRoom(1);
  Future<void> prevRoom() async => _advanceRoom(-1);

  bool _advanceEnclosure(int delta) {
    if (_rooms.isEmpty) return false;
    final room = _rooms[_roomIdx];
    final encs = _enclosuresByRoom[room.id] ?? [];
    if (encs.isEmpty) return false;
    final newIdx = _enclosureIdx + delta;
    if (newIdx >= 0 && newIdx < encs.length) {
      _enclosureIdx = newIdx;
      _loadCurrentBirds();
      return true;
    }
    return false;
  }

  Future<void> _advanceRoom(int delta) async {
    if (_rooms.isEmpty) return;
    final newRoomIdx = _roomIdx + delta;
    if (newRoomIdx < 0 || newRoomIdx >= _rooms.length) return;
    _roomIdx = newRoomIdx;
    // 新房间：定位到第一个容器，或无容器状态
    final room = _rooms[_roomIdx];
    final encs = _enclosuresByRoom[room.id] ?? [];
    _enclosureIdx = encs.isNotEmpty ? 0 : -1;
    await _loadCurrentBirds();
  }

  // ═══════════════════════════════════════════════
  // 脚环搜索
  // ═══════════════════════════════════════════════

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredIndices = [];
      return;
    }
    _filteredIndices = [];
    for (int i = 0; i < state.birds.length; i++) {
      final ring = state.birds[i].bird.ringNumber;
      if (ring != null && ring.toLowerCase().startsWith(query.toLowerCase())) {
        _filteredIndices.add(i);
      }
    }
    if (_filteredIndices.isNotEmpty) {
      goToBird(_filteredIndices.first);
    }
  }

  List<BirdWithDetails> get filteredBirds {
    if (_searchQuery.isEmpty) return state.birds;
    return _filteredIndices.map((i) => state.birds[i]).toList();
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
    final bird = state.currentBird;
    if (bird == null) return;
    final w = double.tryParse(state.weightText);
    if (w == null || w <= 0) {
      state = state.copyWith(message: '请输入有效体重');
      return;
    }

    state = state.copyWith(isSaving: true);

    final now = AppClock.now;

    // 查找今日待完成称重任务（事务外查询）
    final allTodayTasks = await _db.getTodayTasks(null);
    final pendingTask = allTodayTasks
        .where((t) => t.bird.id == bird.bird.id && t.task.status == '待完成')
        .firstOrNull;

    // 原子写入：Weights + ActivityLogs + 完成任务（单事务，防崩溃不一致）
    late final Weight savedWeight;
    await _db.transaction(() async {
      savedWeight = await _db.addWeight(
        birdId: bird.bird.id,
        weightG: w,
        recordedAt: now,
        recordedBy: _userId,
        isFasting: state.isFasting,
      );

      await pluginRegistry.operationService.recordInTransaction(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        birdId: bird.bird.id,
        summary: '称重: ${w.toStringAsFixed(1)}g',
        details: {
          'weightG': w,
          'isFasting': state.isFasting,
          'weightId': savedWeight.id,
        },
        relatedTaskId: pendingTask?.task.id,
        operatedBy: _userId,
      );
    });

    final updatedWeights = Map<int, Weight?>.from(state.latestWeights);
    updatedWeights[bird.bird.id] = savedWeight;

    _onWeightSaved?.call(bird.bird.id);

    final done = allTodayTasks.where((t) => t.task.status == '已完成').length +
        (pendingTask != null ? 1 : 0);

    state = state.copyWith(
      isSaving: false,
      latestWeights: updatedWeights,
      todayCompleted: done,
    );

    // 自动切换到下一只鸟（搜索状态下在过滤结果内导航）
    if (_searchQuery.isNotEmpty && _filteredIndices.isNotEmpty) {
      final curInFiltered = _filteredIndices.indexOf(state.currentIndex);
      if (curInFiltered >= 0 && curInFiltered < _filteredIndices.length - 1) {
        goToBird(_filteredIndices[curInFiltered + 1]);
        return;
      }
    }

    if (state.hasNext) {
      nextBird();
    } else {
      state = state.copyWith(
        message: '✅ 全部完成！',
        weightText: '',
        isFasting: true,
      );
    }
  }
}

/// Riverpod Provider
final weighProvider = StateNotifierProvider<WeighNotifier, WeighState>((ref) {
  final db = ref.watch(databaseProvider);

  // debounce 计时器：连续保存时合并为一次 alert 检测
  Timer? alertDebounce;

  return WeighNotifier(db, onWeightSaved: (int birdId) {
    // 1) 细粒度通知：标记该鸟变化
    ref.read(weightSavedBirdsProvider.notifier).notifySaved(birdId);

    // 2) debounce alert 检测
    alertDebounce?.cancel();
    alertDebounce = Timer(const Duration(seconds: 2), () {
      alertDebounce = null;
      ref.invalidate(rawAlertsProvider);
    });
  });
});
