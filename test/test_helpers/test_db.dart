import '../../lib/core/app_clock.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/enclosure_repository.dart';
import '../../lib/repositories/room_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../../lib/repositories/weight_repository.dart';

/// ── 测试场景构造器 ────────────────────────────────────────────────────────
///
/// 构建常见测试数据集，消除每个测试文件中重复的"创建品种 → 创建鸟 → 加体重"
/// 三段式样板代码。对应 testing-strategy.md Appendix A 的 `test_db.dart`。
///
/// 所有构造器都基于 [setUpTestDb]（来自 test_factories.dart）返回的内存 DB，
/// 不自行创建数据库实例 —— 调用方负责 setUp/tearDown 生命周期。

/// 场景：单只鸟 + 一组体重序列。
///
/// [grams] 按时间升序（最早在前），自动以 [AppClock.now] 为锚点回推时间，
/// 每条间隔 [intervalHours] 小时。
///
/// 例：`dbWithBirdAndWeights(db, grams: [40, 42, 44])` 创建一只 0 日龄成鸟，
/// 并加入 3 条体重记录（间隔 24h）。
Future<({Bird bird, Specy species})> dbWithBirdAndWeights(
  AppDatabase db, {
  String birdName = '测试鹦鹉',
  String speciesName = '测试品种',
  List<double> grams = const [],
  int intervalHours = 24,
  int ageDays = 200, // 默认成鸟阶段，避免触发雏鸟/断奶期告警逻辑
}) async {
  final species = await db.createSpecies(speciesName);
  final bird = await db.createBird(
    name: birdName,
    speciesId: species.id,
    birthDate: AppClock.now.subtract(Duration(days: ageDays)),
  );

  for (int i = 0; i < grams.length; i++) {
    final ago = (grams.length - 1 - i) * intervalHours;
    await db.addWeight(
      birdId: bird.id,
      weightG: grams[i],
      recordedAt: AppClock.now.subtract(Duration(hours: ago)),
    );
  }
  return (bird: bird, species: species);
}

/// 场景：多只鸟（同一品种），用于批量查询测试。
///
/// 返回创建的鸟列表（按调用顺序）。每只鸟的出生日均为 [ageDays] 天前。
Future<List<Bird>> dbWithMultipleBirds(
  AppDatabase db, {
  int count = 3,
  String speciesName = '测试品种',
  int ageDays = 200,
}) async {
  final species = await db.createSpecies(speciesName);
  final birds = <Bird>[];
  for (int i = 0; i < count; i++) {
    birds.add(await db.createBird(
      name: '鸟$i',
      speciesId: species.id,
      birthDate: AppClock.now.subtract(Duration(days: ageDays)),
    ));
  }
  return birds;
}

/// 场景：房间 + 容器层级，附带若干鸟分布其中。
///
/// 返回 `(rooms, enclosures, birds)` 三元组，用于测试按房间/容器筛选查询。
/// 默认创建 2 个房间，每房 1 个容器，每容器 2 只鸟。
Future<
    ({
      List<Room> rooms,
      List<Enclosure> enclosures,
      List<Bird> birds,
    })> dbWithRoomHierarchy(
  AppDatabase db, {
  int roomCount = 2,
  int enclosuresPerRoom = 1,
  int birdsPerEnclosure = 2,
  String speciesName = '测试品种',
}) async {
  final species = await db.createSpecies(speciesName);
  final rooms = <Room>[];
  final enclosures = <Enclosure>[];
  final birds = <Bird>[];

  for (int r = 0; r < roomCount; r++) {
    final room = await db.createRoom('房间$r');
    rooms.add(room);
    for (int e = 0; e < enclosuresPerRoom; e++) {
      final enclosure = await db.createEnclosure('容器$r-$e', room.id);
      enclosures.add(enclosure);
      for (int b = 0; b < birdsPerEnclosure; b++) {
        final bird = await db.createBird(
          name: '鸟$r-$e-$b',
          speciesId: species.id,
          birthDate: AppClock.now.subtract(const Duration(days: 200)),
          roomId: room.id,
          enclosureId: enclosure.id,
        );
        birds.add(bird);
      }
    }
  }
  return (rooms: rooms, enclosures: enclosures, birds: birds);
}

/// 场景：单只鸟 + 精确控制的体重时间序列（按 hoursAgo 偏移）。
///
/// 与 [dbWithBirdAndWeights] 不同，此构造器允许每条记录指定独立的 hoursAgo，
/// 适合测试 48h 窗口、跨日去重等时间敏感逻辑。
Future<({Bird bird, Specy species})> dbWithBirdAndTimedWeights(
  AppDatabase db, {
  String birdName = '测试鹦鹉',
  String speciesName = '测试品种',
  required List<({int hoursAgo, double grams})> entries,
  int ageDays = 200,
}) async {
  final species = await db.createSpecies(speciesName);
  final bird = await db.createBird(
    name: birdName,
    speciesId: species.id,
    birthDate: AppClock.now.subtract(Duration(days: ageDays)),
  );
  for (final e in entries) {
    await db.addWeight(
      birdId: bird.id,
      weightG: e.grams,
      recordedAt: AppClock.now.subtract(Duration(hours: e.hoursAgo)),
    );
  }
  return (bird: bird, species: species);
}
