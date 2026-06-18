import 'package:drift/drift.dart';

/// 品种表
class Species extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()(); // 全局唯一 ID
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// 雏鸟阶段结束天数
  IntColumn get nestlingEndDays => integer().withDefault(const Constant(45))();

  /// 幼鸟阶段结束天数
  IntColumn get juvenileEndDays => integer().withDefault(const Constant(120))();

  /// 雏鸟称重间隔（天）
  IntColumn get nestlingWeighIntervalDays => integer().withDefault(const Constant(1))();

  /// 幼鸟称重间隔（天）
  IntColumn get juvenileWeighIntervalDays => integer().withDefault(const Constant(3))();

  /// 成鸟称重间隔（天）
  IntColumn get adultWeighIntervalDays => integer().withDefault(const Constant(7))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // 软删除
}

/// 用户表
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get username => text().withLength(min: 1, max: 30)();
  TextColumn get displayName => text().withLength(min: 1, max: 30)();
  TextColumn get passwordHash => text()();
  TextColumn get role => text().withLength(max: 20).withDefault(const Constant('keeper'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// 房间内容器（保温箱、飞行笼等）
class Enclosures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get roomId => integer().references(Rooms, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// 房间表
class Rooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// 排序序号
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 负责该房间的用户 ID
  IntColumn get assignedUserId => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// 鹦鹉表
class Birds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// 脚环号
  TextColumn get ringNumber => text().withLength(max: 30).nullable()();

  /// 品种 ID
  IntColumn get speciesId => integer().references(Species, #id)();

  /// 所在房间 ID
  IntColumn get roomId => integer().nullable().references(Rooms, #id)();

  /// 所在容器 ID（保温箱、飞行笼等）
  IntColumn get enclosureId => integer().nullable().references(Enclosures, #id, onDelete: KeyAction.setNull)();

  /// 出生日期
  DateTimeColumn get birthDate => dateTime()();

  /// 性别：公/母/未知
  TextColumn get gender => text().withLength(max: 10).withDefault(const Constant('未知'))();

  /// 自定义排序
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 单只称重间隔覆盖（天），NULL=使用品种默认值
  IntColumn get weighIntervalDays => integer().nullable()();

  /// 用户手动设置的基准体重（g），NULL=自动推断
  RealColumn get manualBaselineG => real().nullable()();

  /// 断奶期覆盖：NULL=自动检测，true=强制开启，false=强制关闭
  BoolColumn get weaningOverride => boolean().nullable()();

  /// 状态：正常/异常/已离舍
  TextColumn get status => text().withLength(max: 20).withDefault(const Constant('正常'))();

  /// 备注
  TextColumn get notes => text().withLength(max: 500).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// 体重记录表
class Weights extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 鹦鹉 ID
  IntColumn get birdId => integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 体重（克），保留一位小数
  RealColumn get weightG => real()();

  /// 记录时间（精确到小时）
  DateTimeColumn get recordedAt => dateTime()();

  /// 记录人 ID
  IntColumn get recordedBy => integer().nullable().references(Users, #id)();

  /// 是否空腹体重
  BoolColumn get isFasting => boolean().withDefault(const Constant(true))();

  /// 备注
  TextColumn get notes => text().withLength(max: 200).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 称重任务表
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 鹦鹉 ID
  IntColumn get birdId => integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 房间 ID（冗余，方便按房间看任务）
  IntColumn get roomId => integer().nullable().references(Rooms, #id)();

  /// 指派人
  IntColumn get assignedUserId => integer().nullable()();

  /// 任务类型：weigh / medication / ...
  TextColumn get taskType => text().withLength(max: 20).withDefault(const Constant('weigh'))();

  /// 任务日期（weigh 为当天零点，medication 为具体喂药时间）
  DateTimeColumn get dueDate => dateTime()();

  /// 任务状态：待完成/已完成/逾期/已跳过
  TextColumn get status => text().withLength(max: 20).withDefault(const Constant('待完成'))();

  /// 完成时间
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// 完成人
  IntColumn get completedBy => integer().nullable()();

  /// 插件私有数据（JSON），如喂药任务存 drugName/dosage/medicationId
  TextColumn get metadata => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 异常提醒表
class AlertRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 鹦鹉 ID
  IntColumn get birdId => integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 提醒类型：体重下降/增长停滞/超期未称重/长期未记录
  TextColumn get alertType => text().withLength(max: 30)();

  /// 提醒详情
  TextColumn get description => text().withLength(max: 500)();

  /// 严重程度: warning / danger
  TextColumn get severity => text().withLength(max: 10)();

  /// 是否已读
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  /// 是否已解决
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}

/// 同步操作日志表（离线 MVP 中不再使用，保留以兼容旧数据库）
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get opId => text().unique()();
  TextColumn get deviceId => text()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityUuid => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

/// 喂药方案表
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 鹦鹉 ID
  IntColumn get birdId => integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 药品名称
  TextColumn get drugName => text()();

  /// 药品类型：抗生素/驱虫/维生素/其他
  TextColumn get drugType => text().withDefault(const Constant('其他'))();

  /// 剂量（如 "0.5ml", "1片", "2滴"）
  TextColumn get dosage => text()();

  /// 每天次数（1/2/3）
  IntColumn get timesPerDay => integer().withDefault(const Constant(1))();

  /// 开始日期
  DateTimeColumn get startDate => dateTime()();

  /// 结束日期（null=持续）
  DateTimeColumn get endDate => dateTime().nullable()();

  /// 备注
  TextColumn get notes => text().nullable()();

  /// 是否启用
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 繁育配对表
class BreedingPairs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 公鸟
  @ReferenceName('maleBreedingPairs')
  IntColumn get maleBirdId => integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 母鸟
  @ReferenceName('femaleBreedingPairs')
  IntColumn get femaleBirdId => integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 配对名称（可选，如 "蓝公×绿母"）
  TextColumn get pairName => text().nullable()();

  /// 状态：active / separated
  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get pairedDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get separatedDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 繁育记录表（每次繁殖周期）
class BreedingRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 关联配对
  IntColumn get pairId => integer().references(BreedingPairs, #id, onDelete: KeyAction.cascade)();

  /// 阶段：配对/产蛋/孵化/育雏/已完结
  TextColumn get stage => text().withDefault(const Constant('配对'))();

  DateTimeColumn get startDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// 完结原因（正常完结/亲鸟弃窝/人工掏窝/其他）
  TextColumn get endReason => text().nullable()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 蛋的记录表
class Eggs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 关联繁育记录
  IntColumn get breedingRecordId => integer().references(BreedingRecords, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get laidDate => dateTime()();
  DateTimeColumn get hatchDate => dateTime().nullable()();

  /// 状态：孵化中/已出壳/未受精/损坏
  TextColumn get status => text().withDefault(const Constant('孵化中'))();

  /// 出壳后关联的雏鸟
  IntColumn get chickBirdId => integer().nullable().references(Birds, #id, onDelete: KeyAction.setNull)();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 踩背观察记录表
class MatingEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 关联繁育记录
  IntColumn get breedingRecordId => integer().references(BreedingRecords, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get observedDate => dateTime()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
