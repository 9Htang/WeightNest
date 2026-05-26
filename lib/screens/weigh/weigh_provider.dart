import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../providers.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/weight_repository.dart';
import '../../repositories/task_repository.dart';

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

  WeighState({
    required this.birds,
    this.currentIndex = 0,
    this.weightText = '',
    this.isFasting = false,
    this.isSaving = false,
    this.message,
    this.latestWeights = const {},
    this.todayCompleted = 0,
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
      );
}

/// 称重流程控制器
class WeighNotifier extends StateNotifier<WeighState> {
  final AppDatabase _db;
  int? _userId;

  WeighNotifier(this._db) : super(WeighState(birds: []));

  void setUserId(int? id) => _userId = id;

  /// 加载鹦鹉列表（按房间或全部）
  Future<void> loadBirds({int? roomId}) async {
    List<BirdWithDetails> birds;
    if (roomId != null) {
      birds = await _db.getByRoom(roomId);
    } else {
      birds = await _db.getAllWithDetails();
    }
    final weights = await _db.getLatestByBirds(
        birds.map((b) => b.bird.id).toList());
    // 自动填入第一只鸟的上次体重
    final firstWeight = birds.isNotEmpty ? weights[birds.first.bird.id] : null;
    state = state.copyWith(
      birds: birds,
      latestWeights: weights,
      weightText: firstWeight != null ? firstWeight.weightG.toStringAsFixed(1) : '',
    );
  }

  /// 跳转到指定鸟
  void goToBird(int index) {
    if (index < 0 || index >= state.birds.length) return;
    final bird = state.birds[index];
    final lastW = state.latestWeights[bird.bird.id];
    state = state.copyWith(
      currentIndex: index,
      weightText: lastW != null ? lastW.weightG.toStringAsFixed(1) : '',
      isFasting: false,
      message: null,
    );
  }

  void nextBird() {
    if (state.hasNext) {
      goToBird(state.currentIndex + 1);
    }
  }

  void prevBird() {
    if (state.hasPrev) {
      goToBird(state.currentIndex - 1);
    }
  }

  /// 输入数字
  void appendDigit(String digit) {
    if (digit == '.' && state.weightText.contains('.')) return;
    if (state.weightText.length >= 6) return;
    state = state.copyWith(
        weightText: state.weightText + digit, message: null);
  }

  void deleteDigit() {
    if (state.weightText.isEmpty) return;
    state = state.copyWith(
        weightText: state.weightText.substring(
            0, state.weightText.length - 1),
        message: null);
  }

  void clearWeight() {
    state = state.copyWith(weightText: '', isFasting: false, message: null);
  }

  void setFasting(bool v) =>
      state = state.copyWith(isFasting: v);

  /// 快速调整（+1g / -1g）
  void adjustWeight(double delta) {
    final current = double.tryParse(state.weightText) ?? 0;
    final newVal = (current + delta).toStringAsFixed(1);
    state = state.copyWith(weightText: newVal, message: null);
  }

  /// 保存体重 → 自动切换到下一只鸟
  Future<void> saveWeight() async {
    final bird = state.currentBird;
    if (bird == null) return;
    final w = double.tryParse(state.weightText);
    if (w == null || w <= 0) {
      state = state.copyWith(message: '请输入有效体重');
      return;
    }

    state = state.copyWith(isSaving: true);

    await _db.addWeight(
      birdId: bird.bird.id,
      weightG: w,
      recordedAt: DateTime.now(),
      recordedBy: _userId,
      isFasting: state.isFasting,
    );

    // 更新最新体重缓存
    final newWeight = await _db.getLatestByBird(bird.bird.id);
    final updatedWeights = Map<int, Weight?>.from(state.latestWeights);
    updatedWeights[bird.bird.id] = newWeight;

    // 离线同步：入队待推送
    offlineSyncQueue.addWeightUpdate(bird.bird.id, {
      'weightG': w,
      'recordedAt': DateTime.now().toIso8601String(),
      'isFasting': state.isFasting,
    });

    final todayTasks = await _db.getTodayTasks(null);
    final done = todayTasks.where((t) => t.task.status == '已完成').length;

    state = state.copyWith(
      isSaving: false,
      latestWeights: updatedWeights,
      todayCompleted: done,
    );

    // 自动切换到下一只鸟
    if (state.hasNext) {
      nextBird();
    } else {
      state = state.copyWith(
        message: '✅ 全部完成！',
        weightText: '',
        isFasting: false,
      );
    }
  }
}

/// Riverpod Provider
final weighProvider =
    StateNotifierProvider<WeighNotifier, WeighState>((ref) {
  final db = ref.watch(databaseProvider);
  return WeighNotifier(db);
});
