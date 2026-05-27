import 'package:drift/drift.dart';

/// 品种表
class Species extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// 雏鸟阶段结束天数
  IntColumn get nestlingEndDays => integer().withDefault(const Constant(45))();

  /// 幼鸟阶段结束天数
  IntColumn get juvenileEndDays => integer().withDefault(const Constant(120))();

  /// 称重周期（天），成鸟用
  IntColumn get adultWeighIntervalDays => integer().withDefault(const Constant(7))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 用户表
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 1, max: 30)();
  TextColumn get displayName => text().withLength(min: 1, max: 30)();
  TextColumn get passwordHash => text()();
  TextColumn get role => text().withLength(max: 20).withDefault(const Constant('keeper'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 房间表
class Rooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// 排序序号
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 负责该房间的用户 ID
  IntColumn get assignedUserId => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 鹦鹉表
class Birds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// 脚环号
  TextColumn get ringNumber => text().withLength(max: 30).nullable()();

  /// 品种 ID
  IntColumn get speciesId => integer().references(Species, #id)();

  /// 所在房间 ID
  IntColumn get roomId => integer().nullable().references(Rooms, #id)();

  /// 出生日期
  DateTimeColumn get birthDate => dateTime()();

  /// 性别：公/母/未知
  TextColumn get gender => text().withLength(max: 10).withDefault(const Constant('未知'))();

  /// 自定义排序
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 状态：正常/异常/已离舍
  TextColumn get status => text().withLength(max: 20).withDefault(const Constant('正常'))();

  /// 备注
  TextColumn get notes => text().withLength(max: 500).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 体重记录表
class Weights extends Table {
  IntColumn get id => integer().autoIncrement()();

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
}

/// 称重任务表
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 鹦鹉 ID
  IntColumn get birdId => integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 房间 ID（冗余，方便按房间看任务）
  IntColumn get roomId => integer().nullable().references(Rooms, #id)();

  /// 指派人
  IntColumn get assignedUserId => integer().nullable()();

  /// 任务日期
  DateTimeColumn get dueDate => dateTime()();

  /// 任务状态：待完成/已完成/逾期
  TextColumn get status => text().withLength(max: 20).withDefault(const Constant('待完成'))();

  /// 完成时间
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// 完成人
  IntColumn get completedBy => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 异常提醒表
class AlertRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 鹦鹉 ID
  IntColumn get birdId => integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 提醒类型：体重下降/增长停滞/超期未称重/长期未记录
  TextColumn get alertType => text().withLength(max: 30)();

  /// 提醒详情
  TextColumn get description => text().withLength(max: 500)();

  /// 是否已读
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  /// 是否已解决
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}

/// 同步日志（局域网同步用）
class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 实体类型
  TextColumn get entityType => text().withLength(max: 30)();

  /// 实体 ID
  IntColumn get entityId => integer()();

  /// 操作类型：create/update/delete
  TextColumn get operation => text().withLength(max: 10)();

  /// 同步时间
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();
}
