// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SpeciesTable extends Species with TableInfo<$SpeciesTable, Specy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpeciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nestlingEndDaysMeta =
      const VerificationMeta('nestlingEndDays');
  @override
  late final GeneratedColumn<int> nestlingEndDays = GeneratedColumn<int>(
      'nestling_end_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(45));
  static const VerificationMeta _juvenileEndDaysMeta =
      const VerificationMeta('juvenileEndDays');
  @override
  late final GeneratedColumn<int> juvenileEndDays = GeneratedColumn<int>(
      'juvenile_end_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(120));
  static const VerificationMeta _nestlingWeighIntervalDaysMeta =
      const VerificationMeta('nestlingWeighIntervalDays');
  @override
  late final GeneratedColumn<int> nestlingWeighIntervalDays =
      GeneratedColumn<int>('nestling_weigh_interval_days', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _juvenileWeighIntervalDaysMeta =
      const VerificationMeta('juvenileWeighIntervalDays');
  @override
  late final GeneratedColumn<int> juvenileWeighIntervalDays =
      GeneratedColumn<int>('juvenile_weigh_interval_days', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(3));
  static const VerificationMeta _adultWeighIntervalDaysMeta =
      const VerificationMeta('adultWeighIntervalDays');
  @override
  late final GeneratedColumn<int> adultWeighIntervalDays = GeneratedColumn<int>(
      'adult_weigh_interval_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(7));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        name,
        nestlingEndDays,
        juvenileEndDays,
        nestlingWeighIntervalDays,
        juvenileWeighIntervalDays,
        adultWeighIntervalDays,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'species';
  @override
  VerificationContext validateIntegrity(Insertable<Specy> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('nestling_end_days')) {
      context.handle(
          _nestlingEndDaysMeta,
          nestlingEndDays.isAcceptableOrUnknown(
              data['nestling_end_days']!, _nestlingEndDaysMeta));
    }
    if (data.containsKey('juvenile_end_days')) {
      context.handle(
          _juvenileEndDaysMeta,
          juvenileEndDays.isAcceptableOrUnknown(
              data['juvenile_end_days']!, _juvenileEndDaysMeta));
    }
    if (data.containsKey('nestling_weigh_interval_days')) {
      context.handle(
          _nestlingWeighIntervalDaysMeta,
          nestlingWeighIntervalDays.isAcceptableOrUnknown(
              data['nestling_weigh_interval_days']!,
              _nestlingWeighIntervalDaysMeta));
    }
    if (data.containsKey('juvenile_weigh_interval_days')) {
      context.handle(
          _juvenileWeighIntervalDaysMeta,
          juvenileWeighIntervalDays.isAcceptableOrUnknown(
              data['juvenile_weigh_interval_days']!,
              _juvenileWeighIntervalDaysMeta));
    }
    if (data.containsKey('adult_weigh_interval_days')) {
      context.handle(
          _adultWeighIntervalDaysMeta,
          adultWeighIntervalDays.isAcceptableOrUnknown(
              data['adult_weigh_interval_days']!, _adultWeighIntervalDaysMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Specy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Specy(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      nestlingEndDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}nestling_end_days'])!,
      juvenileEndDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}juvenile_end_days'])!,
      nestlingWeighIntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}nestling_weigh_interval_days'])!,
      juvenileWeighIntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}juvenile_weigh_interval_days'])!,
      adultWeighIntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}adult_weigh_interval_days'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $SpeciesTable createAlias(String alias) {
    return $SpeciesTable(attachedDatabase, alias);
  }
}

class Specy extends DataClass implements Insertable<Specy> {
  final int id;
  final String uuid;
  final String name;

  /// 雏鸟阶段结束天数
  final int nestlingEndDays;

  /// 幼鸟阶段结束天数
  final int juvenileEndDays;

  /// 雏鸟称重间隔（天）
  final int nestlingWeighIntervalDays;

  /// 幼鸟称重间隔（天）
  final int juvenileWeighIntervalDays;

  /// 成鸟称重间隔（天）
  final int adultWeighIntervalDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Specy(
      {required this.id,
      required this.uuid,
      required this.name,
      required this.nestlingEndDays,
      required this.juvenileEndDays,
      required this.nestlingWeighIntervalDays,
      required this.juvenileWeighIntervalDays,
      required this.adultWeighIntervalDays,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['nestling_end_days'] = Variable<int>(nestlingEndDays);
    map['juvenile_end_days'] = Variable<int>(juvenileEndDays);
    map['nestling_weigh_interval_days'] =
        Variable<int>(nestlingWeighIntervalDays);
    map['juvenile_weigh_interval_days'] =
        Variable<int>(juvenileWeighIntervalDays);
    map['adult_weigh_interval_days'] = Variable<int>(adultWeighIntervalDays);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SpeciesCompanion toCompanion(bool nullToAbsent) {
    return SpeciesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      nestlingEndDays: Value(nestlingEndDays),
      juvenileEndDays: Value(juvenileEndDays),
      nestlingWeighIntervalDays: Value(nestlingWeighIntervalDays),
      juvenileWeighIntervalDays: Value(juvenileWeighIntervalDays),
      adultWeighIntervalDays: Value(adultWeighIntervalDays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Specy.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Specy(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      nestlingEndDays: serializer.fromJson<int>(json['nestlingEndDays']),
      juvenileEndDays: serializer.fromJson<int>(json['juvenileEndDays']),
      nestlingWeighIntervalDays:
          serializer.fromJson<int>(json['nestlingWeighIntervalDays']),
      juvenileWeighIntervalDays:
          serializer.fromJson<int>(json['juvenileWeighIntervalDays']),
      adultWeighIntervalDays:
          serializer.fromJson<int>(json['adultWeighIntervalDays']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'nestlingEndDays': serializer.toJson<int>(nestlingEndDays),
      'juvenileEndDays': serializer.toJson<int>(juvenileEndDays),
      'nestlingWeighIntervalDays':
          serializer.toJson<int>(nestlingWeighIntervalDays),
      'juvenileWeighIntervalDays':
          serializer.toJson<int>(juvenileWeighIntervalDays),
      'adultWeighIntervalDays': serializer.toJson<int>(adultWeighIntervalDays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Specy copyWith(
          {int? id,
          String? uuid,
          String? name,
          int? nestlingEndDays,
          int? juvenileEndDays,
          int? nestlingWeighIntervalDays,
          int? juvenileWeighIntervalDays,
          int? adultWeighIntervalDays,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Specy(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        nestlingEndDays: nestlingEndDays ?? this.nestlingEndDays,
        juvenileEndDays: juvenileEndDays ?? this.juvenileEndDays,
        nestlingWeighIntervalDays:
            nestlingWeighIntervalDays ?? this.nestlingWeighIntervalDays,
        juvenileWeighIntervalDays:
            juvenileWeighIntervalDays ?? this.juvenileWeighIntervalDays,
        adultWeighIntervalDays:
            adultWeighIntervalDays ?? this.adultWeighIntervalDays,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Specy copyWithCompanion(SpeciesCompanion data) {
    return Specy(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      nestlingEndDays: data.nestlingEndDays.present
          ? data.nestlingEndDays.value
          : this.nestlingEndDays,
      juvenileEndDays: data.juvenileEndDays.present
          ? data.juvenileEndDays.value
          : this.juvenileEndDays,
      nestlingWeighIntervalDays: data.nestlingWeighIntervalDays.present
          ? data.nestlingWeighIntervalDays.value
          : this.nestlingWeighIntervalDays,
      juvenileWeighIntervalDays: data.juvenileWeighIntervalDays.present
          ? data.juvenileWeighIntervalDays.value
          : this.juvenileWeighIntervalDays,
      adultWeighIntervalDays: data.adultWeighIntervalDays.present
          ? data.adultWeighIntervalDays.value
          : this.adultWeighIntervalDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Specy(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('nestlingEndDays: $nestlingEndDays, ')
          ..write('juvenileEndDays: $juvenileEndDays, ')
          ..write('nestlingWeighIntervalDays: $nestlingWeighIntervalDays, ')
          ..write('juvenileWeighIntervalDays: $juvenileWeighIntervalDays, ')
          ..write('adultWeighIntervalDays: $adultWeighIntervalDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      uuid,
      name,
      nestlingEndDays,
      juvenileEndDays,
      nestlingWeighIntervalDays,
      juvenileWeighIntervalDays,
      adultWeighIntervalDays,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Specy &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.nestlingEndDays == this.nestlingEndDays &&
          other.juvenileEndDays == this.juvenileEndDays &&
          other.nestlingWeighIntervalDays == this.nestlingWeighIntervalDays &&
          other.juvenileWeighIntervalDays == this.juvenileWeighIntervalDays &&
          other.adultWeighIntervalDays == this.adultWeighIntervalDays &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SpeciesCompanion extends UpdateCompanion<Specy> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> nestlingEndDays;
  final Value<int> juvenileEndDays;
  final Value<int> nestlingWeighIntervalDays;
  final Value<int> juvenileWeighIntervalDays;
  final Value<int> adultWeighIntervalDays;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const SpeciesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.nestlingEndDays = const Value.absent(),
    this.juvenileEndDays = const Value.absent(),
    this.nestlingWeighIntervalDays = const Value.absent(),
    this.juvenileWeighIntervalDays = const Value.absent(),
    this.adultWeighIntervalDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  SpeciesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    this.nestlingEndDays = const Value.absent(),
    this.juvenileEndDays = const Value.absent(),
    this.nestlingWeighIntervalDays = const Value.absent(),
    this.juvenileWeighIntervalDays = const Value.absent(),
    this.adultWeighIntervalDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        name = Value(name);
  static Insertable<Specy> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? nestlingEndDays,
    Expression<int>? juvenileEndDays,
    Expression<int>? nestlingWeighIntervalDays,
    Expression<int>? juvenileWeighIntervalDays,
    Expression<int>? adultWeighIntervalDays,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (nestlingEndDays != null) 'nestling_end_days': nestlingEndDays,
      if (juvenileEndDays != null) 'juvenile_end_days': juvenileEndDays,
      if (nestlingWeighIntervalDays != null)
        'nestling_weigh_interval_days': nestlingWeighIntervalDays,
      if (juvenileWeighIntervalDays != null)
        'juvenile_weigh_interval_days': juvenileWeighIntervalDays,
      if (adultWeighIntervalDays != null)
        'adult_weigh_interval_days': adultWeighIntervalDays,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  SpeciesCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? name,
      Value<int>? nestlingEndDays,
      Value<int>? juvenileEndDays,
      Value<int>? nestlingWeighIntervalDays,
      Value<int>? juvenileWeighIntervalDays,
      Value<int>? adultWeighIntervalDays,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return SpeciesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      nestlingEndDays: nestlingEndDays ?? this.nestlingEndDays,
      juvenileEndDays: juvenileEndDays ?? this.juvenileEndDays,
      nestlingWeighIntervalDays:
          nestlingWeighIntervalDays ?? this.nestlingWeighIntervalDays,
      juvenileWeighIntervalDays:
          juvenileWeighIntervalDays ?? this.juvenileWeighIntervalDays,
      adultWeighIntervalDays:
          adultWeighIntervalDays ?? this.adultWeighIntervalDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nestlingEndDays.present) {
      map['nestling_end_days'] = Variable<int>(nestlingEndDays.value);
    }
    if (juvenileEndDays.present) {
      map['juvenile_end_days'] = Variable<int>(juvenileEndDays.value);
    }
    if (nestlingWeighIntervalDays.present) {
      map['nestling_weigh_interval_days'] =
          Variable<int>(nestlingWeighIntervalDays.value);
    }
    if (juvenileWeighIntervalDays.present) {
      map['juvenile_weigh_interval_days'] =
          Variable<int>(juvenileWeighIntervalDays.value);
    }
    if (adultWeighIntervalDays.present) {
      map['adult_weigh_interval_days'] =
          Variable<int>(adultWeighIntervalDays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('nestlingEndDays: $nestlingEndDays, ')
          ..write('juvenileEndDays: $juvenileEndDays, ')
          ..write('nestlingWeighIntervalDays: $nestlingWeighIntervalDays, ')
          ..write('juvenileWeighIntervalDays: $juvenileWeighIntervalDays, ')
          ..write('adultWeighIntervalDays: $adultWeighIntervalDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('keeper'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        username,
        displayName,
        passwordHash,
        role,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String uuid;
  final String username;
  final String displayName;
  final String passwordHash;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const User(
      {required this.id,
      required this.uuid,
      required this.username,
      required this.displayName,
      required this.passwordHash,
      required this.role,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['username'] = Variable<String>(username);
    map['display_name'] = Variable<String>(displayName);
    map['password_hash'] = Variable<String>(passwordHash);
    map['role'] = Variable<String>(role);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      uuid: Value(uuid),
      username: Value(username),
      displayName: Value(displayName),
      passwordHash: Value(passwordHash),
      role: Value(role),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String>(json['displayName']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      role: serializer.fromJson<String>(json['role']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String>(displayName),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'role': serializer.toJson<String>(role),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  User copyWith(
          {int? id,
          String? uuid,
          String? username,
          String? displayName,
          String? passwordHash,
          String? role,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      username: data.username.present ? data.username.value : this.username,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      role: data.role.present ? data.role.value : this.role,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, username, displayName, passwordHash,
      role, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.passwordHash == this.passwordHash &&
          other.role == this.role &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> username;
  final Value<String> displayName;
  final Value<String> passwordHash;
  final Value<String> role;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String username,
    required String displayName,
    required String passwordHash,
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        username = Value(username),
        displayName = Value(displayName),
        passwordHash = Value(passwordHash);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? passwordHash,
    Expression<String>? role,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? username,
      Value<String>? displayName,
      Value<String>? passwordHash,
      Value<String>? role,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return UsersCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, Room> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _assignedUserIdMeta =
      const VerificationMeta('assignedUserId');
  @override
  late final GeneratedColumn<int> assignedUserId = GeneratedColumn<int>(
      'assigned_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        name,
        sortOrder,
        assignedUserId,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rooms';
  @override
  VerificationContext validateIntegrity(Insertable<Room> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('assigned_user_id')) {
      context.handle(
          _assignedUserIdMeta,
          assignedUserId.isAcceptableOrUnknown(
              data['assigned_user_id']!, _assignedUserIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Room map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Room(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      assignedUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}assigned_user_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class Room extends DataClass implements Insertable<Room> {
  final int id;
  final String uuid;
  final String name;

  /// 排序序号
  final int sortOrder;

  /// 负责该房间的用户 ID
  final int? assignedUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Room(
      {required this.id,
      required this.uuid,
      required this.name,
      required this.sortOrder,
      this.assignedUserId,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || assignedUserId != null) {
      map['assigned_user_id'] = Variable<int>(assignedUserId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      sortOrder: Value(sortOrder),
      assignedUserId: assignedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedUserId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Room.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Room(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      assignedUserId: serializer.fromJson<int?>(json['assignedUserId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'assignedUserId': serializer.toJson<int?>(assignedUserId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Room copyWith(
          {int? id,
          String? uuid,
          String? name,
          int? sortOrder,
          Value<int?> assignedUserId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Room(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        assignedUserId:
            assignedUserId.present ? assignedUserId.value : this.assignedUserId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Room copyWithCompanion(RoomsCompanion data) {
    return Room(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      assignedUserId: data.assignedUserId.present
          ? data.assignedUserId.value
          : this.assignedUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Room(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, name, sortOrder, assignedUserId,
      createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Room &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.assignedUserId == this.assignedUserId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RoomsCompanion extends UpdateCompanion<Room> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int?> assignedUserId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const RoomsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  RoomsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    this.sortOrder = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        name = Value(name);
  static Insertable<Room> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? assignedUserId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (assignedUserId != null) 'assigned_user_id': assignedUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  RoomsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? name,
      Value<int>? sortOrder,
      Value<int?>? assignedUserId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return RoomsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (assignedUserId.present) {
      map['assigned_user_id'] = Variable<int>(assignedUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $EnclosuresTable extends Enclosures
    with TableInfo<$EnclosuresTable, Enclosure> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnclosuresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<int> roomId = GeneratedColumn<int>(
      'room_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES rooms (id) ON DELETE CASCADE'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, uuid, name, roomId, sortOrder, createdAt, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enclosures';
  @override
  VerificationContext validateIntegrity(Insertable<Enclosure> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Enclosure map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Enclosure(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}room_id'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $EnclosuresTable createAlias(String alias) {
    return $EnclosuresTable(attachedDatabase, alias);
  }
}

class Enclosure extends DataClass implements Insertable<Enclosure> {
  final int id;
  final String uuid;
  final String name;
  final int roomId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Enclosure(
      {required this.id,
      required this.uuid,
      required this.name,
      required this.roomId,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['room_id'] = Variable<int>(roomId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  EnclosuresCompanion toCompanion(bool nullToAbsent) {
    return EnclosuresCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      roomId: Value(roomId),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Enclosure.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Enclosure(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      roomId: serializer.fromJson<int>(json['roomId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'roomId': serializer.toJson<int>(roomId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Enclosure copyWith(
          {int? id,
          String? uuid,
          String? name,
          int? roomId,
          int? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Enclosure(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        roomId: roomId ?? this.roomId,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Enclosure copyWithCompanion(EnclosuresCompanion data) {
    return Enclosure(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Enclosure(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('roomId: $roomId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, uuid, name, roomId, sortOrder, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Enclosure &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.roomId == this.roomId &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class EnclosuresCompanion extends UpdateCompanion<Enclosure> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> roomId;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const EnclosuresCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.roomId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  EnclosuresCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    required int roomId,
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        name = Value(name),
        roomId = Value(roomId);
  static Insertable<Enclosure> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? roomId,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (roomId != null) 'room_id': roomId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  EnclosuresCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? name,
      Value<int>? roomId,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return EnclosuresCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      roomId: roomId ?? this.roomId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<int>(roomId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnclosuresCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('roomId: $roomId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $BirdsTable extends Birds with TableInfo<$BirdsTable, Bird> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BirdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _ringNumberMeta =
      const VerificationMeta('ringNumber');
  @override
  late final GeneratedColumn<String> ringNumber = GeneratedColumn<String>(
      'ring_number', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _speciesIdMeta =
      const VerificationMeta('speciesId');
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
      'species_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES species (id)'));
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<int> roomId = GeneratedColumn<int>(
      'room_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES rooms (id)'));
  static const VerificationMeta _enclosureIdMeta =
      const VerificationMeta('enclosureId');
  @override
  late final GeneratedColumn<int> enclosureId = GeneratedColumn<int>(
      'enclosure_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES enclosures (id) ON DELETE SET NULL'));
  static const VerificationMeta _birthDateMeta =
      const VerificationMeta('birthDate');
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
      'birth_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('未知'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _weighIntervalDaysMeta =
      const VerificationMeta('weighIntervalDays');
  @override
  late final GeneratedColumn<int> weighIntervalDays = GeneratedColumn<int>(
      'weigh_interval_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _manualBaselineGMeta =
      const VerificationMeta('manualBaselineG');
  @override
  late final GeneratedColumn<double> manualBaselineG = GeneratedColumn<double>(
      'manual_baseline_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _weaningOverrideMeta =
      const VerificationMeta('weaningOverride');
  @override
  late final GeneratedColumn<bool> weaningOverride = GeneratedColumn<bool>(
      'weaning_override', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("weaning_override" IN (0, 1))'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('正常'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        name,
        ringNumber,
        speciesId,
        roomId,
        enclosureId,
        birthDate,
        gender,
        sortOrder,
        weighIntervalDays,
        manualBaselineG,
        weaningOverride,
        status,
        notes,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'birds';
  @override
  VerificationContext validateIntegrity(Insertable<Bird> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ring_number')) {
      context.handle(
          _ringNumberMeta,
          ringNumber.isAcceptableOrUnknown(
              data['ring_number']!, _ringNumberMeta));
    }
    if (data.containsKey('species_id')) {
      context.handle(_speciesIdMeta,
          speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta));
    } else if (isInserting) {
      context.missing(_speciesIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    }
    if (data.containsKey('enclosure_id')) {
      context.handle(
          _enclosureIdMeta,
          enclosureId.isAcceptableOrUnknown(
              data['enclosure_id']!, _enclosureIdMeta));
    }
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('weigh_interval_days')) {
      context.handle(
          _weighIntervalDaysMeta,
          weighIntervalDays.isAcceptableOrUnknown(
              data['weigh_interval_days']!, _weighIntervalDaysMeta));
    }
    if (data.containsKey('manual_baseline_g')) {
      context.handle(
          _manualBaselineGMeta,
          manualBaselineG.isAcceptableOrUnknown(
              data['manual_baseline_g']!, _manualBaselineGMeta));
    }
    if (data.containsKey('weaning_override')) {
      context.handle(
          _weaningOverrideMeta,
          weaningOverride.isAcceptableOrUnknown(
              data['weaning_override']!, _weaningOverrideMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bird map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bird(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      ringNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ring_number']),
      speciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}species_id'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}room_id']),
      enclosureId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}enclosure_id']),
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birth_date'])!,
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      weighIntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}weigh_interval_days']),
      manualBaselineG: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}manual_baseline_g']),
      weaningOverride: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}weaning_override']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $BirdsTable createAlias(String alias) {
    return $BirdsTable(attachedDatabase, alias);
  }
}

class Bird extends DataClass implements Insertable<Bird> {
  final int id;
  final String uuid;
  final String name;

  /// 脚环号
  final String? ringNumber;

  /// 品种 ID
  final int speciesId;

  /// 所在房间 ID
  final int? roomId;

  /// 所在容器 ID（保温箱、飞行笼等）
  final int? enclosureId;

  /// 出生日期
  final DateTime birthDate;

  /// 性别：公/母/未知
  final String gender;

  /// 自定义排序
  final int sortOrder;

  /// 单只称重间隔覆盖（天），NULL=使用品种默认值
  final int? weighIntervalDays;

  /// 用户手动设置的基准体重（g），NULL=自动推断
  final double? manualBaselineG;

  /// 断奶期覆盖：NULL=自动检测，true=强制开启，false=强制关闭
  final bool? weaningOverride;

  /// 状态：正常/异常/已离舍
  final String status;

  /// 备注
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Bird(
      {required this.id,
      required this.uuid,
      required this.name,
      this.ringNumber,
      required this.speciesId,
      this.roomId,
      this.enclosureId,
      required this.birthDate,
      required this.gender,
      required this.sortOrder,
      this.weighIntervalDays,
      this.manualBaselineG,
      this.weaningOverride,
      required this.status,
      this.notes,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || ringNumber != null) {
      map['ring_number'] = Variable<String>(ringNumber);
    }
    map['species_id'] = Variable<int>(speciesId);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<int>(roomId);
    }
    if (!nullToAbsent || enclosureId != null) {
      map['enclosure_id'] = Variable<int>(enclosureId);
    }
    map['birth_date'] = Variable<DateTime>(birthDate);
    map['gender'] = Variable<String>(gender);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || weighIntervalDays != null) {
      map['weigh_interval_days'] = Variable<int>(weighIntervalDays);
    }
    if (!nullToAbsent || manualBaselineG != null) {
      map['manual_baseline_g'] = Variable<double>(manualBaselineG);
    }
    if (!nullToAbsent || weaningOverride != null) {
      map['weaning_override'] = Variable<bool>(weaningOverride);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  BirdsCompanion toCompanion(bool nullToAbsent) {
    return BirdsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      ringNumber: ringNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(ringNumber),
      speciesId: Value(speciesId),
      roomId:
          roomId == null && nullToAbsent ? const Value.absent() : Value(roomId),
      enclosureId: enclosureId == null && nullToAbsent
          ? const Value.absent()
          : Value(enclosureId),
      birthDate: Value(birthDate),
      gender: Value(gender),
      sortOrder: Value(sortOrder),
      weighIntervalDays: weighIntervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(weighIntervalDays),
      manualBaselineG: manualBaselineG == null && nullToAbsent
          ? const Value.absent()
          : Value(manualBaselineG),
      weaningOverride: weaningOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(weaningOverride),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Bird.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bird(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      ringNumber: serializer.fromJson<String?>(json['ringNumber']),
      speciesId: serializer.fromJson<int>(json['speciesId']),
      roomId: serializer.fromJson<int?>(json['roomId']),
      enclosureId: serializer.fromJson<int?>(json['enclosureId']),
      birthDate: serializer.fromJson<DateTime>(json['birthDate']),
      gender: serializer.fromJson<String>(json['gender']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      weighIntervalDays: serializer.fromJson<int?>(json['weighIntervalDays']),
      manualBaselineG: serializer.fromJson<double?>(json['manualBaselineG']),
      weaningOverride: serializer.fromJson<bool?>(json['weaningOverride']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'ringNumber': serializer.toJson<String?>(ringNumber),
      'speciesId': serializer.toJson<int>(speciesId),
      'roomId': serializer.toJson<int?>(roomId),
      'enclosureId': serializer.toJson<int?>(enclosureId),
      'birthDate': serializer.toJson<DateTime>(birthDate),
      'gender': serializer.toJson<String>(gender),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'weighIntervalDays': serializer.toJson<int?>(weighIntervalDays),
      'manualBaselineG': serializer.toJson<double?>(manualBaselineG),
      'weaningOverride': serializer.toJson<bool?>(weaningOverride),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Bird copyWith(
          {int? id,
          String? uuid,
          String? name,
          Value<String?> ringNumber = const Value.absent(),
          int? speciesId,
          Value<int?> roomId = const Value.absent(),
          Value<int?> enclosureId = const Value.absent(),
          DateTime? birthDate,
          String? gender,
          int? sortOrder,
          Value<int?> weighIntervalDays = const Value.absent(),
          Value<double?> manualBaselineG = const Value.absent(),
          Value<bool?> weaningOverride = const Value.absent(),
          String? status,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Bird(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        ringNumber: ringNumber.present ? ringNumber.value : this.ringNumber,
        speciesId: speciesId ?? this.speciesId,
        roomId: roomId.present ? roomId.value : this.roomId,
        enclosureId: enclosureId.present ? enclosureId.value : this.enclosureId,
        birthDate: birthDate ?? this.birthDate,
        gender: gender ?? this.gender,
        sortOrder: sortOrder ?? this.sortOrder,
        weighIntervalDays: weighIntervalDays.present
            ? weighIntervalDays.value
            : this.weighIntervalDays,
        manualBaselineG: manualBaselineG.present
            ? manualBaselineG.value
            : this.manualBaselineG,
        weaningOverride: weaningOverride.present
            ? weaningOverride.value
            : this.weaningOverride,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Bird copyWithCompanion(BirdsCompanion data) {
    return Bird(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      ringNumber:
          data.ringNumber.present ? data.ringNumber.value : this.ringNumber,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      enclosureId:
          data.enclosureId.present ? data.enclosureId.value : this.enclosureId,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      gender: data.gender.present ? data.gender.value : this.gender,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      weighIntervalDays: data.weighIntervalDays.present
          ? data.weighIntervalDays.value
          : this.weighIntervalDays,
      manualBaselineG: data.manualBaselineG.present
          ? data.manualBaselineG.value
          : this.manualBaselineG,
      weaningOverride: data.weaningOverride.present
          ? data.weaningOverride.value
          : this.weaningOverride,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bird(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('ringNumber: $ringNumber, ')
          ..write('speciesId: $speciesId, ')
          ..write('roomId: $roomId, ')
          ..write('enclosureId: $enclosureId, ')
          ..write('birthDate: $birthDate, ')
          ..write('gender: $gender, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('weighIntervalDays: $weighIntervalDays, ')
          ..write('manualBaselineG: $manualBaselineG, ')
          ..write('weaningOverride: $weaningOverride, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      uuid,
      name,
      ringNumber,
      speciesId,
      roomId,
      enclosureId,
      birthDate,
      gender,
      sortOrder,
      weighIntervalDays,
      manualBaselineG,
      weaningOverride,
      status,
      notes,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bird &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.ringNumber == this.ringNumber &&
          other.speciesId == this.speciesId &&
          other.roomId == this.roomId &&
          other.enclosureId == this.enclosureId &&
          other.birthDate == this.birthDate &&
          other.gender == this.gender &&
          other.sortOrder == this.sortOrder &&
          other.weighIntervalDays == this.weighIntervalDays &&
          other.manualBaselineG == this.manualBaselineG &&
          other.weaningOverride == this.weaningOverride &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BirdsCompanion extends UpdateCompanion<Bird> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<String?> ringNumber;
  final Value<int> speciesId;
  final Value<int?> roomId;
  final Value<int?> enclosureId;
  final Value<DateTime> birthDate;
  final Value<String> gender;
  final Value<int> sortOrder;
  final Value<int?> weighIntervalDays;
  final Value<double?> manualBaselineG;
  final Value<bool?> weaningOverride;
  final Value<String> status;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const BirdsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.ringNumber = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.enclosureId = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.gender = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.weighIntervalDays = const Value.absent(),
    this.manualBaselineG = const Value.absent(),
    this.weaningOverride = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  BirdsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    this.ringNumber = const Value.absent(),
    required int speciesId,
    this.roomId = const Value.absent(),
    this.enclosureId = const Value.absent(),
    required DateTime birthDate,
    this.gender = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.weighIntervalDays = const Value.absent(),
    this.manualBaselineG = const Value.absent(),
    this.weaningOverride = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        name = Value(name),
        speciesId = Value(speciesId),
        birthDate = Value(birthDate);
  static Insertable<Bird> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<String>? ringNumber,
    Expression<int>? speciesId,
    Expression<int>? roomId,
    Expression<int>? enclosureId,
    Expression<DateTime>? birthDate,
    Expression<String>? gender,
    Expression<int>? sortOrder,
    Expression<int>? weighIntervalDays,
    Expression<double>? manualBaselineG,
    Expression<bool>? weaningOverride,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (ringNumber != null) 'ring_number': ringNumber,
      if (speciesId != null) 'species_id': speciesId,
      if (roomId != null) 'room_id': roomId,
      if (enclosureId != null) 'enclosure_id': enclosureId,
      if (birthDate != null) 'birth_date': birthDate,
      if (gender != null) 'gender': gender,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (weighIntervalDays != null) 'weigh_interval_days': weighIntervalDays,
      if (manualBaselineG != null) 'manual_baseline_g': manualBaselineG,
      if (weaningOverride != null) 'weaning_override': weaningOverride,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  BirdsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? name,
      Value<String?>? ringNumber,
      Value<int>? speciesId,
      Value<int?>? roomId,
      Value<int?>? enclosureId,
      Value<DateTime>? birthDate,
      Value<String>? gender,
      Value<int>? sortOrder,
      Value<int?>? weighIntervalDays,
      Value<double?>? manualBaselineG,
      Value<bool?>? weaningOverride,
      Value<String>? status,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return BirdsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      ringNumber: ringNumber ?? this.ringNumber,
      speciesId: speciesId ?? this.speciesId,
      roomId: roomId ?? this.roomId,
      enclosureId: enclosureId ?? this.enclosureId,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      sortOrder: sortOrder ?? this.sortOrder,
      weighIntervalDays: weighIntervalDays ?? this.weighIntervalDays,
      manualBaselineG: manualBaselineG ?? this.manualBaselineG,
      weaningOverride: weaningOverride ?? this.weaningOverride,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ringNumber.present) {
      map['ring_number'] = Variable<String>(ringNumber.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<int>(roomId.value);
    }
    if (enclosureId.present) {
      map['enclosure_id'] = Variable<int>(enclosureId.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (weighIntervalDays.present) {
      map['weigh_interval_days'] = Variable<int>(weighIntervalDays.value);
    }
    if (manualBaselineG.present) {
      map['manual_baseline_g'] = Variable<double>(manualBaselineG.value);
    }
    if (weaningOverride.present) {
      map['weaning_override'] = Variable<bool>(weaningOverride.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BirdsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('ringNumber: $ringNumber, ')
          ..write('speciesId: $speciesId, ')
          ..write('roomId: $roomId, ')
          ..write('enclosureId: $enclosureId, ')
          ..write('birthDate: $birthDate, ')
          ..write('gender: $gender, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('weighIntervalDays: $weighIntervalDays, ')
          ..write('manualBaselineG: $manualBaselineG, ')
          ..write('weaningOverride: $weaningOverride, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $WeightsTable extends Weights with TableInfo<$WeightsTable, Weight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _birdIdMeta = const VerificationMeta('birdId');
  @override
  late final GeneratedColumn<int> birdId = GeneratedColumn<int>(
      'bird_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES birds (id) ON DELETE CASCADE'));
  static const VerificationMeta _weightGMeta =
      const VerificationMeta('weightG');
  @override
  late final GeneratedColumn<double> weightG = GeneratedColumn<double>(
      'weight_g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _recordedByMeta =
      const VerificationMeta('recordedBy');
  @override
  late final GeneratedColumn<int> recordedBy = GeneratedColumn<int>(
      'recorded_by', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _isFastingMeta =
      const VerificationMeta('isFasting');
  @override
  late final GeneratedColumn<bool> isFasting = GeneratedColumn<bool>(
      'is_fasting', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_fasting" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        birdId,
        weightG,
        recordedAt,
        recordedBy,
        isFasting,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weights';
  @override
  VerificationContext validateIntegrity(Insertable<Weight> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('bird_id')) {
      context.handle(_birdIdMeta,
          birdId.isAcceptableOrUnknown(data['bird_id']!, _birdIdMeta));
    } else if (isInserting) {
      context.missing(_birdIdMeta);
    }
    if (data.containsKey('weight_g')) {
      context.handle(_weightGMeta,
          weightG.isAcceptableOrUnknown(data['weight_g']!, _weightGMeta));
    } else if (isInserting) {
      context.missing(_weightGMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
          _recordedByMeta,
          recordedBy.isAcceptableOrUnknown(
              data['recorded_by']!, _recordedByMeta));
    }
    if (data.containsKey('is_fasting')) {
      context.handle(_isFastingMeta,
          isFasting.isAcceptableOrUnknown(data['is_fasting']!, _isFastingMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Weight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Weight(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      birdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bird_id'])!,
      weightG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_g'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      recordedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}recorded_by']),
      isFasting: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_fasting'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WeightsTable createAlias(String alias) {
    return $WeightsTable(attachedDatabase, alias);
  }
}

class Weight extends DataClass implements Insertable<Weight> {
  final int id;
  final String uuid;

  /// 鹦鹉 ID
  final int birdId;

  /// 体重（克），保留一位小数
  final double weightG;

  /// 记录时间（精确到小时）
  final DateTime recordedAt;

  /// 记录人 ID
  final int? recordedBy;

  /// 是否空腹体重
  final bool isFasting;

  /// 备注
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Weight(
      {required this.id,
      required this.uuid,
      required this.birdId,
      required this.weightG,
      required this.recordedAt,
      this.recordedBy,
      required this.isFasting,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['bird_id'] = Variable<int>(birdId);
    map['weight_g'] = Variable<double>(weightG);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || recordedBy != null) {
      map['recorded_by'] = Variable<int>(recordedBy);
    }
    map['is_fasting'] = Variable<bool>(isFasting);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WeightsCompanion toCompanion(bool nullToAbsent) {
    return WeightsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      birdId: Value(birdId),
      weightG: Value(weightG),
      recordedAt: Value(recordedAt),
      recordedBy: recordedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(recordedBy),
      isFasting: Value(isFasting),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Weight.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Weight(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      birdId: serializer.fromJson<int>(json['birdId']),
      weightG: serializer.fromJson<double>(json['weightG']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      recordedBy: serializer.fromJson<int?>(json['recordedBy']),
      isFasting: serializer.fromJson<bool>(json['isFasting']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'birdId': serializer.toJson<int>(birdId),
      'weightG': serializer.toJson<double>(weightG),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'recordedBy': serializer.toJson<int?>(recordedBy),
      'isFasting': serializer.toJson<bool>(isFasting),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Weight copyWith(
          {int? id,
          String? uuid,
          int? birdId,
          double? weightG,
          DateTime? recordedAt,
          Value<int?> recordedBy = const Value.absent(),
          bool? isFasting,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Weight(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        birdId: birdId ?? this.birdId,
        weightG: weightG ?? this.weightG,
        recordedAt: recordedAt ?? this.recordedAt,
        recordedBy: recordedBy.present ? recordedBy.value : this.recordedBy,
        isFasting: isFasting ?? this.isFasting,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Weight copyWithCompanion(WeightsCompanion data) {
    return Weight(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      birdId: data.birdId.present ? data.birdId.value : this.birdId,
      weightG: data.weightG.present ? data.weightG.value : this.weightG,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      recordedBy:
          data.recordedBy.present ? data.recordedBy.value : this.recordedBy,
      isFasting: data.isFasting.present ? data.isFasting.value : this.isFasting,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Weight(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('weightG: $weightG, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('isFasting: $isFasting, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, birdId, weightG, recordedAt,
      recordedBy, isFasting, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Weight &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.birdId == this.birdId &&
          other.weightG == this.weightG &&
          other.recordedAt == this.recordedAt &&
          other.recordedBy == this.recordedBy &&
          other.isFasting == this.isFasting &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WeightsCompanion extends UpdateCompanion<Weight> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> birdId;
  final Value<double> weightG;
  final Value<DateTime> recordedAt;
  final Value<int?> recordedBy;
  final Value<bool> isFasting;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WeightsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.birdId = const Value.absent(),
    this.weightG = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.isFasting = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WeightsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int birdId,
    required double weightG,
    required DateTime recordedAt,
    this.recordedBy = const Value.absent(),
    this.isFasting = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        birdId = Value(birdId),
        weightG = Value(weightG),
        recordedAt = Value(recordedAt);
  static Insertable<Weight> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? birdId,
    Expression<double>? weightG,
    Expression<DateTime>? recordedAt,
    Expression<int>? recordedBy,
    Expression<bool>? isFasting,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (birdId != null) 'bird_id': birdId,
      if (weightG != null) 'weight_g': weightG,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (isFasting != null) 'is_fasting': isFasting,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WeightsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? birdId,
      Value<double>? weightG,
      Value<DateTime>? recordedAt,
      Value<int?>? recordedBy,
      Value<bool>? isFasting,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return WeightsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      birdId: birdId ?? this.birdId,
      weightG: weightG ?? this.weightG,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
      isFasting: isFasting ?? this.isFasting,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (birdId.present) {
      map['bird_id'] = Variable<int>(birdId.value);
    }
    if (weightG.present) {
      map['weight_g'] = Variable<double>(weightG.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<int>(recordedBy.value);
    }
    if (isFasting.present) {
      map['is_fasting'] = Variable<bool>(isFasting.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('weightG: $weightG, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('isFasting: $isFasting, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _birdIdMeta = const VerificationMeta('birdId');
  @override
  late final GeneratedColumn<int> birdId = GeneratedColumn<int>(
      'bird_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES birds (id) ON DELETE CASCADE'));
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<int> roomId = GeneratedColumn<int>(
      'room_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES rooms (id)'));
  static const VerificationMeta _assignedUserIdMeta =
      const VerificationMeta('assignedUserId');
  @override
  late final GeneratedColumn<int> assignedUserId = GeneratedColumn<int>(
      'assigned_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _taskTypeMeta =
      const VerificationMeta('taskType');
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
      'task_type', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('weigh'));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deadlineMeta =
      const VerificationMeta('deadline');
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
      'deadline', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('待完成'));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedByMeta =
      const VerificationMeta('completedBy');
  @override
  late final GeneratedColumn<int> completedBy = GeneratedColumn<int>(
      'completed_by', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        birdId,
        roomId,
        assignedUserId,
        taskType,
        dueDate,
        deadline,
        status,
        completedAt,
        completedBy,
        metadata,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('bird_id')) {
      context.handle(_birdIdMeta,
          birdId.isAcceptableOrUnknown(data['bird_id']!, _birdIdMeta));
    } else if (isInserting) {
      context.missing(_birdIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    }
    if (data.containsKey('assigned_user_id')) {
      context.handle(
          _assignedUserIdMeta,
          assignedUserId.isAcceptableOrUnknown(
              data['assigned_user_id']!, _assignedUserIdMeta));
    }
    if (data.containsKey('task_type')) {
      context.handle(_taskTypeMeta,
          taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(_deadlineMeta,
          deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('completed_by')) {
      context.handle(
          _completedByMeta,
          completedBy.isAcceptableOrUnknown(
              data['completed_by']!, _completedByMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      birdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bird_id'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}room_id']),
      assignedUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}assigned_user_id']),
      taskType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_type'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date'])!,
      deadline: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deadline']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      completedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_by']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String uuid;

  /// 鹦鹉 ID
  final int birdId;

  /// 房间 ID（冗余，方便按房间看任务）
  final int? roomId;

  /// 指派人
  final int? assignedUserId;

  /// 任务类型：weigh / medication / ...
  final String taskType;

  /// 任务日期（weigh 为当天 taskReadyTime（工作开始前30min），medication 为具体喂药时间）
  final DateTime dueDate;

  /// 逾期截止时间（weigh 为次日 taskReadyTime，medication 为下一剂时间；生成时算好写入）
  final DateTime? deadline;

  /// 任务状态：待完成/已完成/逾期/已跳过
  final String status;

  /// 完成时间
  final DateTime? completedAt;

  /// 完成人
  final int? completedBy;

  /// 插件私有数据（JSON），如喂药任务存 drugName/dosage/medicationId
  final String? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Task(
      {required this.id,
      required this.uuid,
      required this.birdId,
      this.roomId,
      this.assignedUserId,
      required this.taskType,
      required this.dueDate,
      this.deadline,
      required this.status,
      this.completedAt,
      this.completedBy,
      this.metadata,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['bird_id'] = Variable<int>(birdId);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<int>(roomId);
    }
    if (!nullToAbsent || assignedUserId != null) {
      map['assigned_user_id'] = Variable<int>(assignedUserId);
    }
    map['task_type'] = Variable<String>(taskType);
    map['due_date'] = Variable<DateTime>(dueDate);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || completedBy != null) {
      map['completed_by'] = Variable<int>(completedBy);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      uuid: Value(uuid),
      birdId: Value(birdId),
      roomId:
          roomId == null && nullToAbsent ? const Value.absent() : Value(roomId),
      assignedUserId: assignedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedUserId),
      taskType: Value(taskType),
      dueDate: Value(dueDate),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completedBy: completedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(completedBy),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      birdId: serializer.fromJson<int>(json['birdId']),
      roomId: serializer.fromJson<int?>(json['roomId']),
      assignedUserId: serializer.fromJson<int?>(json['assignedUserId']),
      taskType: serializer.fromJson<String>(json['taskType']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      status: serializer.fromJson<String>(json['status']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      completedBy: serializer.fromJson<int?>(json['completedBy']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'birdId': serializer.toJson<int>(birdId),
      'roomId': serializer.toJson<int?>(roomId),
      'assignedUserId': serializer.toJson<int?>(assignedUserId),
      'taskType': serializer.toJson<String>(taskType),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'status': serializer.toJson<String>(status),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'completedBy': serializer.toJson<int?>(completedBy),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith(
          {int? id,
          String? uuid,
          int? birdId,
          Value<int?> roomId = const Value.absent(),
          Value<int?> assignedUserId = const Value.absent(),
          String? taskType,
          DateTime? dueDate,
          Value<DateTime?> deadline = const Value.absent(),
          String? status,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<int?> completedBy = const Value.absent(),
          Value<String?> metadata = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Task(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        birdId: birdId ?? this.birdId,
        roomId: roomId.present ? roomId.value : this.roomId,
        assignedUserId:
            assignedUserId.present ? assignedUserId.value : this.assignedUserId,
        taskType: taskType ?? this.taskType,
        dueDate: dueDate ?? this.dueDate,
        deadline: deadline.present ? deadline.value : this.deadline,
        status: status ?? this.status,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        completedBy: completedBy.present ? completedBy.value : this.completedBy,
        metadata: metadata.present ? metadata.value : this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      birdId: data.birdId.present ? data.birdId.value : this.birdId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      assignedUserId: data.assignedUserId.present
          ? data.assignedUserId.value
          : this.assignedUserId,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      status: data.status.present ? data.status.value : this.status,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      completedBy:
          data.completedBy.present ? data.completedBy.value : this.completedBy,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('roomId: $roomId, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('taskType: $taskType, ')
          ..write('dueDate: $dueDate, ')
          ..write('deadline: $deadline, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedBy: $completedBy, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      uuid,
      birdId,
      roomId,
      assignedUserId,
      taskType,
      dueDate,
      deadline,
      status,
      completedAt,
      completedBy,
      metadata,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.birdId == this.birdId &&
          other.roomId == this.roomId &&
          other.assignedUserId == this.assignedUserId &&
          other.taskType == this.taskType &&
          other.dueDate == this.dueDate &&
          other.deadline == this.deadline &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.completedBy == this.completedBy &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> birdId;
  final Value<int?> roomId;
  final Value<int?> assignedUserId;
  final Value<String> taskType;
  final Value<DateTime> dueDate;
  final Value<DateTime?> deadline;
  final Value<String> status;
  final Value<DateTime?> completedAt;
  final Value<int?> completedBy;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.birdId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.taskType = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.deadline = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedBy = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int birdId,
    this.roomId = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.taskType = const Value.absent(),
    required DateTime dueDate,
    this.deadline = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedBy = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        birdId = Value(birdId),
        dueDate = Value(dueDate);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? birdId,
    Expression<int>? roomId,
    Expression<int>? assignedUserId,
    Expression<String>? taskType,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? deadline,
    Expression<String>? status,
    Expression<DateTime>? completedAt,
    Expression<int>? completedBy,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (birdId != null) 'bird_id': birdId,
      if (roomId != null) 'room_id': roomId,
      if (assignedUserId != null) 'assigned_user_id': assignedUserId,
      if (taskType != null) 'task_type': taskType,
      if (dueDate != null) 'due_date': dueDate,
      if (deadline != null) 'deadline': deadline,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (completedBy != null) 'completed_by': completedBy,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TasksCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? birdId,
      Value<int?>? roomId,
      Value<int?>? assignedUserId,
      Value<String>? taskType,
      Value<DateTime>? dueDate,
      Value<DateTime?>? deadline,
      Value<String>? status,
      Value<DateTime?>? completedAt,
      Value<int?>? completedBy,
      Value<String?>? metadata,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return TasksCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      birdId: birdId ?? this.birdId,
      roomId: roomId ?? this.roomId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      taskType: taskType ?? this.taskType,
      dueDate: dueDate ?? this.dueDate,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (birdId.present) {
      map['bird_id'] = Variable<int>(birdId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<int>(roomId.value);
    }
    if (assignedUserId.present) {
      map['assigned_user_id'] = Variable<int>(assignedUserId.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (completedBy.present) {
      map['completed_by'] = Variable<int>(completedBy.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('roomId: $roomId, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('taskType: $taskType, ')
          ..write('dueDate: $dueDate, ')
          ..write('deadline: $deadline, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedBy: $completedBy, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AlertRecordsTable extends AlertRecords
    with TableInfo<$AlertRecordsTable, AlertRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _birdIdMeta = const VerificationMeta('birdId');
  @override
  late final GeneratedColumn<int> birdId = GeneratedColumn<int>(
      'bird_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES birds (id) ON DELETE CASCADE'));
  static const VerificationMeta _alertTypeMeta =
      const VerificationMeta('alertType');
  @override
  late final GeneratedColumn<String> alertType = GeneratedColumn<String>(
      'alert_type', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
      'severity', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isResolvedMeta =
      const VerificationMeta('isResolved');
  @override
  late final GeneratedColumn<bool> isResolved = GeneratedColumn<bool>(
      'is_resolved', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_resolved" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _resolvedAtMeta =
      const VerificationMeta('resolvedAt');
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
      'resolved_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        birdId,
        alertType,
        description,
        severity,
        isRead,
        isResolved,
        createdAt,
        updatedAt,
        resolvedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alert_records';
  @override
  VerificationContext validateIntegrity(Insertable<AlertRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('bird_id')) {
      context.handle(_birdIdMeta,
          birdId.isAcceptableOrUnknown(data['bird_id']!, _birdIdMeta));
    } else if (isInserting) {
      context.missing(_birdIdMeta);
    }
    if (data.containsKey('alert_type')) {
      context.handle(_alertTypeMeta,
          alertType.isAcceptableOrUnknown(data['alert_type']!, _alertTypeMeta));
    } else if (isInserting) {
      context.missing(_alertTypeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('is_resolved')) {
      context.handle(
          _isResolvedMeta,
          isResolved.isAcceptableOrUnknown(
              data['is_resolved']!, _isResolvedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
          _resolvedAtMeta,
          resolvedAt.isAcceptableOrUnknown(
              data['resolved_at']!, _resolvedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlertRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      birdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bird_id'])!,
      alertType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alert_type'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      isResolved: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_resolved'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      resolvedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}resolved_at']),
    );
  }

  @override
  $AlertRecordsTable createAlias(String alias) {
    return $AlertRecordsTable(attachedDatabase, alias);
  }
}

class AlertRecord extends DataClass implements Insertable<AlertRecord> {
  final int id;
  final String uuid;

  /// 鹦鹉 ID
  final int birdId;

  /// 提醒类型：体重下降/增长停滞/超期未称重/长期未记录
  final String alertType;

  /// 提醒详情
  final String description;

  /// 严重程度: warning / danger
  final String severity;

  /// 是否已读
  final bool isRead;

  /// 是否已解决
  final bool isResolved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  const AlertRecord(
      {required this.id,
      required this.uuid,
      required this.birdId,
      required this.alertType,
      required this.description,
      required this.severity,
      required this.isRead,
      required this.isResolved,
      required this.createdAt,
      required this.updatedAt,
      this.resolvedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['bird_id'] = Variable<int>(birdId);
    map['alert_type'] = Variable<String>(alertType);
    map['description'] = Variable<String>(description);
    map['severity'] = Variable<String>(severity);
    map['is_read'] = Variable<bool>(isRead);
    map['is_resolved'] = Variable<bool>(isResolved);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  AlertRecordsCompanion toCompanion(bool nullToAbsent) {
    return AlertRecordsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      birdId: Value(birdId),
      alertType: Value(alertType),
      description: Value(description),
      severity: Value(severity),
      isRead: Value(isRead),
      isResolved: Value(isResolved),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory AlertRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertRecord(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      birdId: serializer.fromJson<int>(json['birdId']),
      alertType: serializer.fromJson<String>(json['alertType']),
      description: serializer.fromJson<String>(json['description']),
      severity: serializer.fromJson<String>(json['severity']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      isResolved: serializer.fromJson<bool>(json['isResolved']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'birdId': serializer.toJson<int>(birdId),
      'alertType': serializer.toJson<String>(alertType),
      'description': serializer.toJson<String>(description),
      'severity': serializer.toJson<String>(severity),
      'isRead': serializer.toJson<bool>(isRead),
      'isResolved': serializer.toJson<bool>(isResolved),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  AlertRecord copyWith(
          {int? id,
          String? uuid,
          int? birdId,
          String? alertType,
          String? description,
          String? severity,
          bool? isRead,
          bool? isResolved,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> resolvedAt = const Value.absent()}) =>
      AlertRecord(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        birdId: birdId ?? this.birdId,
        alertType: alertType ?? this.alertType,
        description: description ?? this.description,
        severity: severity ?? this.severity,
        isRead: isRead ?? this.isRead,
        isResolved: isResolved ?? this.isResolved,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
      );
  AlertRecord copyWithCompanion(AlertRecordsCompanion data) {
    return AlertRecord(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      birdId: data.birdId.present ? data.birdId.value : this.birdId,
      alertType: data.alertType.present ? data.alertType.value : this.alertType,
      description:
          data.description.present ? data.description.value : this.description,
      severity: data.severity.present ? data.severity.value : this.severity,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      isResolved:
          data.isResolved.present ? data.isResolved.value : this.isResolved,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      resolvedAt:
          data.resolvedAt.present ? data.resolvedAt.value : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertRecord(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('alertType: $alertType, ')
          ..write('description: $description, ')
          ..write('severity: $severity, ')
          ..write('isRead: $isRead, ')
          ..write('isResolved: $isResolved, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, birdId, alertType, description,
      severity, isRead, isResolved, createdAt, updatedAt, resolvedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertRecord &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.birdId == this.birdId &&
          other.alertType == this.alertType &&
          other.description == this.description &&
          other.severity == this.severity &&
          other.isRead == this.isRead &&
          other.isResolved == this.isResolved &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.resolvedAt == this.resolvedAt);
}

class AlertRecordsCompanion extends UpdateCompanion<AlertRecord> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> birdId;
  final Value<String> alertType;
  final Value<String> description;
  final Value<String> severity;
  final Value<bool> isRead;
  final Value<bool> isResolved;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> resolvedAt;
  const AlertRecordsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.birdId = const Value.absent(),
    this.alertType = const Value.absent(),
    this.description = const Value.absent(),
    this.severity = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isResolved = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  });
  AlertRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int birdId,
    required String alertType,
    required String description,
    required String severity,
    this.isRead = const Value.absent(),
    this.isResolved = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        birdId = Value(birdId),
        alertType = Value(alertType),
        description = Value(description),
        severity = Value(severity);
  static Insertable<AlertRecord> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? birdId,
    Expression<String>? alertType,
    Expression<String>? description,
    Expression<String>? severity,
    Expression<bool>? isRead,
    Expression<bool>? isResolved,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? resolvedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (birdId != null) 'bird_id': birdId,
      if (alertType != null) 'alert_type': alertType,
      if (description != null) 'description': description,
      if (severity != null) 'severity': severity,
      if (isRead != null) 'is_read': isRead,
      if (isResolved != null) 'is_resolved': isResolved,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
    });
  }

  AlertRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? birdId,
      Value<String>? alertType,
      Value<String>? description,
      Value<String>? severity,
      Value<bool>? isRead,
      Value<bool>? isResolved,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? resolvedAt}) {
    return AlertRecordsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      birdId: birdId ?? this.birdId,
      alertType: alertType ?? this.alertType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (birdId.present) {
      map['bird_id'] = Variable<int>(birdId.value);
    }
    if (alertType.present) {
      map['alert_type'] = Variable<String>(alertType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (isResolved.present) {
      map['is_resolved'] = Variable<bool>(isResolved.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertRecordsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('alertType: $alertType, ')
          ..write('description: $description, ')
          ..write('severity: $severity, ')
          ..write('isRead: $isRead, ')
          ..write('isResolved: $isResolved, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
      'op_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityUuidMeta =
      const VerificationMeta('entityUuid');
  @override
  late final GeneratedColumn<String> entityUuid = GeneratedColumn<String>(
      'entity_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        opId,
        deviceId,
        userId,
        action,
        entityType,
        entityUuid,
        payload,
        createdAt,
        synced,
        retryCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('op_id')) {
      context.handle(
          _opIdMeta, opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta));
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_uuid')) {
      context.handle(
          _entityUuidMeta,
          entityUuid.isAcceptableOrUnknown(
              data['entity_uuid']!, _entityUuidMeta));
    } else if (isInserting) {
      context.missing(_entityUuidMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      opId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op_id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_uuid'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String opId;
  final String deviceId;
  final int userId;
  final String action;
  final String entityType;
  final String entityUuid;
  final String payload;
  final DateTime createdAt;
  final bool synced;
  final int retryCount;
  const SyncQueueData(
      {required this.id,
      required this.opId,
      required this.deviceId,
      required this.userId,
      required this.action,
      required this.entityType,
      required this.entityUuid,
      required this.payload,
      required this.createdAt,
      required this.synced,
      required this.retryCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['op_id'] = Variable<String>(opId);
    map['device_id'] = Variable<String>(deviceId);
    map['user_id'] = Variable<int>(userId);
    map['action'] = Variable<String>(action);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_uuid'] = Variable<String>(entityUuid);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      opId: Value(opId),
      deviceId: Value(deviceId),
      userId: Value(userId),
      action: Value(action),
      entityType: Value(entityType),
      entityUuid: Value(entityUuid),
      payload: Value(payload),
      createdAt: Value(createdAt),
      synced: Value(synced),
      retryCount: Value(retryCount),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      opId: serializer.fromJson<String>(json['opId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      userId: serializer.fromJson<int>(json['userId']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityUuid: serializer.fromJson<String>(json['entityUuid']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'opId': serializer.toJson<String>(opId),
      'deviceId': serializer.toJson<String>(deviceId),
      'userId': serializer.toJson<int>(userId),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String>(entityType),
      'entityUuid': serializer.toJson<String>(entityUuid),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? opId,
          String? deviceId,
          int? userId,
          String? action,
          String? entityType,
          String? entityUuid,
          String? payload,
          DateTime? createdAt,
          bool? synced,
          int? retryCount}) =>
      SyncQueueData(
        id: id ?? this.id,
        opId: opId ?? this.opId,
        deviceId: deviceId ?? this.deviceId,
        userId: userId ?? this.userId,
        action: action ?? this.action,
        entityType: entityType ?? this.entityType,
        entityUuid: entityUuid ?? this.entityUuid,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
        retryCount: retryCount ?? this.retryCount,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      opId: data.opId.present ? data.opId.value : this.opId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      userId: data.userId.present ? data.userId.value : this.userId,
      action: data.action.present ? data.action.value : this.action,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityUuid:
          data.entityUuid.present ? data.entityUuid.value : this.entityUuid,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('opId: $opId, ')
          ..write('deviceId: $deviceId, ')
          ..write('userId: $userId, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityUuid: $entityUuid, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, opId, deviceId, userId, action,
      entityType, entityUuid, payload, createdAt, synced, retryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.opId == this.opId &&
          other.deviceId == this.deviceId &&
          other.userId == this.userId &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityUuid == this.entityUuid &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced &&
          other.retryCount == this.retryCount);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> opId;
  final Value<String> deviceId;
  final Value<int> userId;
  final Value<String> action;
  final Value<String> entityType;
  final Value<String> entityUuid;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<int> retryCount;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.opId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.userId = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityUuid = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String opId,
    required String deviceId,
    required int userId,
    required String action,
    required String entityType,
    required String entityUuid,
    required String payload,
    required DateTime createdAt,
    this.synced = const Value.absent(),
    this.retryCount = const Value.absent(),
  })  : opId = Value(opId),
        deviceId = Value(deviceId),
        userId = Value(userId),
        action = Value(action),
        entityType = Value(entityType),
        entityUuid = Value(entityUuid),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? opId,
    Expression<String>? deviceId,
    Expression<int>? userId,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<String>? entityUuid,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (opId != null) 'op_id': opId,
      if (deviceId != null) 'device_id': deviceId,
      if (userId != null) 'user_id': userId,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityUuid != null) 'entity_uuid': entityUuid,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? opId,
      Value<String>? deviceId,
      Value<int>? userId,
      Value<String>? action,
      Value<String>? entityType,
      Value<String>? entityUuid,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<bool>? synced,
      Value<int>? retryCount}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      opId: opId ?? this.opId,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityUuid: entityUuid ?? this.entityUuid,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityUuid.present) {
      map['entity_uuid'] = Variable<String>(entityUuid.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('opId: $opId, ')
          ..write('deviceId: $deviceId, ')
          ..write('userId: $userId, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityUuid: $entityUuid, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _birdIdMeta = const VerificationMeta('birdId');
  @override
  late final GeneratedColumn<int> birdId = GeneratedColumn<int>(
      'bird_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES birds (id) ON DELETE CASCADE'));
  static const VerificationMeta _drugNameMeta =
      const VerificationMeta('drugName');
  @override
  late final GeneratedColumn<String> drugName = GeneratedColumn<String>(
      'drug_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _drugTypeMeta =
      const VerificationMeta('drugType');
  @override
  late final GeneratedColumn<String> drugType = GeneratedColumn<String>(
      'drug_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('其他'));
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
      'dosage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timesPerDayMeta =
      const VerificationMeta('timesPerDay');
  @override
  late final GeneratedColumn<int> timesPerDay = GeneratedColumn<int>(
      'times_per_day', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        birdId,
        drugName,
        drugType,
        dosage,
        timesPerDay,
        startDate,
        endDate,
        notes,
        active,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(Insertable<Medication> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('bird_id')) {
      context.handle(_birdIdMeta,
          birdId.isAcceptableOrUnknown(data['bird_id']!, _birdIdMeta));
    } else if (isInserting) {
      context.missing(_birdIdMeta);
    }
    if (data.containsKey('drug_name')) {
      context.handle(_drugNameMeta,
          drugName.isAcceptableOrUnknown(data['drug_name']!, _drugNameMeta));
    } else if (isInserting) {
      context.missing(_drugNameMeta);
    }
    if (data.containsKey('drug_type')) {
      context.handle(_drugTypeMeta,
          drugType.isAcceptableOrUnknown(data['drug_type']!, _drugTypeMeta));
    }
    if (data.containsKey('dosage')) {
      context.handle(_dosageMeta,
          dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta));
    } else if (isInserting) {
      context.missing(_dosageMeta);
    }
    if (data.containsKey('times_per_day')) {
      context.handle(
          _timesPerDayMeta,
          timesPerDay.isAcceptableOrUnknown(
              data['times_per_day']!, _timesPerDayMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      birdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bird_id'])!,
      drugName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}drug_name'])!,
      drugType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}drug_type'])!,
      dosage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dosage'])!,
      timesPerDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}times_per_day'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class Medication extends DataClass implements Insertable<Medication> {
  final int id;
  final String uuid;

  /// 鹦鹉 ID
  final int birdId;

  /// 药品名称
  final String drugName;

  /// 药品类型：抗生素/驱虫/维生素/其他
  final String drugType;

  /// 剂量（如 "0.5ml", "1片", "2滴"）
  final String dosage;

  /// 每天次数（1/2/3）
  final int timesPerDay;

  /// 开始日期
  final DateTime startDate;

  /// 结束日期（null=持续）
  final DateTime? endDate;

  /// 备注
  final String? notes;

  /// 是否启用
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Medication(
      {required this.id,
      required this.uuid,
      required this.birdId,
      required this.drugName,
      required this.drugType,
      required this.dosage,
      required this.timesPerDay,
      required this.startDate,
      this.endDate,
      this.notes,
      required this.active,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['bird_id'] = Variable<int>(birdId);
    map['drug_name'] = Variable<String>(drugName);
    map['drug_type'] = Variable<String>(drugType);
    map['dosage'] = Variable<String>(dosage);
    map['times_per_day'] = Variable<int>(timesPerDay);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      birdId: Value(birdId),
      drugName: Value(drugName),
      drugType: Value(drugType),
      dosage: Value(dosage),
      timesPerDay: Value(timesPerDay),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Medication.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      birdId: serializer.fromJson<int>(json['birdId']),
      drugName: serializer.fromJson<String>(json['drugName']),
      drugType: serializer.fromJson<String>(json['drugType']),
      dosage: serializer.fromJson<String>(json['dosage']),
      timesPerDay: serializer.fromJson<int>(json['timesPerDay']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'birdId': serializer.toJson<int>(birdId),
      'drugName': serializer.toJson<String>(drugName),
      'drugType': serializer.toJson<String>(drugType),
      'dosage': serializer.toJson<String>(dosage),
      'timesPerDay': serializer.toJson<int>(timesPerDay),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'notes': serializer.toJson<String?>(notes),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Medication copyWith(
          {int? id,
          String? uuid,
          int? birdId,
          String? drugName,
          String? drugType,
          String? dosage,
          int? timesPerDay,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? active,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Medication(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        birdId: birdId ?? this.birdId,
        drugName: drugName ?? this.drugName,
        drugType: drugType ?? this.drugType,
        dosage: dosage ?? this.dosage,
        timesPerDay: timesPerDay ?? this.timesPerDay,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        notes: notes.present ? notes.value : this.notes,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      birdId: data.birdId.present ? data.birdId.value : this.birdId,
      drugName: data.drugName.present ? data.drugName.value : this.drugName,
      drugType: data.drugType.present ? data.drugType.value : this.drugType,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      timesPerDay:
          data.timesPerDay.present ? data.timesPerDay.value : this.timesPerDay,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('drugName: $drugName, ')
          ..write('drugType: $drugType, ')
          ..write('dosage: $dosage, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('notes: $notes, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, birdId, drugName, drugType, dosage,
      timesPerDay, startDate, endDate, notes, active, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.birdId == this.birdId &&
          other.drugName == this.drugName &&
          other.drugType == this.drugType &&
          other.dosage == this.dosage &&
          other.timesPerDay == this.timesPerDay &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.notes == this.notes &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> birdId;
  final Value<String> drugName;
  final Value<String> drugType;
  final Value<String> dosage;
  final Value<int> timesPerDay;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<String?> notes;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.birdId = const Value.absent(),
    this.drugName = const Value.absent(),
    this.drugType = const Value.absent(),
    this.dosage = const Value.absent(),
    this.timesPerDay = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MedicationsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int birdId,
    required String drugName,
    this.drugType = const Value.absent(),
    required String dosage,
    this.timesPerDay = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        birdId = Value(birdId),
        drugName = Value(drugName),
        dosage = Value(dosage),
        startDate = Value(startDate);
  static Insertable<Medication> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? birdId,
    Expression<String>? drugName,
    Expression<String>? drugType,
    Expression<String>? dosage,
    Expression<int>? timesPerDay,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? notes,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (birdId != null) 'bird_id': birdId,
      if (drugName != null) 'drug_name': drugName,
      if (drugType != null) 'drug_type': drugType,
      if (dosage != null) 'dosage': dosage,
      if (timesPerDay != null) 'times_per_day': timesPerDay,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (notes != null) 'notes': notes,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MedicationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? birdId,
      Value<String>? drugName,
      Value<String>? drugType,
      Value<String>? dosage,
      Value<int>? timesPerDay,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<String?>? notes,
      Value<bool>? active,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return MedicationsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      birdId: birdId ?? this.birdId,
      drugName: drugName ?? this.drugName,
      drugType: drugType ?? this.drugType,
      dosage: dosage ?? this.dosage,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (birdId.present) {
      map['bird_id'] = Variable<int>(birdId.value);
    }
    if (drugName.present) {
      map['drug_name'] = Variable<String>(drugName.value);
    }
    if (drugType.present) {
      map['drug_type'] = Variable<String>(drugType.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (timesPerDay.present) {
      map['times_per_day'] = Variable<int>(timesPerDay.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('drugName: $drugName, ')
          ..write('drugType: $drugType, ')
          ..write('dosage: $dosage, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('notes: $notes, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BreedingPairsTable extends BreedingPairs
    with TableInfo<$BreedingPairsTable, BreedingPair> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BreedingPairsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _maleBirdIdMeta =
      const VerificationMeta('maleBirdId');
  @override
  late final GeneratedColumn<int> maleBirdId = GeneratedColumn<int>(
      'male_bird_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES birds (id) ON DELETE CASCADE'));
  static const VerificationMeta _femaleBirdIdMeta =
      const VerificationMeta('femaleBirdId');
  @override
  late final GeneratedColumn<int> femaleBirdId = GeneratedColumn<int>(
      'female_bird_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES birds (id) ON DELETE CASCADE'));
  static const VerificationMeta _pairNameMeta =
      const VerificationMeta('pairName');
  @override
  late final GeneratedColumn<String> pairName = GeneratedColumn<String>(
      'pair_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _pairedDateMeta =
      const VerificationMeta('pairedDate');
  @override
  late final GeneratedColumn<DateTime> pairedDate = GeneratedColumn<DateTime>(
      'paired_date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _separatedDateMeta =
      const VerificationMeta('separatedDate');
  @override
  late final GeneratedColumn<DateTime> separatedDate =
      GeneratedColumn<DateTime>('separated_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        maleBirdId,
        femaleBirdId,
        pairName,
        status,
        pairedDate,
        separatedDate,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'breeding_pairs';
  @override
  VerificationContext validateIntegrity(Insertable<BreedingPair> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('male_bird_id')) {
      context.handle(
          _maleBirdIdMeta,
          maleBirdId.isAcceptableOrUnknown(
              data['male_bird_id']!, _maleBirdIdMeta));
    } else if (isInserting) {
      context.missing(_maleBirdIdMeta);
    }
    if (data.containsKey('female_bird_id')) {
      context.handle(
          _femaleBirdIdMeta,
          femaleBirdId.isAcceptableOrUnknown(
              data['female_bird_id']!, _femaleBirdIdMeta));
    } else if (isInserting) {
      context.missing(_femaleBirdIdMeta);
    }
    if (data.containsKey('pair_name')) {
      context.handle(_pairNameMeta,
          pairName.isAcceptableOrUnknown(data['pair_name']!, _pairNameMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('paired_date')) {
      context.handle(
          _pairedDateMeta,
          pairedDate.isAcceptableOrUnknown(
              data['paired_date']!, _pairedDateMeta));
    }
    if (data.containsKey('separated_date')) {
      context.handle(
          _separatedDateMeta,
          separatedDate.isAcceptableOrUnknown(
              data['separated_date']!, _separatedDateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BreedingPair map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BreedingPair(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      maleBirdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}male_bird_id'])!,
      femaleBirdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}female_bird_id'])!,
      pairName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pair_name']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      pairedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paired_date'])!,
      separatedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}separated_date']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BreedingPairsTable createAlias(String alias) {
    return $BreedingPairsTable(attachedDatabase, alias);
  }
}

class BreedingPair extends DataClass implements Insertable<BreedingPair> {
  final int id;
  final String uuid;

  /// 公鸟
  final int maleBirdId;

  /// 母鸟
  final int femaleBirdId;

  /// 配对名称（可选，如 "蓝公×绿母"）
  final String? pairName;

  /// 状态：active / separated
  final String status;
  final DateTime pairedDate;
  final DateTime? separatedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BreedingPair(
      {required this.id,
      required this.uuid,
      required this.maleBirdId,
      required this.femaleBirdId,
      this.pairName,
      required this.status,
      required this.pairedDate,
      this.separatedDate,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['male_bird_id'] = Variable<int>(maleBirdId);
    map['female_bird_id'] = Variable<int>(femaleBirdId);
    if (!nullToAbsent || pairName != null) {
      map['pair_name'] = Variable<String>(pairName);
    }
    map['status'] = Variable<String>(status);
    map['paired_date'] = Variable<DateTime>(pairedDate);
    if (!nullToAbsent || separatedDate != null) {
      map['separated_date'] = Variable<DateTime>(separatedDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BreedingPairsCompanion toCompanion(bool nullToAbsent) {
    return BreedingPairsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      maleBirdId: Value(maleBirdId),
      femaleBirdId: Value(femaleBirdId),
      pairName: pairName == null && nullToAbsent
          ? const Value.absent()
          : Value(pairName),
      status: Value(status),
      pairedDate: Value(pairedDate),
      separatedDate: separatedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(separatedDate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BreedingPair.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BreedingPair(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      maleBirdId: serializer.fromJson<int>(json['maleBirdId']),
      femaleBirdId: serializer.fromJson<int>(json['femaleBirdId']),
      pairName: serializer.fromJson<String?>(json['pairName']),
      status: serializer.fromJson<String>(json['status']),
      pairedDate: serializer.fromJson<DateTime>(json['pairedDate']),
      separatedDate: serializer.fromJson<DateTime?>(json['separatedDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'maleBirdId': serializer.toJson<int>(maleBirdId),
      'femaleBirdId': serializer.toJson<int>(femaleBirdId),
      'pairName': serializer.toJson<String?>(pairName),
      'status': serializer.toJson<String>(status),
      'pairedDate': serializer.toJson<DateTime>(pairedDate),
      'separatedDate': serializer.toJson<DateTime?>(separatedDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BreedingPair copyWith(
          {int? id,
          String? uuid,
          int? maleBirdId,
          int? femaleBirdId,
          Value<String?> pairName = const Value.absent(),
          String? status,
          DateTime? pairedDate,
          Value<DateTime?> separatedDate = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      BreedingPair(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        maleBirdId: maleBirdId ?? this.maleBirdId,
        femaleBirdId: femaleBirdId ?? this.femaleBirdId,
        pairName: pairName.present ? pairName.value : this.pairName,
        status: status ?? this.status,
        pairedDate: pairedDate ?? this.pairedDate,
        separatedDate:
            separatedDate.present ? separatedDate.value : this.separatedDate,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BreedingPair copyWithCompanion(BreedingPairsCompanion data) {
    return BreedingPair(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      maleBirdId:
          data.maleBirdId.present ? data.maleBirdId.value : this.maleBirdId,
      femaleBirdId: data.femaleBirdId.present
          ? data.femaleBirdId.value
          : this.femaleBirdId,
      pairName: data.pairName.present ? data.pairName.value : this.pairName,
      status: data.status.present ? data.status.value : this.status,
      pairedDate:
          data.pairedDate.present ? data.pairedDate.value : this.pairedDate,
      separatedDate: data.separatedDate.present
          ? data.separatedDate.value
          : this.separatedDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BreedingPair(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('maleBirdId: $maleBirdId, ')
          ..write('femaleBirdId: $femaleBirdId, ')
          ..write('pairName: $pairName, ')
          ..write('status: $status, ')
          ..write('pairedDate: $pairedDate, ')
          ..write('separatedDate: $separatedDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, maleBirdId, femaleBirdId, pairName,
      status, pairedDate, separatedDate, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BreedingPair &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.maleBirdId == this.maleBirdId &&
          other.femaleBirdId == this.femaleBirdId &&
          other.pairName == this.pairName &&
          other.status == this.status &&
          other.pairedDate == this.pairedDate &&
          other.separatedDate == this.separatedDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BreedingPairsCompanion extends UpdateCompanion<BreedingPair> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> maleBirdId;
  final Value<int> femaleBirdId;
  final Value<String?> pairName;
  final Value<String> status;
  final Value<DateTime> pairedDate;
  final Value<DateTime?> separatedDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BreedingPairsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.maleBirdId = const Value.absent(),
    this.femaleBirdId = const Value.absent(),
    this.pairName = const Value.absent(),
    this.status = const Value.absent(),
    this.pairedDate = const Value.absent(),
    this.separatedDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BreedingPairsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int maleBirdId,
    required int femaleBirdId,
    this.pairName = const Value.absent(),
    this.status = const Value.absent(),
    this.pairedDate = const Value.absent(),
    this.separatedDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        maleBirdId = Value(maleBirdId),
        femaleBirdId = Value(femaleBirdId);
  static Insertable<BreedingPair> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? maleBirdId,
    Expression<int>? femaleBirdId,
    Expression<String>? pairName,
    Expression<String>? status,
    Expression<DateTime>? pairedDate,
    Expression<DateTime>? separatedDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (maleBirdId != null) 'male_bird_id': maleBirdId,
      if (femaleBirdId != null) 'female_bird_id': femaleBirdId,
      if (pairName != null) 'pair_name': pairName,
      if (status != null) 'status': status,
      if (pairedDate != null) 'paired_date': pairedDate,
      if (separatedDate != null) 'separated_date': separatedDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BreedingPairsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? maleBirdId,
      Value<int>? femaleBirdId,
      Value<String?>? pairName,
      Value<String>? status,
      Value<DateTime>? pairedDate,
      Value<DateTime?>? separatedDate,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return BreedingPairsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      maleBirdId: maleBirdId ?? this.maleBirdId,
      femaleBirdId: femaleBirdId ?? this.femaleBirdId,
      pairName: pairName ?? this.pairName,
      status: status ?? this.status,
      pairedDate: pairedDate ?? this.pairedDate,
      separatedDate: separatedDate ?? this.separatedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (maleBirdId.present) {
      map['male_bird_id'] = Variable<int>(maleBirdId.value);
    }
    if (femaleBirdId.present) {
      map['female_bird_id'] = Variable<int>(femaleBirdId.value);
    }
    if (pairName.present) {
      map['pair_name'] = Variable<String>(pairName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pairedDate.present) {
      map['paired_date'] = Variable<DateTime>(pairedDate.value);
    }
    if (separatedDate.present) {
      map['separated_date'] = Variable<DateTime>(separatedDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BreedingPairsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('maleBirdId: $maleBirdId, ')
          ..write('femaleBirdId: $femaleBirdId, ')
          ..write('pairName: $pairName, ')
          ..write('status: $status, ')
          ..write('pairedDate: $pairedDate, ')
          ..write('separatedDate: $separatedDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BreedingRecordsTable extends BreedingRecords
    with TableInfo<$BreedingRecordsTable, BreedingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BreedingRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _pairIdMeta = const VerificationMeta('pairId');
  @override
  late final GeneratedColumn<int> pairId = GeneratedColumn<int>(
      'pair_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES breeding_pairs (id) ON DELETE CASCADE'));
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
      'stage', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('配对'));
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endReasonMeta =
      const VerificationMeta('endReason');
  @override
  late final GeneratedColumn<String> endReason = GeneratedColumn<String>(
      'end_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        pairId,
        stage,
        startDate,
        endDate,
        endReason,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'breeding_records';
  @override
  VerificationContext validateIntegrity(Insertable<BreedingRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('pair_id')) {
      context.handle(_pairIdMeta,
          pairId.isAcceptableOrUnknown(data['pair_id']!, _pairIdMeta));
    } else if (isInserting) {
      context.missing(_pairIdMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
          _stageMeta, stage.isAcceptableOrUnknown(data['stage']!, _stageMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('end_reason')) {
      context.handle(_endReasonMeta,
          endReason.isAcceptableOrUnknown(data['end_reason']!, _endReasonMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BreedingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BreedingRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      pairId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pair_id'])!,
      stage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stage'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      endReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_reason']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BreedingRecordsTable createAlias(String alias) {
    return $BreedingRecordsTable(attachedDatabase, alias);
  }
}

class BreedingRecord extends DataClass implements Insertable<BreedingRecord> {
  final int id;
  final String uuid;

  /// 关联配对
  final int pairId;

  /// 阶段：配对/产蛋/孵化/育雏/已完结
  final String stage;
  final DateTime startDate;
  final DateTime? endDate;

  /// 完结原因（正常完结/亲鸟弃窝/人工掏窝/其他）
  final String? endReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BreedingRecord(
      {required this.id,
      required this.uuid,
      required this.pairId,
      required this.stage,
      required this.startDate,
      this.endDate,
      this.endReason,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['pair_id'] = Variable<int>(pairId);
    map['stage'] = Variable<String>(stage);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || endReason != null) {
      map['end_reason'] = Variable<String>(endReason);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BreedingRecordsCompanion toCompanion(bool nullToAbsent) {
    return BreedingRecordsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      pairId: Value(pairId),
      stage: Value(stage),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      endReason: endReason == null && nullToAbsent
          ? const Value.absent()
          : Value(endReason),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BreedingRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BreedingRecord(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      pairId: serializer.fromJson<int>(json['pairId']),
      stage: serializer.fromJson<String>(json['stage']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      endReason: serializer.fromJson<String?>(json['endReason']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'pairId': serializer.toJson<int>(pairId),
      'stage': serializer.toJson<String>(stage),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'endReason': serializer.toJson<String?>(endReason),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BreedingRecord copyWith(
          {int? id,
          String? uuid,
          int? pairId,
          String? stage,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          Value<String?> endReason = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      BreedingRecord(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        pairId: pairId ?? this.pairId,
        stage: stage ?? this.stage,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        endReason: endReason.present ? endReason.value : this.endReason,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BreedingRecord copyWithCompanion(BreedingRecordsCompanion data) {
    return BreedingRecord(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      pairId: data.pairId.present ? data.pairId.value : this.pairId,
      stage: data.stage.present ? data.stage.value : this.stage,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      endReason: data.endReason.present ? data.endReason.value : this.endReason,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BreedingRecord(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('pairId: $pairId, ')
          ..write('stage: $stage, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('endReason: $endReason, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, pairId, stage, startDate, endDate,
      endReason, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BreedingRecord &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.pairId == this.pairId &&
          other.stage == this.stage &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.endReason == this.endReason &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BreedingRecordsCompanion extends UpdateCompanion<BreedingRecord> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> pairId;
  final Value<String> stage;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<String?> endReason;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BreedingRecordsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.pairId = const Value.absent(),
    this.stage = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.endReason = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BreedingRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int pairId,
    this.stage = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.endReason = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        pairId = Value(pairId);
  static Insertable<BreedingRecord> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? pairId,
    Expression<String>? stage,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? endReason,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (pairId != null) 'pair_id': pairId,
      if (stage != null) 'stage': stage,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (endReason != null) 'end_reason': endReason,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BreedingRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? pairId,
      Value<String>? stage,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<String?>? endReason,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return BreedingRecordsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      pairId: pairId ?? this.pairId,
      stage: stage ?? this.stage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      endReason: endReason ?? this.endReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (pairId.present) {
      map['pair_id'] = Variable<int>(pairId.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (endReason.present) {
      map['end_reason'] = Variable<String>(endReason.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BreedingRecordsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('pairId: $pairId, ')
          ..write('stage: $stage, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('endReason: $endReason, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EggsTable extends Eggs with TableInfo<$EggsTable, Egg> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EggsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _breedingRecordIdMeta =
      const VerificationMeta('breedingRecordId');
  @override
  late final GeneratedColumn<int> breedingRecordId = GeneratedColumn<int>(
      'breeding_record_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES breeding_records (id) ON DELETE CASCADE'));
  static const VerificationMeta _laidDateMeta =
      const VerificationMeta('laidDate');
  @override
  late final GeneratedColumn<DateTime> laidDate = GeneratedColumn<DateTime>(
      'laid_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _hatchDateMeta =
      const VerificationMeta('hatchDate');
  @override
  late final GeneratedColumn<DateTime> hatchDate = GeneratedColumn<DateTime>(
      'hatch_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('孵化中'));
  static const VerificationMeta _chickBirdIdMeta =
      const VerificationMeta('chickBirdId');
  @override
  late final GeneratedColumn<int> chickBirdId = GeneratedColumn<int>(
      'chick_bird_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES birds (id) ON DELETE SET NULL'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        breedingRecordId,
        laidDate,
        hatchDate,
        status,
        chickBirdId,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eggs';
  @override
  VerificationContext validateIntegrity(Insertable<Egg> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('breeding_record_id')) {
      context.handle(
          _breedingRecordIdMeta,
          breedingRecordId.isAcceptableOrUnknown(
              data['breeding_record_id']!, _breedingRecordIdMeta));
    } else if (isInserting) {
      context.missing(_breedingRecordIdMeta);
    }
    if (data.containsKey('laid_date')) {
      context.handle(_laidDateMeta,
          laidDate.isAcceptableOrUnknown(data['laid_date']!, _laidDateMeta));
    } else if (isInserting) {
      context.missing(_laidDateMeta);
    }
    if (data.containsKey('hatch_date')) {
      context.handle(_hatchDateMeta,
          hatchDate.isAcceptableOrUnknown(data['hatch_date']!, _hatchDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('chick_bird_id')) {
      context.handle(
          _chickBirdIdMeta,
          chickBirdId.isAcceptableOrUnknown(
              data['chick_bird_id']!, _chickBirdIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Egg map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Egg(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      breedingRecordId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}breeding_record_id'])!,
      laidDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}laid_date'])!,
      hatchDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}hatch_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      chickBirdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chick_bird_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EggsTable createAlias(String alias) {
    return $EggsTable(attachedDatabase, alias);
  }
}

class Egg extends DataClass implements Insertable<Egg> {
  final int id;
  final String uuid;

  /// 关联繁育记录
  final int breedingRecordId;
  final DateTime laidDate;
  final DateTime? hatchDate;

  /// 状态：孵化中/已出壳/未受精/损坏
  final String status;

  /// 出壳后关联的雏鸟
  final int? chickBirdId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Egg(
      {required this.id,
      required this.uuid,
      required this.breedingRecordId,
      required this.laidDate,
      this.hatchDate,
      required this.status,
      this.chickBirdId,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['breeding_record_id'] = Variable<int>(breedingRecordId);
    map['laid_date'] = Variable<DateTime>(laidDate);
    if (!nullToAbsent || hatchDate != null) {
      map['hatch_date'] = Variable<DateTime>(hatchDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || chickBirdId != null) {
      map['chick_bird_id'] = Variable<int>(chickBirdId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EggsCompanion toCompanion(bool nullToAbsent) {
    return EggsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      breedingRecordId: Value(breedingRecordId),
      laidDate: Value(laidDate),
      hatchDate: hatchDate == null && nullToAbsent
          ? const Value.absent()
          : Value(hatchDate),
      status: Value(status),
      chickBirdId: chickBirdId == null && nullToAbsent
          ? const Value.absent()
          : Value(chickBirdId),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Egg.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Egg(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      breedingRecordId: serializer.fromJson<int>(json['breedingRecordId']),
      laidDate: serializer.fromJson<DateTime>(json['laidDate']),
      hatchDate: serializer.fromJson<DateTime?>(json['hatchDate']),
      status: serializer.fromJson<String>(json['status']),
      chickBirdId: serializer.fromJson<int?>(json['chickBirdId']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'breedingRecordId': serializer.toJson<int>(breedingRecordId),
      'laidDate': serializer.toJson<DateTime>(laidDate),
      'hatchDate': serializer.toJson<DateTime?>(hatchDate),
      'status': serializer.toJson<String>(status),
      'chickBirdId': serializer.toJson<int?>(chickBirdId),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Egg copyWith(
          {int? id,
          String? uuid,
          int? breedingRecordId,
          DateTime? laidDate,
          Value<DateTime?> hatchDate = const Value.absent(),
          String? status,
          Value<int?> chickBirdId = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Egg(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        breedingRecordId: breedingRecordId ?? this.breedingRecordId,
        laidDate: laidDate ?? this.laidDate,
        hatchDate: hatchDate.present ? hatchDate.value : this.hatchDate,
        status: status ?? this.status,
        chickBirdId: chickBirdId.present ? chickBirdId.value : this.chickBirdId,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Egg copyWithCompanion(EggsCompanion data) {
    return Egg(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      breedingRecordId: data.breedingRecordId.present
          ? data.breedingRecordId.value
          : this.breedingRecordId,
      laidDate: data.laidDate.present ? data.laidDate.value : this.laidDate,
      hatchDate: data.hatchDate.present ? data.hatchDate.value : this.hatchDate,
      status: data.status.present ? data.status.value : this.status,
      chickBirdId:
          data.chickBirdId.present ? data.chickBirdId.value : this.chickBirdId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Egg(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('breedingRecordId: $breedingRecordId, ')
          ..write('laidDate: $laidDate, ')
          ..write('hatchDate: $hatchDate, ')
          ..write('status: $status, ')
          ..write('chickBirdId: $chickBirdId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, breedingRecordId, laidDate,
      hatchDate, status, chickBirdId, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Egg &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.breedingRecordId == this.breedingRecordId &&
          other.laidDate == this.laidDate &&
          other.hatchDate == this.hatchDate &&
          other.status == this.status &&
          other.chickBirdId == this.chickBirdId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EggsCompanion extends UpdateCompanion<Egg> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> breedingRecordId;
  final Value<DateTime> laidDate;
  final Value<DateTime?> hatchDate;
  final Value<String> status;
  final Value<int?> chickBirdId;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EggsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.breedingRecordId = const Value.absent(),
    this.laidDate = const Value.absent(),
    this.hatchDate = const Value.absent(),
    this.status = const Value.absent(),
    this.chickBirdId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EggsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int breedingRecordId,
    required DateTime laidDate,
    this.hatchDate = const Value.absent(),
    this.status = const Value.absent(),
    this.chickBirdId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        breedingRecordId = Value(breedingRecordId),
        laidDate = Value(laidDate);
  static Insertable<Egg> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? breedingRecordId,
    Expression<DateTime>? laidDate,
    Expression<DateTime>? hatchDate,
    Expression<String>? status,
    Expression<int>? chickBirdId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (breedingRecordId != null) 'breeding_record_id': breedingRecordId,
      if (laidDate != null) 'laid_date': laidDate,
      if (hatchDate != null) 'hatch_date': hatchDate,
      if (status != null) 'status': status,
      if (chickBirdId != null) 'chick_bird_id': chickBirdId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EggsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? breedingRecordId,
      Value<DateTime>? laidDate,
      Value<DateTime?>? hatchDate,
      Value<String>? status,
      Value<int?>? chickBirdId,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return EggsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      breedingRecordId: breedingRecordId ?? this.breedingRecordId,
      laidDate: laidDate ?? this.laidDate,
      hatchDate: hatchDate ?? this.hatchDate,
      status: status ?? this.status,
      chickBirdId: chickBirdId ?? this.chickBirdId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (breedingRecordId.present) {
      map['breeding_record_id'] = Variable<int>(breedingRecordId.value);
    }
    if (laidDate.present) {
      map['laid_date'] = Variable<DateTime>(laidDate.value);
    }
    if (hatchDate.present) {
      map['hatch_date'] = Variable<DateTime>(hatchDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (chickBirdId.present) {
      map['chick_bird_id'] = Variable<int>(chickBirdId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EggsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('breedingRecordId: $breedingRecordId, ')
          ..write('laidDate: $laidDate, ')
          ..write('hatchDate: $hatchDate, ')
          ..write('status: $status, ')
          ..write('chickBirdId: $chickBirdId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MatingEventsTable extends MatingEvents
    with TableInfo<$MatingEventsTable, MatingEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatingEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _breedingRecordIdMeta =
      const VerificationMeta('breedingRecordId');
  @override
  late final GeneratedColumn<int> breedingRecordId = GeneratedColumn<int>(
      'breeding_record_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES breeding_records (id) ON DELETE CASCADE'));
  static const VerificationMeta _observedDateMeta =
      const VerificationMeta('observedDate');
  @override
  late final GeneratedColumn<DateTime> observedDate = GeneratedColumn<DateTime>(
      'observed_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, uuid, breedingRecordId, observedDate, notes, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mating_events';
  @override
  VerificationContext validateIntegrity(Insertable<MatingEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('breeding_record_id')) {
      context.handle(
          _breedingRecordIdMeta,
          breedingRecordId.isAcceptableOrUnknown(
              data['breeding_record_id']!, _breedingRecordIdMeta));
    } else if (isInserting) {
      context.missing(_breedingRecordIdMeta);
    }
    if (data.containsKey('observed_date')) {
      context.handle(
          _observedDateMeta,
          observedDate.isAcceptableOrUnknown(
              data['observed_date']!, _observedDateMeta));
    } else if (isInserting) {
      context.missing(_observedDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MatingEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatingEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      breedingRecordId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}breeding_record_id'])!,
      observedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}observed_date'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MatingEventsTable createAlias(String alias) {
    return $MatingEventsTable(attachedDatabase, alias);
  }
}

class MatingEvent extends DataClass implements Insertable<MatingEvent> {
  final int id;
  final String uuid;

  /// 关联繁育记录
  final int breedingRecordId;
  final DateTime observedDate;
  final String? notes;
  final DateTime createdAt;
  const MatingEvent(
      {required this.id,
      required this.uuid,
      required this.breedingRecordId,
      required this.observedDate,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['breeding_record_id'] = Variable<int>(breedingRecordId);
    map['observed_date'] = Variable<DateTime>(observedDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MatingEventsCompanion toCompanion(bool nullToAbsent) {
    return MatingEventsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      breedingRecordId: Value(breedingRecordId),
      observedDate: Value(observedDate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory MatingEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatingEvent(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      breedingRecordId: serializer.fromJson<int>(json['breedingRecordId']),
      observedDate: serializer.fromJson<DateTime>(json['observedDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'breedingRecordId': serializer.toJson<int>(breedingRecordId),
      'observedDate': serializer.toJson<DateTime>(observedDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MatingEvent copyWith(
          {int? id,
          String? uuid,
          int? breedingRecordId,
          DateTime? observedDate,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      MatingEvent(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        breedingRecordId: breedingRecordId ?? this.breedingRecordId,
        observedDate: observedDate ?? this.observedDate,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  MatingEvent copyWithCompanion(MatingEventsCompanion data) {
    return MatingEvent(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      breedingRecordId: data.breedingRecordId.present
          ? data.breedingRecordId.value
          : this.breedingRecordId,
      observedDate: data.observedDate.present
          ? data.observedDate.value
          : this.observedDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatingEvent(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('breedingRecordId: $breedingRecordId, ')
          ..write('observedDate: $observedDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uuid, breedingRecordId, observedDate, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatingEvent &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.breedingRecordId == this.breedingRecordId &&
          other.observedDate == this.observedDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class MatingEventsCompanion extends UpdateCompanion<MatingEvent> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> breedingRecordId;
  final Value<DateTime> observedDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const MatingEventsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.breedingRecordId = const Value.absent(),
    this.observedDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MatingEventsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int breedingRecordId,
    required DateTime observedDate,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : uuid = Value(uuid),
        breedingRecordId = Value(breedingRecordId),
        observedDate = Value(observedDate);
  static Insertable<MatingEvent> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? breedingRecordId,
    Expression<DateTime>? observedDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (breedingRecordId != null) 'breeding_record_id': breedingRecordId,
      if (observedDate != null) 'observed_date': observedDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MatingEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? breedingRecordId,
      Value<DateTime>? observedDate,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return MatingEventsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      breedingRecordId: breedingRecordId ?? this.breedingRecordId,
      observedDate: observedDate ?? this.observedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (breedingRecordId.present) {
      map['breeding_record_id'] = Variable<int>(breedingRecordId.value);
    }
    if (observedDate.present) {
      map['observed_date'] = Variable<DateTime>(observedDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatingEventsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('breedingRecordId: $breedingRecordId, ')
          ..write('observedDate: $observedDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ActivityLogsTable extends ActivityLogs
    with TableInfo<$ActivityLogsTable, ActivityLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _birdIdMeta = const VerificationMeta('birdId');
  @override
  late final GeneratedColumn<int> birdId = GeneratedColumn<int>(
      'bird_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES birds (id) ON DELETE SET NULL'));
  static const VerificationMeta _pluginIdMeta =
      const VerificationMeta('pluginId');
  @override
  late final GeneratedColumn<String> pluginId = GeneratedColumn<String>(
      'plugin_id', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _actionTypeMeta =
      const VerificationMeta('actionType');
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
      'action_type', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _detailsMeta =
      const VerificationMeta('details');
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
      'details', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _relatedTaskIdMeta =
      const VerificationMeta('relatedTaskId');
  @override
  late final GeneratedColumn<int> relatedTaskId = GeneratedColumn<int>(
      'related_task_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tasks (id) ON DELETE SET NULL'));
  static const VerificationMeta _operatedByMeta =
      const VerificationMeta('operatedBy');
  @override
  late final GeneratedColumn<int> operatedBy = GeneratedColumn<int>(
      'operated_by', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _operatedAtMeta =
      const VerificationMeta('operatedAt');
  @override
  late final GeneratedColumn<DateTime> operatedAt = GeneratedColumn<DateTime>(
      'operated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        birdId,
        pluginId,
        actionType,
        summary,
        details,
        relatedTaskId,
        operatedBy,
        operatedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ActivityLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('bird_id')) {
      context.handle(_birdIdMeta,
          birdId.isAcceptableOrUnknown(data['bird_id']!, _birdIdMeta));
    }
    if (data.containsKey('plugin_id')) {
      context.handle(_pluginIdMeta,
          pluginId.isAcceptableOrUnknown(data['plugin_id']!, _pluginIdMeta));
    } else if (isInserting) {
      context.missing(_pluginIdMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
          _actionTypeMeta,
          actionType.isAcceptableOrUnknown(
              data['action_type']!, _actionTypeMeta));
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('details')) {
      context.handle(_detailsMeta,
          details.isAcceptableOrUnknown(data['details']!, _detailsMeta));
    }
    if (data.containsKey('related_task_id')) {
      context.handle(
          _relatedTaskIdMeta,
          relatedTaskId.isAcceptableOrUnknown(
              data['related_task_id']!, _relatedTaskIdMeta));
    }
    if (data.containsKey('operated_by')) {
      context.handle(
          _operatedByMeta,
          operatedBy.isAcceptableOrUnknown(
              data['operated_by']!, _operatedByMeta));
    }
    if (data.containsKey('operated_at')) {
      context.handle(
          _operatedAtMeta,
          operatedAt.isAcceptableOrUnknown(
              data['operated_at']!, _operatedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      birdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bird_id']),
      pluginId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plugin_id'])!,
      actionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_type'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      details: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}details']),
      relatedTaskId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}related_task_id']),
      operatedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}operated_by']),
      operatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}operated_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ActivityLogsTable createAlias(String alias) {
    return $ActivityLogsTable(attachedDatabase, alias);
  }
}

class ActivityLog extends DataClass implements Insertable<ActivityLog> {
  final int id;
  final String uuid;

  /// 关联的鹦鹉（繁育等不关联单只鸟时可 null）
  final int? birdId;

  /// 插件标识: 'weights' | 'medication' | 'breeding'
  final String pluginId;

  /// 操作类型: 'weight_recorded' | 'medication_given' | 'medication_skipped' | 'breeding_started' 等
  final String actionType;

  /// 人类可读简述，如 "称重: 45.2g", "喂药: 恩诺沙星 0.5ml"
  final String summary;

  /// JSON 格式的操作详情，如 {"drugName":"恩诺沙星","dosage":"0.5ml","weightId":42}
  final String? details;

  /// 关联的待办任务 ID（操作完成后自动标记任务为已完成）
  final int? relatedTaskId;

  /// 操作人 ID
  final int? operatedBy;

  /// 操作发生时间
  final DateTime operatedAt;
  final DateTime createdAt;
  const ActivityLog(
      {required this.id,
      required this.uuid,
      this.birdId,
      required this.pluginId,
      required this.actionType,
      required this.summary,
      this.details,
      this.relatedTaskId,
      this.operatedBy,
      required this.operatedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || birdId != null) {
      map['bird_id'] = Variable<int>(birdId);
    }
    map['plugin_id'] = Variable<String>(pluginId);
    map['action_type'] = Variable<String>(actionType);
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    if (!nullToAbsent || relatedTaskId != null) {
      map['related_task_id'] = Variable<int>(relatedTaskId);
    }
    if (!nullToAbsent || operatedBy != null) {
      map['operated_by'] = Variable<int>(operatedBy);
    }
    map['operated_at'] = Variable<DateTime>(operatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ActivityLogsCompanion toCompanion(bool nullToAbsent) {
    return ActivityLogsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      birdId:
          birdId == null && nullToAbsent ? const Value.absent() : Value(birdId),
      pluginId: Value(pluginId),
      actionType: Value(actionType),
      summary: Value(summary),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      relatedTaskId: relatedTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedTaskId),
      operatedBy: operatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(operatedBy),
      operatedAt: Value(operatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityLog(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      birdId: serializer.fromJson<int?>(json['birdId']),
      pluginId: serializer.fromJson<String>(json['pluginId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      summary: serializer.fromJson<String>(json['summary']),
      details: serializer.fromJson<String?>(json['details']),
      relatedTaskId: serializer.fromJson<int?>(json['relatedTaskId']),
      operatedBy: serializer.fromJson<int?>(json['operatedBy']),
      operatedAt: serializer.fromJson<DateTime>(json['operatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'birdId': serializer.toJson<int?>(birdId),
      'pluginId': serializer.toJson<String>(pluginId),
      'actionType': serializer.toJson<String>(actionType),
      'summary': serializer.toJson<String>(summary),
      'details': serializer.toJson<String?>(details),
      'relatedTaskId': serializer.toJson<int?>(relatedTaskId),
      'operatedBy': serializer.toJson<int?>(operatedBy),
      'operatedAt': serializer.toJson<DateTime>(operatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ActivityLog copyWith(
          {int? id,
          String? uuid,
          Value<int?> birdId = const Value.absent(),
          String? pluginId,
          String? actionType,
          String? summary,
          Value<String?> details = const Value.absent(),
          Value<int?> relatedTaskId = const Value.absent(),
          Value<int?> operatedBy = const Value.absent(),
          DateTime? operatedAt,
          DateTime? createdAt}) =>
      ActivityLog(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        birdId: birdId.present ? birdId.value : this.birdId,
        pluginId: pluginId ?? this.pluginId,
        actionType: actionType ?? this.actionType,
        summary: summary ?? this.summary,
        details: details.present ? details.value : this.details,
        relatedTaskId:
            relatedTaskId.present ? relatedTaskId.value : this.relatedTaskId,
        operatedBy: operatedBy.present ? operatedBy.value : this.operatedBy,
        operatedAt: operatedAt ?? this.operatedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  ActivityLog copyWithCompanion(ActivityLogsCompanion data) {
    return ActivityLog(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      birdId: data.birdId.present ? data.birdId.value : this.birdId,
      pluginId: data.pluginId.present ? data.pluginId.value : this.pluginId,
      actionType:
          data.actionType.present ? data.actionType.value : this.actionType,
      summary: data.summary.present ? data.summary.value : this.summary,
      details: data.details.present ? data.details.value : this.details,
      relatedTaskId: data.relatedTaskId.present
          ? data.relatedTaskId.value
          : this.relatedTaskId,
      operatedBy:
          data.operatedBy.present ? data.operatedBy.value : this.operatedBy,
      operatedAt:
          data.operatedAt.present ? data.operatedAt.value : this.operatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityLog(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('pluginId: $pluginId, ')
          ..write('actionType: $actionType, ')
          ..write('summary: $summary, ')
          ..write('details: $details, ')
          ..write('relatedTaskId: $relatedTaskId, ')
          ..write('operatedBy: $operatedBy, ')
          ..write('operatedAt: $operatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, birdId, pluginId, actionType,
      summary, details, relatedTaskId, operatedBy, operatedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityLog &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.birdId == this.birdId &&
          other.pluginId == this.pluginId &&
          other.actionType == this.actionType &&
          other.summary == this.summary &&
          other.details == this.details &&
          other.relatedTaskId == this.relatedTaskId &&
          other.operatedBy == this.operatedBy &&
          other.operatedAt == this.operatedAt &&
          other.createdAt == this.createdAt);
}

class ActivityLogsCompanion extends UpdateCompanion<ActivityLog> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int?> birdId;
  final Value<String> pluginId;
  final Value<String> actionType;
  final Value<String> summary;
  final Value<String?> details;
  final Value<int?> relatedTaskId;
  final Value<int?> operatedBy;
  final Value<DateTime> operatedAt;
  final Value<DateTime> createdAt;
  const ActivityLogsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.birdId = const Value.absent(),
    this.pluginId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.summary = const Value.absent(),
    this.details = const Value.absent(),
    this.relatedTaskId = const Value.absent(),
    this.operatedBy = const Value.absent(),
    this.operatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ActivityLogsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    this.birdId = const Value.absent(),
    required String pluginId,
    required String actionType,
    required String summary,
    this.details = const Value.absent(),
    this.relatedTaskId = const Value.absent(),
    this.operatedBy = const Value.absent(),
    this.operatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : uuid = Value(uuid),
        pluginId = Value(pluginId),
        actionType = Value(actionType),
        summary = Value(summary);
  static Insertable<ActivityLog> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? birdId,
    Expression<String>? pluginId,
    Expression<String>? actionType,
    Expression<String>? summary,
    Expression<String>? details,
    Expression<int>? relatedTaskId,
    Expression<int>? operatedBy,
    Expression<DateTime>? operatedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (birdId != null) 'bird_id': birdId,
      if (pluginId != null) 'plugin_id': pluginId,
      if (actionType != null) 'action_type': actionType,
      if (summary != null) 'summary': summary,
      if (details != null) 'details': details,
      if (relatedTaskId != null) 'related_task_id': relatedTaskId,
      if (operatedBy != null) 'operated_by': operatedBy,
      if (operatedAt != null) 'operated_at': operatedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ActivityLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int?>? birdId,
      Value<String>? pluginId,
      Value<String>? actionType,
      Value<String>? summary,
      Value<String?>? details,
      Value<int?>? relatedTaskId,
      Value<int?>? operatedBy,
      Value<DateTime>? operatedAt,
      Value<DateTime>? createdAt}) {
    return ActivityLogsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      birdId: birdId ?? this.birdId,
      pluginId: pluginId ?? this.pluginId,
      actionType: actionType ?? this.actionType,
      summary: summary ?? this.summary,
      details: details ?? this.details,
      relatedTaskId: relatedTaskId ?? this.relatedTaskId,
      operatedBy: operatedBy ?? this.operatedBy,
      operatedAt: operatedAt ?? this.operatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (birdId.present) {
      map['bird_id'] = Variable<int>(birdId.value);
    }
    if (pluginId.present) {
      map['plugin_id'] = Variable<String>(pluginId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (relatedTaskId.present) {
      map['related_task_id'] = Variable<int>(relatedTaskId.value);
    }
    if (operatedBy.present) {
      map['operated_by'] = Variable<int>(operatedBy.value);
    }
    if (operatedAt.present) {
      map['operated_at'] = Variable<DateTime>(operatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityLogsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('birdId: $birdId, ')
          ..write('pluginId: $pluginId, ')
          ..write('actionType: $actionType, ')
          ..write('summary: $summary, ')
          ..write('details: $details, ')
          ..write('relatedTaskId: $relatedTaskId, ')
          ..write('operatedBy: $operatedBy, ')
          ..write('operatedAt: $operatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BirdPhotosTable extends BirdPhotos
    with TableInfo<$BirdPhotosTable, BirdPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BirdPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _birdIdMeta = const VerificationMeta('birdId');
  @override
  late final GeneratedColumn<int> birdId = GeneratedColumn<int>(
      'bird_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES birds (id) ON DELETE CASCADE'));
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('photo'));
  static const VerificationMeta _videoFilePathMeta =
      const VerificationMeta('videoFilePath');
  @override
  late final GeneratedColumn<String> videoFilePath = GeneratedColumn<String>(
      'video_file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        birdId,
        filePath,
        sortOrder,
        mediaType,
        videoFilePath,
        thumbnailPath,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bird_photos';
  @override
  VerificationContext validateIntegrity(Insertable<BirdPhoto> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bird_id')) {
      context.handle(_birdIdMeta,
          birdId.isAcceptableOrUnknown(data['bird_id']!, _birdIdMeta));
    } else if (isInserting) {
      context.missing(_birdIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    }
    if (data.containsKey('video_file_path')) {
      context.handle(
          _videoFilePathMeta,
          videoFilePath.isAcceptableOrUnknown(
              data['video_file_path']!, _videoFilePathMeta));
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BirdPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BirdPhoto(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      birdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bird_id'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      videoFilePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_file_path']),
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BirdPhotosTable createAlias(String alias) {
    return $BirdPhotosTable(attachedDatabase, alias);
  }
}

class BirdPhoto extends DataClass implements Insertable<BirdPhoto> {
  final int id;
  final int birdId;
  final String filePath;
  final int sortOrder;
  final String mediaType;
  final String? videoFilePath;
  final String? thumbnailPath;
  final DateTime createdAt;
  const BirdPhoto(
      {required this.id,
      required this.birdId,
      required this.filePath,
      required this.sortOrder,
      required this.mediaType,
      this.videoFilePath,
      this.thumbnailPath,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bird_id'] = Variable<int>(birdId);
    map['file_path'] = Variable<String>(filePath);
    map['sort_order'] = Variable<int>(sortOrder);
    map['media_type'] = Variable<String>(mediaType);
    if (!nullToAbsent || videoFilePath != null) {
      map['video_file_path'] = Variable<String>(videoFilePath);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BirdPhotosCompanion toCompanion(bool nullToAbsent) {
    return BirdPhotosCompanion(
      id: Value(id),
      birdId: Value(birdId),
      filePath: Value(filePath),
      sortOrder: Value(sortOrder),
      mediaType: Value(mediaType),
      videoFilePath: videoFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(videoFilePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      createdAt: Value(createdAt),
    );
  }

  factory BirdPhoto.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BirdPhoto(
      id: serializer.fromJson<int>(json['id']),
      birdId: serializer.fromJson<int>(json['birdId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      videoFilePath: serializer.fromJson<String?>(json['videoFilePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'birdId': serializer.toJson<int>(birdId),
      'filePath': serializer.toJson<String>(filePath),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'mediaType': serializer.toJson<String>(mediaType),
      'videoFilePath': serializer.toJson<String?>(videoFilePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BirdPhoto copyWith(
          {int? id,
          int? birdId,
          String? filePath,
          int? sortOrder,
          String? mediaType,
          Value<String?> videoFilePath = const Value.absent(),
          Value<String?> thumbnailPath = const Value.absent(),
          DateTime? createdAt}) =>
      BirdPhoto(
        id: id ?? this.id,
        birdId: birdId ?? this.birdId,
        filePath: filePath ?? this.filePath,
        sortOrder: sortOrder ?? this.sortOrder,
        mediaType: mediaType ?? this.mediaType,
        videoFilePath:
            videoFilePath.present ? videoFilePath.value : this.videoFilePath,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        createdAt: createdAt ?? this.createdAt,
      );
  BirdPhoto copyWithCompanion(BirdPhotosCompanion data) {
    return BirdPhoto(
      id: data.id.present ? data.id.value : this.id,
      birdId: data.birdId.present ? data.birdId.value : this.birdId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      videoFilePath: data.videoFilePath.present
          ? data.videoFilePath.value
          : this.videoFilePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BirdPhoto(')
          ..write('id: $id, ')
          ..write('birdId: $birdId, ')
          ..write('filePath: $filePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('mediaType: $mediaType, ')
          ..write('videoFilePath: $videoFilePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, birdId, filePath, sortOrder, mediaType,
      videoFilePath, thumbnailPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BirdPhoto &&
          other.id == this.id &&
          other.birdId == this.birdId &&
          other.filePath == this.filePath &&
          other.sortOrder == this.sortOrder &&
          other.mediaType == this.mediaType &&
          other.videoFilePath == this.videoFilePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.createdAt == this.createdAt);
}

class BirdPhotosCompanion extends UpdateCompanion<BirdPhoto> {
  final Value<int> id;
  final Value<int> birdId;
  final Value<String> filePath;
  final Value<int> sortOrder;
  final Value<String> mediaType;
  final Value<String?> videoFilePath;
  final Value<String?> thumbnailPath;
  final Value<DateTime> createdAt;
  const BirdPhotosCompanion({
    this.id = const Value.absent(),
    this.birdId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.videoFilePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BirdPhotosCompanion.insert({
    this.id = const Value.absent(),
    required int birdId,
    required String filePath,
    this.sortOrder = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.videoFilePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : birdId = Value(birdId),
        filePath = Value(filePath);
  static Insertable<BirdPhoto> custom({
    Expression<int>? id,
    Expression<int>? birdId,
    Expression<String>? filePath,
    Expression<int>? sortOrder,
    Expression<String>? mediaType,
    Expression<String>? videoFilePath,
    Expression<String>? thumbnailPath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (birdId != null) 'bird_id': birdId,
      if (filePath != null) 'file_path': filePath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (mediaType != null) 'media_type': mediaType,
      if (videoFilePath != null) 'video_file_path': videoFilePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BirdPhotosCompanion copyWith(
      {Value<int>? id,
      Value<int>? birdId,
      Value<String>? filePath,
      Value<int>? sortOrder,
      Value<String>? mediaType,
      Value<String?>? videoFilePath,
      Value<String?>? thumbnailPath,
      Value<DateTime>? createdAt}) {
    return BirdPhotosCompanion(
      id: id ?? this.id,
      birdId: birdId ?? this.birdId,
      filePath: filePath ?? this.filePath,
      sortOrder: sortOrder ?? this.sortOrder,
      mediaType: mediaType ?? this.mediaType,
      videoFilePath: videoFilePath ?? this.videoFilePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (birdId.present) {
      map['bird_id'] = Variable<int>(birdId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (videoFilePath.present) {
      map['video_file_path'] = Variable<String>(videoFilePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BirdPhotosCompanion(')
          ..write('id: $id, ')
          ..write('birdId: $birdId, ')
          ..write('filePath: $filePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('mediaType: $mediaType, ')
          ..write('videoFilePath: $videoFilePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BirdAvatarsTable extends BirdAvatars
    with TableInfo<$BirdAvatarsTable, BirdAvatar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BirdAvatarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _birdIdMeta = const VerificationMeta('birdId');
  @override
  late final GeneratedColumn<int> birdId = GeneratedColumn<int>(
      'bird_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'UNIQUE REFERENCES birds (id) ON DELETE CASCADE'));
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, birdId, filePath, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bird_avatars';
  @override
  VerificationContext validateIntegrity(Insertable<BirdAvatar> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bird_id')) {
      context.handle(_birdIdMeta,
          birdId.isAcceptableOrUnknown(data['bird_id']!, _birdIdMeta));
    } else if (isInserting) {
      context.missing(_birdIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BirdAvatar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BirdAvatar(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      birdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bird_id'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BirdAvatarsTable createAlias(String alias) {
    return $BirdAvatarsTable(attachedDatabase, alias);
  }
}

class BirdAvatar extends DataClass implements Insertable<BirdAvatar> {
  final int id;
  final int birdId;
  final String filePath;
  final DateTime updatedAt;
  const BirdAvatar(
      {required this.id,
      required this.birdId,
      required this.filePath,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bird_id'] = Variable<int>(birdId);
    map['file_path'] = Variable<String>(filePath);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BirdAvatarsCompanion toCompanion(bool nullToAbsent) {
    return BirdAvatarsCompanion(
      id: Value(id),
      birdId: Value(birdId),
      filePath: Value(filePath),
      updatedAt: Value(updatedAt),
    );
  }

  factory BirdAvatar.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BirdAvatar(
      id: serializer.fromJson<int>(json['id']),
      birdId: serializer.fromJson<int>(json['birdId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'birdId': serializer.toJson<int>(birdId),
      'filePath': serializer.toJson<String>(filePath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BirdAvatar copyWith(
          {int? id, int? birdId, String? filePath, DateTime? updatedAt}) =>
      BirdAvatar(
        id: id ?? this.id,
        birdId: birdId ?? this.birdId,
        filePath: filePath ?? this.filePath,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BirdAvatar copyWithCompanion(BirdAvatarsCompanion data) {
    return BirdAvatar(
      id: data.id.present ? data.id.value : this.id,
      birdId: data.birdId.present ? data.birdId.value : this.birdId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BirdAvatar(')
          ..write('id: $id, ')
          ..write('birdId: $birdId, ')
          ..write('filePath: $filePath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, birdId, filePath, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BirdAvatar &&
          other.id == this.id &&
          other.birdId == this.birdId &&
          other.filePath == this.filePath &&
          other.updatedAt == this.updatedAt);
}

class BirdAvatarsCompanion extends UpdateCompanion<BirdAvatar> {
  final Value<int> id;
  final Value<int> birdId;
  final Value<String> filePath;
  final Value<DateTime> updatedAt;
  const BirdAvatarsCompanion({
    this.id = const Value.absent(),
    this.birdId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BirdAvatarsCompanion.insert({
    this.id = const Value.absent(),
    required int birdId,
    required String filePath,
    this.updatedAt = const Value.absent(),
  })  : birdId = Value(birdId),
        filePath = Value(filePath);
  static Insertable<BirdAvatar> custom({
    Expression<int>? id,
    Expression<int>? birdId,
    Expression<String>? filePath,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (birdId != null) 'bird_id': birdId,
      if (filePath != null) 'file_path': filePath,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BirdAvatarsCompanion copyWith(
      {Value<int>? id,
      Value<int>? birdId,
      Value<String>? filePath,
      Value<DateTime>? updatedAt}) {
    return BirdAvatarsCompanion(
      id: id ?? this.id,
      birdId: birdId ?? this.birdId,
      filePath: filePath ?? this.filePath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (birdId.present) {
      map['bird_id'] = Variable<int>(birdId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BirdAvatarsCompanion(')
          ..write('id: $id, ')
          ..write('birdId: $birdId, ')
          ..write('filePath: $filePath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SpeciesTable species = $SpeciesTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $RoomsTable rooms = $RoomsTable(this);
  late final $EnclosuresTable enclosures = $EnclosuresTable(this);
  late final $BirdsTable birds = $BirdsTable(this);
  late final $WeightsTable weights = $WeightsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $AlertRecordsTable alertRecords = $AlertRecordsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $BreedingPairsTable breedingPairs = $BreedingPairsTable(this);
  late final $BreedingRecordsTable breedingRecords =
      $BreedingRecordsTable(this);
  late final $EggsTable eggs = $EggsTable(this);
  late final $MatingEventsTable matingEvents = $MatingEventsTable(this);
  late final $ActivityLogsTable activityLogs = $ActivityLogsTable(this);
  late final $BirdPhotosTable birdPhotos = $BirdPhotosTable(this);
  late final $BirdAvatarsTable birdAvatars = $BirdAvatarsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        species,
        users,
        rooms,
        enclosures,
        birds,
        weights,
        tasks,
        alertRecords,
        syncQueue,
        medications,
        breedingPairs,
        breedingRecords,
        eggs,
        matingEvents,
        activityLogs,
        birdPhotos,
        birdAvatars
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('rooms',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('enclosures', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('enclosures',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('birds', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('weights', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('tasks', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('alert_records', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('medications', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('breeding_pairs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('breeding_pairs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('breeding_pairs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('breeding_records', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('breeding_records',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('eggs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('eggs', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('breeding_records',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('mating_events', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('activity_logs', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('tasks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('activity_logs', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('bird_photos', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('birds',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('bird_avatars', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$SpeciesTableCreateCompanionBuilder = SpeciesCompanion Function({
  Value<int> id,
  required String uuid,
  required String name,
  Value<int> nestlingEndDays,
  Value<int> juvenileEndDays,
  Value<int> nestlingWeighIntervalDays,
  Value<int> juvenileWeighIntervalDays,
  Value<int> adultWeighIntervalDays,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$SpeciesTableUpdateCompanionBuilder = SpeciesCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<int> nestlingEndDays,
  Value<int> juvenileEndDays,
  Value<int> nestlingWeighIntervalDays,
  Value<int> juvenileWeighIntervalDays,
  Value<int> adultWeighIntervalDays,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

final class $$SpeciesTableReferences
    extends BaseReferences<_$AppDatabase, $SpeciesTable, Specy> {
  $$SpeciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BirdsTable, List<Bird>> _birdsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.birds,
          aliasName: $_aliasNameGenerator(db.species.id, db.birds.speciesId));

  $$BirdsTableProcessedTableManager get birdsRefs {
    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.speciesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_birdsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SpeciesTableFilterComposer
    extends Composer<_$AppDatabase, $SpeciesTable> {
  $$SpeciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nestlingEndDays => $composableBuilder(
      column: $table.nestlingEndDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get juvenileEndDays => $composableBuilder(
      column: $table.juvenileEndDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nestlingWeighIntervalDays => $composableBuilder(
      column: $table.nestlingWeighIntervalDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get juvenileWeighIntervalDays => $composableBuilder(
      column: $table.juvenileWeighIntervalDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get adultWeighIntervalDays => $composableBuilder(
      column: $table.adultWeighIntervalDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> birdsRefs(
      Expression<bool> Function($$BirdsTableFilterComposer f) f) {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.speciesId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SpeciesTableOrderingComposer
    extends Composer<_$AppDatabase, $SpeciesTable> {
  $$SpeciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nestlingEndDays => $composableBuilder(
      column: $table.nestlingEndDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get juvenileEndDays => $composableBuilder(
      column: $table.juvenileEndDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nestlingWeighIntervalDays => $composableBuilder(
      column: $table.nestlingWeighIntervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get juvenileWeighIntervalDays => $composableBuilder(
      column: $table.juvenileWeighIntervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get adultWeighIntervalDays => $composableBuilder(
      column: $table.adultWeighIntervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$SpeciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpeciesTable> {
  $$SpeciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get nestlingEndDays => $composableBuilder(
      column: $table.nestlingEndDays, builder: (column) => column);

  GeneratedColumn<int> get juvenileEndDays => $composableBuilder(
      column: $table.juvenileEndDays, builder: (column) => column);

  GeneratedColumn<int> get nestlingWeighIntervalDays => $composableBuilder(
      column: $table.nestlingWeighIntervalDays, builder: (column) => column);

  GeneratedColumn<int> get juvenileWeighIntervalDays => $composableBuilder(
      column: $table.juvenileWeighIntervalDays, builder: (column) => column);

  GeneratedColumn<int> get adultWeighIntervalDays => $composableBuilder(
      column: $table.adultWeighIntervalDays, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> birdsRefs<T extends Object>(
      Expression<T> Function($$BirdsTableAnnotationComposer a) f) {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.speciesId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SpeciesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SpeciesTable,
    Specy,
    $$SpeciesTableFilterComposer,
    $$SpeciesTableOrderingComposer,
    $$SpeciesTableAnnotationComposer,
    $$SpeciesTableCreateCompanionBuilder,
    $$SpeciesTableUpdateCompanionBuilder,
    (Specy, $$SpeciesTableReferences),
    Specy,
    PrefetchHooks Function({bool birdsRefs})> {
  $$SpeciesTableTableManager(_$AppDatabase db, $SpeciesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpeciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpeciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpeciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> nestlingEndDays = const Value.absent(),
            Value<int> juvenileEndDays = const Value.absent(),
            Value<int> nestlingWeighIntervalDays = const Value.absent(),
            Value<int> juvenileWeighIntervalDays = const Value.absent(),
            Value<int> adultWeighIntervalDays = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              SpeciesCompanion(
            id: id,
            uuid: uuid,
            name: name,
            nestlingEndDays: nestlingEndDays,
            juvenileEndDays: juvenileEndDays,
            nestlingWeighIntervalDays: nestlingWeighIntervalDays,
            juvenileWeighIntervalDays: juvenileWeighIntervalDays,
            adultWeighIntervalDays: adultWeighIntervalDays,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String name,
            Value<int> nestlingEndDays = const Value.absent(),
            Value<int> juvenileEndDays = const Value.absent(),
            Value<int> nestlingWeighIntervalDays = const Value.absent(),
            Value<int> juvenileWeighIntervalDays = const Value.absent(),
            Value<int> adultWeighIntervalDays = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              SpeciesCompanion.insert(
            id: id,
            uuid: uuid,
            name: name,
            nestlingEndDays: nestlingEndDays,
            juvenileEndDays: juvenileEndDays,
            nestlingWeighIntervalDays: nestlingWeighIntervalDays,
            juvenileWeighIntervalDays: juvenileWeighIntervalDays,
            adultWeighIntervalDays: adultWeighIntervalDays,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SpeciesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({birdsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (birdsRefs) db.birds],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (birdsRefs)
                    await $_getPrefetchedData<Specy, $SpeciesTable, Bird>(
                        currentTable: table,
                        referencedTable:
                            $$SpeciesTableReferences._birdsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SpeciesTableReferences(db, table, p0).birdsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.speciesId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SpeciesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SpeciesTable,
    Specy,
    $$SpeciesTableFilterComposer,
    $$SpeciesTableOrderingComposer,
    $$SpeciesTableAnnotationComposer,
    $$SpeciesTableCreateCompanionBuilder,
    $$SpeciesTableUpdateCompanionBuilder,
    (Specy, $$SpeciesTableReferences),
    Specy,
    PrefetchHooks Function({bool birdsRefs})>;
typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String uuid,
  required String username,
  required String displayName,
  required String passwordHash,
  Value<String> role,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> username,
  Value<String> displayName,
  Value<String> passwordHash,
  Value<String> role,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WeightsTable, List<Weight>> _weightsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.weights,
          aliasName: $_aliasNameGenerator(db.users.id, db.weights.recordedBy));

  $$WeightsTableProcessedTableManager get weightsRefs {
    final manager = $$WeightsTableTableManager($_db, $_db.weights)
        .filter((f) => f.recordedBy.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_weightsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SyncQueueTable, List<SyncQueueData>>
      _syncQueueRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.syncQueue,
          aliasName: $_aliasNameGenerator(db.users.id, db.syncQueue.userId));

  $$SyncQueueTableProcessedTableManager get syncQueueRefs {
    final manager = $$SyncQueueTableTableManager($_db, $_db.syncQueue)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncQueueRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ActivityLogsTable, List<ActivityLog>>
      _activityLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.activityLogs,
          aliasName:
              $_aliasNameGenerator(db.users.id, db.activityLogs.operatedBy));

  $$ActivityLogsTableProcessedTableManager get activityLogsRefs {
    final manager = $$ActivityLogsTableTableManager($_db, $_db.activityLogs)
        .filter((f) => f.operatedBy.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_activityLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> weightsRefs(
      Expression<bool> Function($$WeightsTableFilterComposer f) f) {
    final $$WeightsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.weights,
        getReferencedColumn: (t) => t.recordedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WeightsTableFilterComposer(
              $db: $db,
              $table: $db.weights,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> syncQueueRefs(
      Expression<bool> Function($$SyncQueueTableFilterComposer f) f) {
    final $$SyncQueueTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.syncQueue,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SyncQueueTableFilterComposer(
              $db: $db,
              $table: $db.syncQueue,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> activityLogsRefs(
      Expression<bool> Function($$ActivityLogsTableFilterComposer f) f) {
    final $$ActivityLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.activityLogs,
        getReferencedColumn: (t) => t.operatedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActivityLogsTableFilterComposer(
              $db: $db,
              $table: $db.activityLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> weightsRefs<T extends Object>(
      Expression<T> Function($$WeightsTableAnnotationComposer a) f) {
    final $$WeightsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.weights,
        getReferencedColumn: (t) => t.recordedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WeightsTableAnnotationComposer(
              $db: $db,
              $table: $db.weights,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> syncQueueRefs<T extends Object>(
      Expression<T> Function($$SyncQueueTableAnnotationComposer a) f) {
    final $$SyncQueueTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.syncQueue,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SyncQueueTableAnnotationComposer(
              $db: $db,
              $table: $db.syncQueue,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> activityLogsRefs<T extends Object>(
      Expression<T> Function($$ActivityLogsTableAnnotationComposer a) f) {
    final $$ActivityLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.activityLogs,
        getReferencedColumn: (t) => t.operatedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActivityLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.activityLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool weightsRefs, bool syncQueueRefs, bool activityLogsRefs})> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            uuid: uuid,
            username: username,
            displayName: displayName,
            passwordHash: passwordHash,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String username,
            required String displayName,
            required String passwordHash,
            Value<String> role = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            uuid: uuid,
            username: username,
            displayName: displayName,
            passwordHash: passwordHash,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UsersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {weightsRefs = false,
              syncQueueRefs = false,
              activityLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (weightsRefs) db.weights,
                if (syncQueueRefs) db.syncQueue,
                if (activityLogsRefs) db.activityLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (weightsRefs)
                    await $_getPrefetchedData<User, $UsersTable, Weight>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._weightsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).weightsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.recordedBy == item.id),
                        typedResults: items),
                  if (syncQueueRefs)
                    await $_getPrefetchedData<User, $UsersTable, SyncQueueData>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._syncQueueRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).syncQueueRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (activityLogsRefs)
                    await $_getPrefetchedData<User, $UsersTable, ActivityLog>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._activityLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .activityLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.operatedBy == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool weightsRefs, bool syncQueueRefs, bool activityLogsRefs})>;
typedef $$RoomsTableCreateCompanionBuilder = RoomsCompanion Function({
  Value<int> id,
  required String uuid,
  required String name,
  Value<int> sortOrder,
  Value<int?> assignedUserId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$RoomsTableUpdateCompanionBuilder = RoomsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<int> sortOrder,
  Value<int?> assignedUserId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

final class $$RoomsTableReferences
    extends BaseReferences<_$AppDatabase, $RoomsTable, Room> {
  $$RoomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EnclosuresTable, List<Enclosure>>
      _enclosuresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.enclosures,
          aliasName: $_aliasNameGenerator(db.rooms.id, db.enclosures.roomId));

  $$EnclosuresTableProcessedTableManager get enclosuresRefs {
    final manager = $$EnclosuresTableTableManager($_db, $_db.enclosures)
        .filter((f) => f.roomId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_enclosuresRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BirdsTable, List<Bird>> _birdsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.birds,
          aliasName: $_aliasNameGenerator(db.rooms.id, db.birds.roomId));

  $$BirdsTableProcessedTableManager get birdsRefs {
    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.roomId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_birdsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.tasks,
          aliasName: $_aliasNameGenerator(db.rooms.id, db.tasks.roomId));

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.roomId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RoomsTableFilterComposer extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> enclosuresRefs(
      Expression<bool> Function($$EnclosuresTableFilterComposer f) f) {
    final $$EnclosuresTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.enclosures,
        getReferencedColumn: (t) => t.roomId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnclosuresTableFilterComposer(
              $db: $db,
              $table: $db.enclosures,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> birdsRefs(
      Expression<bool> Function($$BirdsTableFilterComposer f) f) {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.roomId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> tasksRefs(
      Expression<bool> Function($$TasksTableFilterComposer f) f) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.roomId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableFilterComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$RoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> enclosuresRefs<T extends Object>(
      Expression<T> Function($$EnclosuresTableAnnotationComposer a) f) {
    final $$EnclosuresTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.enclosures,
        getReferencedColumn: (t) => t.roomId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnclosuresTableAnnotationComposer(
              $db: $db,
              $table: $db.enclosures,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> birdsRefs<T extends Object>(
      Expression<T> Function($$BirdsTableAnnotationComposer a) f) {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.roomId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
      Expression<T> Function($$TasksTableAnnotationComposer a) f) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.roomId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableAnnotationComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoomsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoomsTable,
    Room,
    $$RoomsTableFilterComposer,
    $$RoomsTableOrderingComposer,
    $$RoomsTableAnnotationComposer,
    $$RoomsTableCreateCompanionBuilder,
    $$RoomsTableUpdateCompanionBuilder,
    (Room, $$RoomsTableReferences),
    Room,
    PrefetchHooks Function(
        {bool enclosuresRefs, bool birdsRefs, bool tasksRefs})> {
  $$RoomsTableTableManager(_$AppDatabase db, $RoomsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> assignedUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              RoomsCompanion(
            id: id,
            uuid: uuid,
            name: name,
            sortOrder: sortOrder,
            assignedUserId: assignedUserId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String name,
            Value<int> sortOrder = const Value.absent(),
            Value<int?> assignedUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              RoomsCompanion.insert(
            id: id,
            uuid: uuid,
            name: name,
            sortOrder: sortOrder,
            assignedUserId: assignedUserId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RoomsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {enclosuresRefs = false, birdsRefs = false, tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (enclosuresRefs) db.enclosures,
                if (birdsRefs) db.birds,
                if (tasksRefs) db.tasks
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (enclosuresRefs)
                    await $_getPrefetchedData<Room, $RoomsTable, Enclosure>(
                        currentTable: table,
                        referencedTable:
                            $$RoomsTableReferences._enclosuresRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoomsTableReferences(db, table, p0)
                                .enclosuresRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.roomId == item.id),
                        typedResults: items),
                  if (birdsRefs)
                    await $_getPrefetchedData<Room, $RoomsTable, Bird>(
                        currentTable: table,
                        referencedTable:
                            $$RoomsTableReferences._birdsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoomsTableReferences(db, table, p0).birdsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.roomId == item.id),
                        typedResults: items),
                  if (tasksRefs)
                    await $_getPrefetchedData<Room, $RoomsTable, Task>(
                        currentTable: table,
                        referencedTable:
                            $$RoomsTableReferences._tasksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoomsTableReferences(db, table, p0).tasksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.roomId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RoomsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoomsTable,
    Room,
    $$RoomsTableFilterComposer,
    $$RoomsTableOrderingComposer,
    $$RoomsTableAnnotationComposer,
    $$RoomsTableCreateCompanionBuilder,
    $$RoomsTableUpdateCompanionBuilder,
    (Room, $$RoomsTableReferences),
    Room,
    PrefetchHooks Function(
        {bool enclosuresRefs, bool birdsRefs, bool tasksRefs})>;
typedef $$EnclosuresTableCreateCompanionBuilder = EnclosuresCompanion Function({
  Value<int> id,
  required String uuid,
  required String name,
  required int roomId,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$EnclosuresTableUpdateCompanionBuilder = EnclosuresCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<int> roomId,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

final class $$EnclosuresTableReferences
    extends BaseReferences<_$AppDatabase, $EnclosuresTable, Enclosure> {
  $$EnclosuresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoomsTable _roomIdTable(_$AppDatabase db) => db.rooms
      .createAlias($_aliasNameGenerator(db.enclosures.roomId, db.rooms.id));

  $$RoomsTableProcessedTableManager get roomId {
    final $_column = $_itemColumn<int>('room_id')!;

    final manager = $$RoomsTableTableManager($_db, $_db.rooms)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$BirdsTable, List<Bird>> _birdsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.birds,
          aliasName:
              $_aliasNameGenerator(db.enclosures.id, db.birds.enclosureId));

  $$BirdsTableProcessedTableManager get birdsRefs {
    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.enclosureId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_birdsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EnclosuresTableFilterComposer
    extends Composer<_$AppDatabase, $EnclosuresTable> {
  $$EnclosuresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roomId,
        referencedTable: $db.rooms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoomsTableFilterComposer(
              $db: $db,
              $table: $db.rooms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> birdsRefs(
      Expression<bool> Function($$BirdsTableFilterComposer f) f) {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.enclosureId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EnclosuresTableOrderingComposer
    extends Composer<_$AppDatabase, $EnclosuresTable> {
  $$EnclosuresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roomId,
        referencedTable: $db.rooms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoomsTableOrderingComposer(
              $db: $db,
              $table: $db.rooms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EnclosuresTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnclosuresTable> {
  $$EnclosuresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roomId,
        referencedTable: $db.rooms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoomsTableAnnotationComposer(
              $db: $db,
              $table: $db.rooms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> birdsRefs<T extends Object>(
      Expression<T> Function($$BirdsTableAnnotationComposer a) f) {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.enclosureId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EnclosuresTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EnclosuresTable,
    Enclosure,
    $$EnclosuresTableFilterComposer,
    $$EnclosuresTableOrderingComposer,
    $$EnclosuresTableAnnotationComposer,
    $$EnclosuresTableCreateCompanionBuilder,
    $$EnclosuresTableUpdateCompanionBuilder,
    (Enclosure, $$EnclosuresTableReferences),
    Enclosure,
    PrefetchHooks Function({bool roomId, bool birdsRefs})> {
  $$EnclosuresTableTableManager(_$AppDatabase db, $EnclosuresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnclosuresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnclosuresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnclosuresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> roomId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              EnclosuresCompanion(
            id: id,
            uuid: uuid,
            name: name,
            roomId: roomId,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String name,
            required int roomId,
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              EnclosuresCompanion.insert(
            id: id,
            uuid: uuid,
            name: name,
            roomId: roomId,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EnclosuresTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({roomId = false, birdsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (birdsRefs) db.birds],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (roomId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.roomId,
                    referencedTable:
                        $$EnclosuresTableReferences._roomIdTable(db),
                    referencedColumn:
                        $$EnclosuresTableReferences._roomIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (birdsRefs)
                    await $_getPrefetchedData<Enclosure, $EnclosuresTable,
                            Bird>(
                        currentTable: table,
                        referencedTable:
                            $$EnclosuresTableReferences._birdsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EnclosuresTableReferences(db, table, p0)
                                .birdsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.enclosureId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EnclosuresTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EnclosuresTable,
    Enclosure,
    $$EnclosuresTableFilterComposer,
    $$EnclosuresTableOrderingComposer,
    $$EnclosuresTableAnnotationComposer,
    $$EnclosuresTableCreateCompanionBuilder,
    $$EnclosuresTableUpdateCompanionBuilder,
    (Enclosure, $$EnclosuresTableReferences),
    Enclosure,
    PrefetchHooks Function({bool roomId, bool birdsRefs})>;
typedef $$BirdsTableCreateCompanionBuilder = BirdsCompanion Function({
  Value<int> id,
  required String uuid,
  required String name,
  Value<String?> ringNumber,
  required int speciesId,
  Value<int?> roomId,
  Value<int?> enclosureId,
  required DateTime birthDate,
  Value<String> gender,
  Value<int> sortOrder,
  Value<int?> weighIntervalDays,
  Value<double?> manualBaselineG,
  Value<bool?> weaningOverride,
  Value<String> status,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$BirdsTableUpdateCompanionBuilder = BirdsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<String?> ringNumber,
  Value<int> speciesId,
  Value<int?> roomId,
  Value<int?> enclosureId,
  Value<DateTime> birthDate,
  Value<String> gender,
  Value<int> sortOrder,
  Value<int?> weighIntervalDays,
  Value<double?> manualBaselineG,
  Value<bool?> weaningOverride,
  Value<String> status,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

final class $$BirdsTableReferences
    extends BaseReferences<_$AppDatabase, $BirdsTable, Bird> {
  $$BirdsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SpeciesTable _speciesIdTable(_$AppDatabase db) => db.species
      .createAlias($_aliasNameGenerator(db.birds.speciesId, db.species.id));

  $$SpeciesTableProcessedTableManager get speciesId {
    final $_column = $_itemColumn<int>('species_id')!;

    final manager = $$SpeciesTableTableManager($_db, $_db.species)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_speciesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $RoomsTable _roomIdTable(_$AppDatabase db) =>
      db.rooms.createAlias($_aliasNameGenerator(db.birds.roomId, db.rooms.id));

  $$RoomsTableProcessedTableManager? get roomId {
    final $_column = $_itemColumn<int>('room_id');
    if ($_column == null) return null;
    final manager = $$RoomsTableTableManager($_db, $_db.rooms)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EnclosuresTable _enclosureIdTable(_$AppDatabase db) =>
      db.enclosures.createAlias(
          $_aliasNameGenerator(db.birds.enclosureId, db.enclosures.id));

  $$EnclosuresTableProcessedTableManager? get enclosureId {
    final $_column = $_itemColumn<int>('enclosure_id');
    if ($_column == null) return null;
    final manager = $$EnclosuresTableTableManager($_db, $_db.enclosures)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_enclosureIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$WeightsTable, List<Weight>> _weightsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.weights,
          aliasName: $_aliasNameGenerator(db.birds.id, db.weights.birdId));

  $$WeightsTableProcessedTableManager get weightsRefs {
    final manager = $$WeightsTableTableManager($_db, $_db.weights)
        .filter((f) => f.birdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_weightsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.tasks,
          aliasName: $_aliasNameGenerator(db.birds.id, db.tasks.birdId));

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.birdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AlertRecordsTable, List<AlertRecord>>
      _alertRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.alertRecords,
          aliasName: $_aliasNameGenerator(db.birds.id, db.alertRecords.birdId));

  $$AlertRecordsTableProcessedTableManager get alertRecordsRefs {
    final manager = $$AlertRecordsTableTableManager($_db, $_db.alertRecords)
        .filter((f) => f.birdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_alertRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MedicationsTable, List<Medication>>
      _medicationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.medications,
          aliasName: $_aliasNameGenerator(db.birds.id, db.medications.birdId));

  $$MedicationsTableProcessedTableManager get medicationsRefs {
    final manager = $$MedicationsTableTableManager($_db, $_db.medications)
        .filter((f) => f.birdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_medicationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BreedingPairsTable, List<BreedingPair>>
      _maleBreedingPairsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.breedingPairs,
              aliasName: $_aliasNameGenerator(
                  db.birds.id, db.breedingPairs.maleBirdId));

  $$BreedingPairsTableProcessedTableManager get maleBreedingPairs {
    final manager = $$BreedingPairsTableTableManager($_db, $_db.breedingPairs)
        .filter((f) => f.maleBirdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_maleBreedingPairsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BreedingPairsTable, List<BreedingPair>>
      _femaleBreedingPairsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.breedingPairs,
              aliasName: $_aliasNameGenerator(
                  db.birds.id, db.breedingPairs.femaleBirdId));

  $$BreedingPairsTableProcessedTableManager get femaleBreedingPairs {
    final manager = $$BreedingPairsTableTableManager($_db, $_db.breedingPairs)
        .filter((f) => f.femaleBirdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_femaleBreedingPairsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EggsTable, List<Egg>> _eggsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.eggs,
          aliasName: $_aliasNameGenerator(db.birds.id, db.eggs.chickBirdId));

  $$EggsTableProcessedTableManager get eggsRefs {
    final manager = $$EggsTableTableManager($_db, $_db.eggs)
        .filter((f) => f.chickBirdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eggsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ActivityLogsTable, List<ActivityLog>>
      _activityLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.activityLogs,
          aliasName: $_aliasNameGenerator(db.birds.id, db.activityLogs.birdId));

  $$ActivityLogsTableProcessedTableManager get activityLogsRefs {
    final manager = $$ActivityLogsTableTableManager($_db, $_db.activityLogs)
        .filter((f) => f.birdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_activityLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BirdPhotosTable, List<BirdPhoto>>
      _birdPhotosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.birdPhotos,
          aliasName: $_aliasNameGenerator(db.birds.id, db.birdPhotos.birdId));

  $$BirdPhotosTableProcessedTableManager get birdPhotosRefs {
    final manager = $$BirdPhotosTableTableManager($_db, $_db.birdPhotos)
        .filter((f) => f.birdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_birdPhotosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BirdAvatarsTable, List<BirdAvatar>>
      _birdAvatarsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.birdAvatars,
          aliasName: $_aliasNameGenerator(db.birds.id, db.birdAvatars.birdId));

  $$BirdAvatarsTableProcessedTableManager get birdAvatarsRefs {
    final manager = $$BirdAvatarsTableTableManager($_db, $_db.birdAvatars)
        .filter((f) => f.birdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_birdAvatarsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BirdsTableFilterComposer extends Composer<_$AppDatabase, $BirdsTable> {
  $$BirdsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ringNumber => $composableBuilder(
      column: $table.ringNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weighIntervalDays => $composableBuilder(
      column: $table.weighIntervalDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get manualBaselineG => $composableBuilder(
      column: $table.manualBaselineG,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get weaningOverride => $composableBuilder(
      column: $table.weaningOverride,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$SpeciesTableFilterComposer get speciesId {
    final $$SpeciesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.speciesId,
        referencedTable: $db.species,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SpeciesTableFilterComposer(
              $db: $db,
              $table: $db.species,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roomId,
        referencedTable: $db.rooms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoomsTableFilterComposer(
              $db: $db,
              $table: $db.rooms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnclosuresTableFilterComposer get enclosureId {
    final $$EnclosuresTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.enclosureId,
        referencedTable: $db.enclosures,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnclosuresTableFilterComposer(
              $db: $db,
              $table: $db.enclosures,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> weightsRefs(
      Expression<bool> Function($$WeightsTableFilterComposer f) f) {
    final $$WeightsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.weights,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WeightsTableFilterComposer(
              $db: $db,
              $table: $db.weights,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> tasksRefs(
      Expression<bool> Function($$TasksTableFilterComposer f) f) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableFilterComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> alertRecordsRefs(
      Expression<bool> Function($$AlertRecordsTableFilterComposer f) f) {
    final $$AlertRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.alertRecords,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlertRecordsTableFilterComposer(
              $db: $db,
              $table: $db.alertRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> medicationsRefs(
      Expression<bool> Function($$MedicationsTableFilterComposer f) f) {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.medications,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MedicationsTableFilterComposer(
              $db: $db,
              $table: $db.medications,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> maleBreedingPairs(
      Expression<bool> Function($$BreedingPairsTableFilterComposer f) f) {
    final $$BreedingPairsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.breedingPairs,
        getReferencedColumn: (t) => t.maleBirdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingPairsTableFilterComposer(
              $db: $db,
              $table: $db.breedingPairs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> femaleBreedingPairs(
      Expression<bool> Function($$BreedingPairsTableFilterComposer f) f) {
    final $$BreedingPairsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.breedingPairs,
        getReferencedColumn: (t) => t.femaleBirdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingPairsTableFilterComposer(
              $db: $db,
              $table: $db.breedingPairs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> eggsRefs(
      Expression<bool> Function($$EggsTableFilterComposer f) f) {
    final $$EggsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.eggs,
        getReferencedColumn: (t) => t.chickBirdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EggsTableFilterComposer(
              $db: $db,
              $table: $db.eggs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> activityLogsRefs(
      Expression<bool> Function($$ActivityLogsTableFilterComposer f) f) {
    final $$ActivityLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.activityLogs,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActivityLogsTableFilterComposer(
              $db: $db,
              $table: $db.activityLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> birdPhotosRefs(
      Expression<bool> Function($$BirdPhotosTableFilterComposer f) f) {
    final $$BirdPhotosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birdPhotos,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdPhotosTableFilterComposer(
              $db: $db,
              $table: $db.birdPhotos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> birdAvatarsRefs(
      Expression<bool> Function($$BirdAvatarsTableFilterComposer f) f) {
    final $$BirdAvatarsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birdAvatars,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdAvatarsTableFilterComposer(
              $db: $db,
              $table: $db.birdAvatars,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BirdsTableOrderingComposer
    extends Composer<_$AppDatabase, $BirdsTable> {
  $$BirdsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ringNumber => $composableBuilder(
      column: $table.ringNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weighIntervalDays => $composableBuilder(
      column: $table.weighIntervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get manualBaselineG => $composableBuilder(
      column: $table.manualBaselineG,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get weaningOverride => $composableBuilder(
      column: $table.weaningOverride,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$SpeciesTableOrderingComposer get speciesId {
    final $$SpeciesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.speciesId,
        referencedTable: $db.species,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SpeciesTableOrderingComposer(
              $db: $db,
              $table: $db.species,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roomId,
        referencedTable: $db.rooms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoomsTableOrderingComposer(
              $db: $db,
              $table: $db.rooms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnclosuresTableOrderingComposer get enclosureId {
    final $$EnclosuresTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.enclosureId,
        referencedTable: $db.enclosures,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnclosuresTableOrderingComposer(
              $db: $db,
              $table: $db.enclosures,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BirdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BirdsTable> {
  $$BirdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ringNumber => $composableBuilder(
      column: $table.ringNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get weighIntervalDays => $composableBuilder(
      column: $table.weighIntervalDays, builder: (column) => column);

  GeneratedColumn<double> get manualBaselineG => $composableBuilder(
      column: $table.manualBaselineG, builder: (column) => column);

  GeneratedColumn<bool> get weaningOverride => $composableBuilder(
      column: $table.weaningOverride, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$SpeciesTableAnnotationComposer get speciesId {
    final $$SpeciesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.speciesId,
        referencedTable: $db.species,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SpeciesTableAnnotationComposer(
              $db: $db,
              $table: $db.species,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roomId,
        referencedTable: $db.rooms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoomsTableAnnotationComposer(
              $db: $db,
              $table: $db.rooms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnclosuresTableAnnotationComposer get enclosureId {
    final $$EnclosuresTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.enclosureId,
        referencedTable: $db.enclosures,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnclosuresTableAnnotationComposer(
              $db: $db,
              $table: $db.enclosures,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> weightsRefs<T extends Object>(
      Expression<T> Function($$WeightsTableAnnotationComposer a) f) {
    final $$WeightsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.weights,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WeightsTableAnnotationComposer(
              $db: $db,
              $table: $db.weights,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
      Expression<T> Function($$TasksTableAnnotationComposer a) f) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableAnnotationComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> alertRecordsRefs<T extends Object>(
      Expression<T> Function($$AlertRecordsTableAnnotationComposer a) f) {
    final $$AlertRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.alertRecords,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlertRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.alertRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> medicationsRefs<T extends Object>(
      Expression<T> Function($$MedicationsTableAnnotationComposer a) f) {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.medications,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MedicationsTableAnnotationComposer(
              $db: $db,
              $table: $db.medications,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> maleBreedingPairs<T extends Object>(
      Expression<T> Function($$BreedingPairsTableAnnotationComposer a) f) {
    final $$BreedingPairsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.breedingPairs,
        getReferencedColumn: (t) => t.maleBirdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingPairsTableAnnotationComposer(
              $db: $db,
              $table: $db.breedingPairs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> femaleBreedingPairs<T extends Object>(
      Expression<T> Function($$BreedingPairsTableAnnotationComposer a) f) {
    final $$BreedingPairsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.breedingPairs,
        getReferencedColumn: (t) => t.femaleBirdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingPairsTableAnnotationComposer(
              $db: $db,
              $table: $db.breedingPairs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> eggsRefs<T extends Object>(
      Expression<T> Function($$EggsTableAnnotationComposer a) f) {
    final $$EggsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.eggs,
        getReferencedColumn: (t) => t.chickBirdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EggsTableAnnotationComposer(
              $db: $db,
              $table: $db.eggs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> activityLogsRefs<T extends Object>(
      Expression<T> Function($$ActivityLogsTableAnnotationComposer a) f) {
    final $$ActivityLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.activityLogs,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActivityLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.activityLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> birdPhotosRefs<T extends Object>(
      Expression<T> Function($$BirdPhotosTableAnnotationComposer a) f) {
    final $$BirdPhotosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birdPhotos,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdPhotosTableAnnotationComposer(
              $db: $db,
              $table: $db.birdPhotos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> birdAvatarsRefs<T extends Object>(
      Expression<T> Function($$BirdAvatarsTableAnnotationComposer a) f) {
    final $$BirdAvatarsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.birdAvatars,
        getReferencedColumn: (t) => t.birdId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdAvatarsTableAnnotationComposer(
              $db: $db,
              $table: $db.birdAvatars,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BirdsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BirdsTable,
    Bird,
    $$BirdsTableFilterComposer,
    $$BirdsTableOrderingComposer,
    $$BirdsTableAnnotationComposer,
    $$BirdsTableCreateCompanionBuilder,
    $$BirdsTableUpdateCompanionBuilder,
    (Bird, $$BirdsTableReferences),
    Bird,
    PrefetchHooks Function(
        {bool speciesId,
        bool roomId,
        bool enclosureId,
        bool weightsRefs,
        bool tasksRefs,
        bool alertRecordsRefs,
        bool medicationsRefs,
        bool maleBreedingPairs,
        bool femaleBreedingPairs,
        bool eggsRefs,
        bool activityLogsRefs,
        bool birdPhotosRefs,
        bool birdAvatarsRefs})> {
  $$BirdsTableTableManager(_$AppDatabase db, $BirdsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BirdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BirdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BirdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> ringNumber = const Value.absent(),
            Value<int> speciesId = const Value.absent(),
            Value<int?> roomId = const Value.absent(),
            Value<int?> enclosureId = const Value.absent(),
            Value<DateTime> birthDate = const Value.absent(),
            Value<String> gender = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> weighIntervalDays = const Value.absent(),
            Value<double?> manualBaselineG = const Value.absent(),
            Value<bool?> weaningOverride = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              BirdsCompanion(
            id: id,
            uuid: uuid,
            name: name,
            ringNumber: ringNumber,
            speciesId: speciesId,
            roomId: roomId,
            enclosureId: enclosureId,
            birthDate: birthDate,
            gender: gender,
            sortOrder: sortOrder,
            weighIntervalDays: weighIntervalDays,
            manualBaselineG: manualBaselineG,
            weaningOverride: weaningOverride,
            status: status,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String name,
            Value<String?> ringNumber = const Value.absent(),
            required int speciesId,
            Value<int?> roomId = const Value.absent(),
            Value<int?> enclosureId = const Value.absent(),
            required DateTime birthDate,
            Value<String> gender = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> weighIntervalDays = const Value.absent(),
            Value<double?> manualBaselineG = const Value.absent(),
            Value<bool?> weaningOverride = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              BirdsCompanion.insert(
            id: id,
            uuid: uuid,
            name: name,
            ringNumber: ringNumber,
            speciesId: speciesId,
            roomId: roomId,
            enclosureId: enclosureId,
            birthDate: birthDate,
            gender: gender,
            sortOrder: sortOrder,
            weighIntervalDays: weighIntervalDays,
            manualBaselineG: manualBaselineG,
            weaningOverride: weaningOverride,
            status: status,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BirdsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {speciesId = false,
              roomId = false,
              enclosureId = false,
              weightsRefs = false,
              tasksRefs = false,
              alertRecordsRefs = false,
              medicationsRefs = false,
              maleBreedingPairs = false,
              femaleBreedingPairs = false,
              eggsRefs = false,
              activityLogsRefs = false,
              birdPhotosRefs = false,
              birdAvatarsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (weightsRefs) db.weights,
                if (tasksRefs) db.tasks,
                if (alertRecordsRefs) db.alertRecords,
                if (medicationsRefs) db.medications,
                if (maleBreedingPairs) db.breedingPairs,
                if (femaleBreedingPairs) db.breedingPairs,
                if (eggsRefs) db.eggs,
                if (activityLogsRefs) db.activityLogs,
                if (birdPhotosRefs) db.birdPhotos,
                if (birdAvatarsRefs) db.birdAvatars
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (speciesId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.speciesId,
                    referencedTable: $$BirdsTableReferences._speciesIdTable(db),
                    referencedColumn:
                        $$BirdsTableReferences._speciesIdTable(db).id,
                  ) as T;
                }
                if (roomId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.roomId,
                    referencedTable: $$BirdsTableReferences._roomIdTable(db),
                    referencedColumn:
                        $$BirdsTableReferences._roomIdTable(db).id,
                  ) as T;
                }
                if (enclosureId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.enclosureId,
                    referencedTable:
                        $$BirdsTableReferences._enclosureIdTable(db),
                    referencedColumn:
                        $$BirdsTableReferences._enclosureIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (weightsRefs)
                    await $_getPrefetchedData<Bird, $BirdsTable, Weight>(
                        currentTable: table,
                        referencedTable:
                            $$BirdsTableReferences._weightsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0).weightsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.birdId == item.id),
                        typedResults: items),
                  if (tasksRefs)
                    await $_getPrefetchedData<Bird, $BirdsTable, Task>(
                        currentTable: table,
                        referencedTable:
                            $$BirdsTableReferences._tasksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0).tasksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.birdId == item.id),
                        typedResults: items),
                  if (alertRecordsRefs)
                    await $_getPrefetchedData<Bird, $BirdsTable, AlertRecord>(
                        currentTable: table,
                        referencedTable:
                            $$BirdsTableReferences._alertRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0)
                                .alertRecordsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.birdId == item.id),
                        typedResults: items),
                  if (medicationsRefs)
                    await $_getPrefetchedData<Bird, $BirdsTable, Medication>(
                        currentTable: table,
                        referencedTable:
                            $$BirdsTableReferences._medicationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0)
                                .medicationsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.birdId == item.id),
                        typedResults: items),
                  if (maleBreedingPairs)
                    await $_getPrefetchedData<Bird, $BirdsTable, BreedingPair>(
                        currentTable: table,
                        referencedTable:
                            $$BirdsTableReferences._maleBreedingPairsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0)
                                .maleBreedingPairs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.maleBirdId == item.id),
                        typedResults: items),
                  if (femaleBreedingPairs)
                    await $_getPrefetchedData<Bird, $BirdsTable, BreedingPair>(
                        currentTable: table,
                        referencedTable: $$BirdsTableReferences
                            ._femaleBreedingPairsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0)
                                .femaleBreedingPairs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.femaleBirdId == item.id),
                        typedResults: items),
                  if (eggsRefs)
                    await $_getPrefetchedData<Bird, $BirdsTable, Egg>(
                        currentTable: table,
                        referencedTable:
                            $$BirdsTableReferences._eggsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0).eggsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.chickBirdId == item.id),
                        typedResults: items),
                  if (activityLogsRefs)
                    await $_getPrefetchedData<Bird, $BirdsTable, ActivityLog>(
                        currentTable: table,
                        referencedTable:
                            $$BirdsTableReferences._activityLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0)
                                .activityLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.birdId == item.id),
                        typedResults: items),
                  if (birdPhotosRefs)
                    await $_getPrefetchedData<Bird, $BirdsTable, BirdPhoto>(
                        currentTable: table,
                        referencedTable:
                            $$BirdsTableReferences._birdPhotosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0)
                                .birdPhotosRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.birdId == item.id),
                        typedResults: items),
                  if (birdAvatarsRefs)
                    await $_getPrefetchedData<Bird, $BirdsTable, BirdAvatar>(
                        currentTable: table,
                        referencedTable:
                            $$BirdsTableReferences._birdAvatarsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BirdsTableReferences(db, table, p0)
                                .birdAvatarsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.birdId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BirdsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BirdsTable,
    Bird,
    $$BirdsTableFilterComposer,
    $$BirdsTableOrderingComposer,
    $$BirdsTableAnnotationComposer,
    $$BirdsTableCreateCompanionBuilder,
    $$BirdsTableUpdateCompanionBuilder,
    (Bird, $$BirdsTableReferences),
    Bird,
    PrefetchHooks Function(
        {bool speciesId,
        bool roomId,
        bool enclosureId,
        bool weightsRefs,
        bool tasksRefs,
        bool alertRecordsRefs,
        bool medicationsRefs,
        bool maleBreedingPairs,
        bool femaleBreedingPairs,
        bool eggsRefs,
        bool activityLogsRefs,
        bool birdPhotosRefs,
        bool birdAvatarsRefs})>;
typedef $$WeightsTableCreateCompanionBuilder = WeightsCompanion Function({
  Value<int> id,
  required String uuid,
  required int birdId,
  required double weightG,
  required DateTime recordedAt,
  Value<int?> recordedBy,
  Value<bool> isFasting,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$WeightsTableUpdateCompanionBuilder = WeightsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> birdId,
  Value<double> weightG,
  Value<DateTime> recordedAt,
  Value<int?> recordedBy,
  Value<bool> isFasting,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$WeightsTableReferences
    extends BaseReferences<_$AppDatabase, $WeightsTable, Weight> {
  $$WeightsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BirdsTable _birdIdTable(_$AppDatabase db) => db.birds
      .createAlias($_aliasNameGenerator(db.weights.birdId, db.birds.id));

  $$BirdsTableProcessedTableManager get birdId {
    final $_column = $_itemColumn<int>('bird_id')!;

    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_birdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _recordedByTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.weights.recordedBy, db.users.id));

  $$UsersTableProcessedTableManager? get recordedBy {
    final $_column = $_itemColumn<int>('recorded_by');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WeightsTableFilterComposer
    extends Composer<_$AppDatabase, $WeightsTable> {
  $$WeightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightG => $composableBuilder(
      column: $table.weightG, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFasting => $composableBuilder(
      column: $table.isFasting, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$BirdsTableFilterComposer get birdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get recordedBy {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recordedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WeightsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightsTable> {
  $$WeightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightG => $composableBuilder(
      column: $table.weightG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFasting => $composableBuilder(
      column: $table.isFasting, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$BirdsTableOrderingComposer get birdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get recordedBy {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recordedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WeightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightsTable> {
  $$WeightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<double> get weightG =>
      $composableBuilder(column: $table.weightG, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<bool> get isFasting =>
      $composableBuilder(column: $table.isFasting, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BirdsTableAnnotationComposer get birdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get recordedBy {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recordedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WeightsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeightsTable,
    Weight,
    $$WeightsTableFilterComposer,
    $$WeightsTableOrderingComposer,
    $$WeightsTableAnnotationComposer,
    $$WeightsTableCreateCompanionBuilder,
    $$WeightsTableUpdateCompanionBuilder,
    (Weight, $$WeightsTableReferences),
    Weight,
    PrefetchHooks Function({bool birdId, bool recordedBy})> {
  $$WeightsTableTableManager(_$AppDatabase db, $WeightsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> birdId = const Value.absent(),
            Value<double> weightG = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<int?> recordedBy = const Value.absent(),
            Value<bool> isFasting = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WeightsCompanion(
            id: id,
            uuid: uuid,
            birdId: birdId,
            weightG: weightG,
            recordedAt: recordedAt,
            recordedBy: recordedBy,
            isFasting: isFasting,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int birdId,
            required double weightG,
            required DateTime recordedAt,
            Value<int?> recordedBy = const Value.absent(),
            Value<bool> isFasting = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WeightsCompanion.insert(
            id: id,
            uuid: uuid,
            birdId: birdId,
            weightG: weightG,
            recordedAt: recordedAt,
            recordedBy: recordedBy,
            isFasting: isFasting,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$WeightsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({birdId = false, recordedBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (birdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.birdId,
                    referencedTable: $$WeightsTableReferences._birdIdTable(db),
                    referencedColumn:
                        $$WeightsTableReferences._birdIdTable(db).id,
                  ) as T;
                }
                if (recordedBy) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recordedBy,
                    referencedTable:
                        $$WeightsTableReferences._recordedByTable(db),
                    referencedColumn:
                        $$WeightsTableReferences._recordedByTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WeightsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WeightsTable,
    Weight,
    $$WeightsTableFilterComposer,
    $$WeightsTableOrderingComposer,
    $$WeightsTableAnnotationComposer,
    $$WeightsTableCreateCompanionBuilder,
    $$WeightsTableUpdateCompanionBuilder,
    (Weight, $$WeightsTableReferences),
    Weight,
    PrefetchHooks Function({bool birdId, bool recordedBy})>;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  required String uuid,
  required int birdId,
  Value<int?> roomId,
  Value<int?> assignedUserId,
  Value<String> taskType,
  required DateTime dueDate,
  Value<DateTime?> deadline,
  Value<String> status,
  Value<DateTime?> completedAt,
  Value<int?> completedBy,
  Value<String?> metadata,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> birdId,
  Value<int?> roomId,
  Value<int?> assignedUserId,
  Value<String> taskType,
  Value<DateTime> dueDate,
  Value<DateTime?> deadline,
  Value<String> status,
  Value<DateTime?> completedAt,
  Value<int?> completedBy,
  Value<String?> metadata,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BirdsTable _birdIdTable(_$AppDatabase db) =>
      db.birds.createAlias($_aliasNameGenerator(db.tasks.birdId, db.birds.id));

  $$BirdsTableProcessedTableManager get birdId {
    final $_column = $_itemColumn<int>('bird_id')!;

    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_birdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $RoomsTable _roomIdTable(_$AppDatabase db) =>
      db.rooms.createAlias($_aliasNameGenerator(db.tasks.roomId, db.rooms.id));

  $$RoomsTableProcessedTableManager? get roomId {
    final $_column = $_itemColumn<int>('room_id');
    if ($_column == null) return null;
    final manager = $$RoomsTableTableManager($_db, $_db.rooms)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ActivityLogsTable, List<ActivityLog>>
      _activityLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.activityLogs,
          aliasName:
              $_aliasNameGenerator(db.tasks.id, db.activityLogs.relatedTaskId));

  $$ActivityLogsTableProcessedTableManager get activityLogsRefs {
    final manager = $$ActivityLogsTableTableManager($_db, $_db.activityLogs)
        .filter((f) => f.relatedTaskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_activityLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedBy => $composableBuilder(
      column: $table.completedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$BirdsTableFilterComposer get birdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roomId,
        referencedTable: $db.rooms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoomsTableFilterComposer(
              $db: $db,
              $table: $db.rooms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> activityLogsRefs(
      Expression<bool> Function($$ActivityLogsTableFilterComposer f) f) {
    final $$ActivityLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.activityLogs,
        getReferencedColumn: (t) => t.relatedTaskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActivityLogsTableFilterComposer(
              $db: $db,
              $table: $db.activityLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedBy => $composableBuilder(
      column: $table.completedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$BirdsTableOrderingComposer get birdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roomId,
        referencedTable: $db.rooms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoomsTableOrderingComposer(
              $db: $db,
              $table: $db.rooms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get completedBy => $composableBuilder(
      column: $table.completedBy, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BirdsTableAnnotationComposer get birdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roomId,
        referencedTable: $db.rooms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoomsTableAnnotationComposer(
              $db: $db,
              $table: $db.rooms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> activityLogsRefs<T extends Object>(
      Expression<T> Function($$ActivityLogsTableAnnotationComposer a) f) {
    final $$ActivityLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.activityLogs,
        getReferencedColumn: (t) => t.relatedTaskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActivityLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.activityLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool birdId, bool roomId, bool activityLogsRefs})> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> birdId = const Value.absent(),
            Value<int?> roomId = const Value.absent(),
            Value<int?> assignedUserId = const Value.absent(),
            Value<String> taskType = const Value.absent(),
            Value<DateTime> dueDate = const Value.absent(),
            Value<DateTime?> deadline = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int?> completedBy = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            uuid: uuid,
            birdId: birdId,
            roomId: roomId,
            assignedUserId: assignedUserId,
            taskType: taskType,
            dueDate: dueDate,
            deadline: deadline,
            status: status,
            completedAt: completedAt,
            completedBy: completedBy,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int birdId,
            Value<int?> roomId = const Value.absent(),
            Value<int?> assignedUserId = const Value.absent(),
            Value<String> taskType = const Value.absent(),
            required DateTime dueDate,
            Value<DateTime?> deadline = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int?> completedBy = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            uuid: uuid,
            birdId: birdId,
            roomId: roomId,
            assignedUserId: assignedUserId,
            taskType: taskType,
            dueDate: dueDate,
            deadline: deadline,
            status: status,
            completedAt: completedAt,
            completedBy: completedBy,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TasksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {birdId = false, roomId = false, activityLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (activityLogsRefs) db.activityLogs],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (birdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.birdId,
                    referencedTable: $$TasksTableReferences._birdIdTable(db),
                    referencedColumn:
                        $$TasksTableReferences._birdIdTable(db).id,
                  ) as T;
                }
                if (roomId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.roomId,
                    referencedTable: $$TasksTableReferences._roomIdTable(db),
                    referencedColumn:
                        $$TasksTableReferences._roomIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (activityLogsRefs)
                    await $_getPrefetchedData<Task, $TasksTable, ActivityLog>(
                        currentTable: table,
                        referencedTable:
                            $$TasksTableReferences._activityLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TasksTableReferences(db, table, p0)
                                .activityLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.relatedTaskId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool birdId, bool roomId, bool activityLogsRefs})>;
typedef $$AlertRecordsTableCreateCompanionBuilder = AlertRecordsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required int birdId,
  required String alertType,
  required String description,
  required String severity,
  Value<bool> isRead,
  Value<bool> isResolved,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> resolvedAt,
});
typedef $$AlertRecordsTableUpdateCompanionBuilder = AlertRecordsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> birdId,
  Value<String> alertType,
  Value<String> description,
  Value<String> severity,
  Value<bool> isRead,
  Value<bool> isResolved,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> resolvedAt,
});

final class $$AlertRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $AlertRecordsTable, AlertRecord> {
  $$AlertRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BirdsTable _birdIdTable(_$AppDatabase db) => db.birds
      .createAlias($_aliasNameGenerator(db.alertRecords.birdId, db.birds.id));

  $$BirdsTableProcessedTableManager get birdId {
    final $_column = $_itemColumn<int>('bird_id')!;

    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_birdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AlertRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AlertRecordsTable> {
  $$AlertRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alertType => $composableBuilder(
      column: $table.alertType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isResolved => $composableBuilder(
      column: $table.isResolved, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
      column: $table.resolvedAt, builder: (column) => ColumnFilters(column));

  $$BirdsTableFilterComposer get birdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AlertRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertRecordsTable> {
  $$AlertRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alertType => $composableBuilder(
      column: $table.alertType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isResolved => $composableBuilder(
      column: $table.isResolved, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
      column: $table.resolvedAt, builder: (column) => ColumnOrderings(column));

  $$BirdsTableOrderingComposer get birdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AlertRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertRecordsTable> {
  $$AlertRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get alertType =>
      $composableBuilder(column: $table.alertType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get isResolved => $composableBuilder(
      column: $table.isResolved, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
      column: $table.resolvedAt, builder: (column) => column);

  $$BirdsTableAnnotationComposer get birdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AlertRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlertRecordsTable,
    AlertRecord,
    $$AlertRecordsTableFilterComposer,
    $$AlertRecordsTableOrderingComposer,
    $$AlertRecordsTableAnnotationComposer,
    $$AlertRecordsTableCreateCompanionBuilder,
    $$AlertRecordsTableUpdateCompanionBuilder,
    (AlertRecord, $$AlertRecordsTableReferences),
    AlertRecord,
    PrefetchHooks Function({bool birdId})> {
  $$AlertRecordsTableTableManager(_$AppDatabase db, $AlertRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> birdId = const Value.absent(),
            Value<String> alertType = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> severity = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<bool> isResolved = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> resolvedAt = const Value.absent(),
          }) =>
              AlertRecordsCompanion(
            id: id,
            uuid: uuid,
            birdId: birdId,
            alertType: alertType,
            description: description,
            severity: severity,
            isRead: isRead,
            isResolved: isResolved,
            createdAt: createdAt,
            updatedAt: updatedAt,
            resolvedAt: resolvedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int birdId,
            required String alertType,
            required String description,
            required String severity,
            Value<bool> isRead = const Value.absent(),
            Value<bool> isResolved = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> resolvedAt = const Value.absent(),
          }) =>
              AlertRecordsCompanion.insert(
            id: id,
            uuid: uuid,
            birdId: birdId,
            alertType: alertType,
            description: description,
            severity: severity,
            isRead: isRead,
            isResolved: isResolved,
            createdAt: createdAt,
            updatedAt: updatedAt,
            resolvedAt: resolvedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AlertRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({birdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (birdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.birdId,
                    referencedTable:
                        $$AlertRecordsTableReferences._birdIdTable(db),
                    referencedColumn:
                        $$AlertRecordsTableReferences._birdIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AlertRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AlertRecordsTable,
    AlertRecord,
    $$AlertRecordsTableFilterComposer,
    $$AlertRecordsTableOrderingComposer,
    $$AlertRecordsTableAnnotationComposer,
    $$AlertRecordsTableCreateCompanionBuilder,
    $$AlertRecordsTableUpdateCompanionBuilder,
    (AlertRecord, $$AlertRecordsTableReferences),
    AlertRecord,
    PrefetchHooks Function({bool birdId})>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String opId,
  required String deviceId,
  required int userId,
  required String action,
  required String entityType,
  required String entityUuid,
  required String payload,
  required DateTime createdAt,
  Value<bool> synced,
  Value<int> retryCount,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> opId,
  Value<String> deviceId,
  Value<int> userId,
  Value<String> action,
  Value<String> entityType,
  Value<String> entityUuid,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> retryCount,
});

final class $$SyncQueueTableReferences
    extends BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData> {
  $$SyncQueueTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.syncQueue.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get opId => $composableBuilder(
      column: $table.opId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityUuid => $composableBuilder(
      column: $table.entityUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get opId => $composableBuilder(
      column: $table.opId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityUuid => $composableBuilder(
      column: $table.entityUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityUuid => $composableBuilder(
      column: $table.entityUuid, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (SyncQueueData, $$SyncQueueTableReferences),
    SyncQueueData,
    PrefetchHooks Function({bool userId})> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> opId = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityUuid = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            opId: opId,
            deviceId: deviceId,
            userId: userId,
            action: action,
            entityType: entityType,
            entityUuid: entityUuid,
            payload: payload,
            createdAt: createdAt,
            synced: synced,
            retryCount: retryCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String opId,
            required String deviceId,
            required int userId,
            required String action,
            required String entityType,
            required String entityUuid,
            required String payload,
            required DateTime createdAt,
            Value<bool> synced = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            opId: opId,
            deviceId: deviceId,
            userId: userId,
            action: action,
            entityType: entityType,
            entityUuid: entityUuid,
            payload: payload,
            createdAt: createdAt,
            synced: synced,
            retryCount: retryCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SyncQueueTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$SyncQueueTableReferences._userIdTable(db),
                    referencedColumn:
                        $$SyncQueueTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (SyncQueueData, $$SyncQueueTableReferences),
    SyncQueueData,
    PrefetchHooks Function({bool userId})>;
typedef $$MedicationsTableCreateCompanionBuilder = MedicationsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required int birdId,
  required String drugName,
  Value<String> drugType,
  required String dosage,
  Value<int> timesPerDay,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<String?> notes,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$MedicationsTableUpdateCompanionBuilder = MedicationsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> birdId,
  Value<String> drugName,
  Value<String> drugType,
  Value<String> dosage,
  Value<int> timesPerDay,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<String?> notes,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$MedicationsTableReferences
    extends BaseReferences<_$AppDatabase, $MedicationsTable, Medication> {
  $$MedicationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BirdsTable _birdIdTable(_$AppDatabase db) => db.birds
      .createAlias($_aliasNameGenerator(db.medications.birdId, db.birds.id));

  $$BirdsTableProcessedTableManager get birdId {
    final $_column = $_itemColumn<int>('bird_id')!;

    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_birdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get drugName => $composableBuilder(
      column: $table.drugName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get drugType => $composableBuilder(
      column: $table.drugType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dosage => $composableBuilder(
      column: $table.dosage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timesPerDay => $composableBuilder(
      column: $table.timesPerDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$BirdsTableFilterComposer get birdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get drugName => $composableBuilder(
      column: $table.drugName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get drugType => $composableBuilder(
      column: $table.drugType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dosage => $composableBuilder(
      column: $table.dosage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timesPerDay => $composableBuilder(
      column: $table.timesPerDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$BirdsTableOrderingComposer get birdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get drugName =>
      $composableBuilder(column: $table.drugName, builder: (column) => column);

  GeneratedColumn<String> get drugType =>
      $composableBuilder(column: $table.drugType, builder: (column) => column);

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<int> get timesPerDay => $composableBuilder(
      column: $table.timesPerDay, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BirdsTableAnnotationComposer get birdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MedicationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MedicationsTable,
    Medication,
    $$MedicationsTableFilterComposer,
    $$MedicationsTableOrderingComposer,
    $$MedicationsTableAnnotationComposer,
    $$MedicationsTableCreateCompanionBuilder,
    $$MedicationsTableUpdateCompanionBuilder,
    (Medication, $$MedicationsTableReferences),
    Medication,
    PrefetchHooks Function({bool birdId})> {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> birdId = const Value.absent(),
            Value<String> drugName = const Value.absent(),
            Value<String> drugType = const Value.absent(),
            Value<String> dosage = const Value.absent(),
            Value<int> timesPerDay = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MedicationsCompanion(
            id: id,
            uuid: uuid,
            birdId: birdId,
            drugName: drugName,
            drugType: drugType,
            dosage: dosage,
            timesPerDay: timesPerDay,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int birdId,
            required String drugName,
            Value<String> drugType = const Value.absent(),
            required String dosage,
            Value<int> timesPerDay = const Value.absent(),
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MedicationsCompanion.insert(
            id: id,
            uuid: uuid,
            birdId: birdId,
            drugName: drugName,
            drugType: drugType,
            dosage: dosage,
            timesPerDay: timesPerDay,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MedicationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({birdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (birdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.birdId,
                    referencedTable:
                        $$MedicationsTableReferences._birdIdTable(db),
                    referencedColumn:
                        $$MedicationsTableReferences._birdIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MedicationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MedicationsTable,
    Medication,
    $$MedicationsTableFilterComposer,
    $$MedicationsTableOrderingComposer,
    $$MedicationsTableAnnotationComposer,
    $$MedicationsTableCreateCompanionBuilder,
    $$MedicationsTableUpdateCompanionBuilder,
    (Medication, $$MedicationsTableReferences),
    Medication,
    PrefetchHooks Function({bool birdId})>;
typedef $$BreedingPairsTableCreateCompanionBuilder = BreedingPairsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required int maleBirdId,
  required int femaleBirdId,
  Value<String?> pairName,
  Value<String> status,
  Value<DateTime> pairedDate,
  Value<DateTime?> separatedDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$BreedingPairsTableUpdateCompanionBuilder = BreedingPairsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> maleBirdId,
  Value<int> femaleBirdId,
  Value<String?> pairName,
  Value<String> status,
  Value<DateTime> pairedDate,
  Value<DateTime?> separatedDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$BreedingPairsTableReferences
    extends BaseReferences<_$AppDatabase, $BreedingPairsTable, BreedingPair> {
  $$BreedingPairsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $BirdsTable _maleBirdIdTable(_$AppDatabase db) => db.birds.createAlias(
      $_aliasNameGenerator(db.breedingPairs.maleBirdId, db.birds.id));

  $$BirdsTableProcessedTableManager get maleBirdId {
    final $_column = $_itemColumn<int>('male_bird_id')!;

    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_maleBirdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BirdsTable _femaleBirdIdTable(_$AppDatabase db) =>
      db.birds.createAlias(
          $_aliasNameGenerator(db.breedingPairs.femaleBirdId, db.birds.id));

  $$BirdsTableProcessedTableManager get femaleBirdId {
    final $_column = $_itemColumn<int>('female_bird_id')!;

    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_femaleBirdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$BreedingRecordsTable, List<BreedingRecord>>
      _breedingRecordsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.breedingRecords,
              aliasName: $_aliasNameGenerator(
                  db.breedingPairs.id, db.breedingRecords.pairId));

  $$BreedingRecordsTableProcessedTableManager get breedingRecordsRefs {
    final manager =
        $$BreedingRecordsTableTableManager($_db, $_db.breedingRecords)
            .filter((f) => f.pairId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_breedingRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BreedingPairsTableFilterComposer
    extends Composer<_$AppDatabase, $BreedingPairsTable> {
  $$BreedingPairsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pairName => $composableBuilder(
      column: $table.pairName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pairedDate => $composableBuilder(
      column: $table.pairedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get separatedDate => $composableBuilder(
      column: $table.separatedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$BirdsTableFilterComposer get maleBirdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.maleBirdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BirdsTableFilterComposer get femaleBirdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.femaleBirdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> breedingRecordsRefs(
      Expression<bool> Function($$BreedingRecordsTableFilterComposer f) f) {
    final $$BreedingRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.breedingRecords,
        getReferencedColumn: (t) => t.pairId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingRecordsTableFilterComposer(
              $db: $db,
              $table: $db.breedingRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BreedingPairsTableOrderingComposer
    extends Composer<_$AppDatabase, $BreedingPairsTable> {
  $$BreedingPairsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pairName => $composableBuilder(
      column: $table.pairName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pairedDate => $composableBuilder(
      column: $table.pairedDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get separatedDate => $composableBuilder(
      column: $table.separatedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$BirdsTableOrderingComposer get maleBirdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.maleBirdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BirdsTableOrderingComposer get femaleBirdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.femaleBirdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BreedingPairsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BreedingPairsTable> {
  $$BreedingPairsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get pairName =>
      $composableBuilder(column: $table.pairName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get pairedDate => $composableBuilder(
      column: $table.pairedDate, builder: (column) => column);

  GeneratedColumn<DateTime> get separatedDate => $composableBuilder(
      column: $table.separatedDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BirdsTableAnnotationComposer get maleBirdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.maleBirdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BirdsTableAnnotationComposer get femaleBirdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.femaleBirdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> breedingRecordsRefs<T extends Object>(
      Expression<T> Function($$BreedingRecordsTableAnnotationComposer a) f) {
    final $$BreedingRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.breedingRecords,
        getReferencedColumn: (t) => t.pairId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.breedingRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BreedingPairsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BreedingPairsTable,
    BreedingPair,
    $$BreedingPairsTableFilterComposer,
    $$BreedingPairsTableOrderingComposer,
    $$BreedingPairsTableAnnotationComposer,
    $$BreedingPairsTableCreateCompanionBuilder,
    $$BreedingPairsTableUpdateCompanionBuilder,
    (BreedingPair, $$BreedingPairsTableReferences),
    BreedingPair,
    PrefetchHooks Function(
        {bool maleBirdId, bool femaleBirdId, bool breedingRecordsRefs})> {
  $$BreedingPairsTableTableManager(_$AppDatabase db, $BreedingPairsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BreedingPairsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BreedingPairsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BreedingPairsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> maleBirdId = const Value.absent(),
            Value<int> femaleBirdId = const Value.absent(),
            Value<String?> pairName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> pairedDate = const Value.absent(),
            Value<DateTime?> separatedDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BreedingPairsCompanion(
            id: id,
            uuid: uuid,
            maleBirdId: maleBirdId,
            femaleBirdId: femaleBirdId,
            pairName: pairName,
            status: status,
            pairedDate: pairedDate,
            separatedDate: separatedDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int maleBirdId,
            required int femaleBirdId,
            Value<String?> pairName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> pairedDate = const Value.absent(),
            Value<DateTime?> separatedDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BreedingPairsCompanion.insert(
            id: id,
            uuid: uuid,
            maleBirdId: maleBirdId,
            femaleBirdId: femaleBirdId,
            pairName: pairName,
            status: status,
            pairedDate: pairedDate,
            separatedDate: separatedDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BreedingPairsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {maleBirdId = false,
              femaleBirdId = false,
              breedingRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (breedingRecordsRefs) db.breedingRecords
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (maleBirdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.maleBirdId,
                    referencedTable:
                        $$BreedingPairsTableReferences._maleBirdIdTable(db),
                    referencedColumn:
                        $$BreedingPairsTableReferences._maleBirdIdTable(db).id,
                  ) as T;
                }
                if (femaleBirdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.femaleBirdId,
                    referencedTable:
                        $$BreedingPairsTableReferences._femaleBirdIdTable(db),
                    referencedColumn: $$BreedingPairsTableReferences
                        ._femaleBirdIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (breedingRecordsRefs)
                    await $_getPrefetchedData<BreedingPair, $BreedingPairsTable, BreedingRecord>(
                        currentTable: table,
                        referencedTable: $$BreedingPairsTableReferences
                            ._breedingRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BreedingPairsTableReferences(db, table, p0)
                                .breedingRecordsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.pairId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BreedingPairsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BreedingPairsTable,
    BreedingPair,
    $$BreedingPairsTableFilterComposer,
    $$BreedingPairsTableOrderingComposer,
    $$BreedingPairsTableAnnotationComposer,
    $$BreedingPairsTableCreateCompanionBuilder,
    $$BreedingPairsTableUpdateCompanionBuilder,
    (BreedingPair, $$BreedingPairsTableReferences),
    BreedingPair,
    PrefetchHooks Function(
        {bool maleBirdId, bool femaleBirdId, bool breedingRecordsRefs})>;
typedef $$BreedingRecordsTableCreateCompanionBuilder = BreedingRecordsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required int pairId,
  Value<String> stage,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<String?> endReason,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$BreedingRecordsTableUpdateCompanionBuilder = BreedingRecordsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> pairId,
  Value<String> stage,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<String?> endReason,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$BreedingRecordsTableReferences extends BaseReferences<
    _$AppDatabase, $BreedingRecordsTable, BreedingRecord> {
  $$BreedingRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $BreedingPairsTable _pairIdTable(_$AppDatabase db) =>
      db.breedingPairs.createAlias(
          $_aliasNameGenerator(db.breedingRecords.pairId, db.breedingPairs.id));

  $$BreedingPairsTableProcessedTableManager get pairId {
    final $_column = $_itemColumn<int>('pair_id')!;

    final manager = $$BreedingPairsTableTableManager($_db, $_db.breedingPairs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pairIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$EggsTable, List<Egg>> _eggsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.eggs,
          aliasName: $_aliasNameGenerator(
              db.breedingRecords.id, db.eggs.breedingRecordId));

  $$EggsTableProcessedTableManager get eggsRefs {
    final manager = $$EggsTableTableManager($_db, $_db.eggs).filter(
        (f) => f.breedingRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eggsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MatingEventsTable, List<MatingEvent>>
      _matingEventsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.matingEvents,
              aliasName: $_aliasNameGenerator(
                  db.breedingRecords.id, db.matingEvents.breedingRecordId));

  $$MatingEventsTableProcessedTableManager get matingEventsRefs {
    final manager = $$MatingEventsTableTableManager($_db, $_db.matingEvents)
        .filter(
            (f) => f.breedingRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_matingEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BreedingRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $BreedingRecordsTable> {
  $$BreedingRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endReason => $composableBuilder(
      column: $table.endReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$BreedingPairsTableFilterComposer get pairId {
    final $$BreedingPairsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pairId,
        referencedTable: $db.breedingPairs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingPairsTableFilterComposer(
              $db: $db,
              $table: $db.breedingPairs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> eggsRefs(
      Expression<bool> Function($$EggsTableFilterComposer f) f) {
    final $$EggsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.eggs,
        getReferencedColumn: (t) => t.breedingRecordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EggsTableFilterComposer(
              $db: $db,
              $table: $db.eggs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> matingEventsRefs(
      Expression<bool> Function($$MatingEventsTableFilterComposer f) f) {
    final $$MatingEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.matingEvents,
        getReferencedColumn: (t) => t.breedingRecordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MatingEventsTableFilterComposer(
              $db: $db,
              $table: $db.matingEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BreedingRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $BreedingRecordsTable> {
  $$BreedingRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endReason => $composableBuilder(
      column: $table.endReason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$BreedingPairsTableOrderingComposer get pairId {
    final $$BreedingPairsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pairId,
        referencedTable: $db.breedingPairs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingPairsTableOrderingComposer(
              $db: $db,
              $table: $db.breedingPairs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BreedingRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BreedingRecordsTable> {
  $$BreedingRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get endReason =>
      $composableBuilder(column: $table.endReason, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BreedingPairsTableAnnotationComposer get pairId {
    final $$BreedingPairsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pairId,
        referencedTable: $db.breedingPairs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingPairsTableAnnotationComposer(
              $db: $db,
              $table: $db.breedingPairs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> eggsRefs<T extends Object>(
      Expression<T> Function($$EggsTableAnnotationComposer a) f) {
    final $$EggsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.eggs,
        getReferencedColumn: (t) => t.breedingRecordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EggsTableAnnotationComposer(
              $db: $db,
              $table: $db.eggs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> matingEventsRefs<T extends Object>(
      Expression<T> Function($$MatingEventsTableAnnotationComposer a) f) {
    final $$MatingEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.matingEvents,
        getReferencedColumn: (t) => t.breedingRecordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MatingEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.matingEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BreedingRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BreedingRecordsTable,
    BreedingRecord,
    $$BreedingRecordsTableFilterComposer,
    $$BreedingRecordsTableOrderingComposer,
    $$BreedingRecordsTableAnnotationComposer,
    $$BreedingRecordsTableCreateCompanionBuilder,
    $$BreedingRecordsTableUpdateCompanionBuilder,
    (BreedingRecord, $$BreedingRecordsTableReferences),
    BreedingRecord,
    PrefetchHooks Function(
        {bool pairId, bool eggsRefs, bool matingEventsRefs})> {
  $$BreedingRecordsTableTableManager(
      _$AppDatabase db, $BreedingRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BreedingRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BreedingRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BreedingRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> pairId = const Value.absent(),
            Value<String> stage = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String?> endReason = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BreedingRecordsCompanion(
            id: id,
            uuid: uuid,
            pairId: pairId,
            stage: stage,
            startDate: startDate,
            endDate: endDate,
            endReason: endReason,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int pairId,
            Value<String> stage = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String?> endReason = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BreedingRecordsCompanion.insert(
            id: id,
            uuid: uuid,
            pairId: pairId,
            stage: stage,
            startDate: startDate,
            endDate: endDate,
            endReason: endReason,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BreedingRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {pairId = false, eggsRefs = false, matingEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (eggsRefs) db.eggs,
                if (matingEventsRefs) db.matingEvents
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (pairId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pairId,
                    referencedTable:
                        $$BreedingRecordsTableReferences._pairIdTable(db),
                    referencedColumn:
                        $$BreedingRecordsTableReferences._pairIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eggsRefs)
                    await $_getPrefetchedData<BreedingRecord,
                            $BreedingRecordsTable, Egg>(
                        currentTable: table,
                        referencedTable:
                            $$BreedingRecordsTableReferences._eggsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BreedingRecordsTableReferences(db, table, p0)
                                .eggsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.breedingRecordId == item.id),
                        typedResults: items),
                  if (matingEventsRefs)
                    await $_getPrefetchedData<BreedingRecord,
                            $BreedingRecordsTable, MatingEvent>(
                        currentTable: table,
                        referencedTable: $$BreedingRecordsTableReferences
                            ._matingEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BreedingRecordsTableReferences(db, table, p0)
                                .matingEventsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.breedingRecordId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BreedingRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BreedingRecordsTable,
    BreedingRecord,
    $$BreedingRecordsTableFilterComposer,
    $$BreedingRecordsTableOrderingComposer,
    $$BreedingRecordsTableAnnotationComposer,
    $$BreedingRecordsTableCreateCompanionBuilder,
    $$BreedingRecordsTableUpdateCompanionBuilder,
    (BreedingRecord, $$BreedingRecordsTableReferences),
    BreedingRecord,
    PrefetchHooks Function(
        {bool pairId, bool eggsRefs, bool matingEventsRefs})>;
typedef $$EggsTableCreateCompanionBuilder = EggsCompanion Function({
  Value<int> id,
  required String uuid,
  required int breedingRecordId,
  required DateTime laidDate,
  Value<DateTime?> hatchDate,
  Value<String> status,
  Value<int?> chickBirdId,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$EggsTableUpdateCompanionBuilder = EggsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> breedingRecordId,
  Value<DateTime> laidDate,
  Value<DateTime?> hatchDate,
  Value<String> status,
  Value<int?> chickBirdId,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$EggsTableReferences
    extends BaseReferences<_$AppDatabase, $EggsTable, Egg> {
  $$EggsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BreedingRecordsTable _breedingRecordIdTable(_$AppDatabase db) =>
      db.breedingRecords.createAlias($_aliasNameGenerator(
          db.eggs.breedingRecordId, db.breedingRecords.id));

  $$BreedingRecordsTableProcessedTableManager get breedingRecordId {
    final $_column = $_itemColumn<int>('breeding_record_id')!;

    final manager =
        $$BreedingRecordsTableTableManager($_db, $_db.breedingRecords)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_breedingRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BirdsTable _chickBirdIdTable(_$AppDatabase db) => db.birds
      .createAlias($_aliasNameGenerator(db.eggs.chickBirdId, db.birds.id));

  $$BirdsTableProcessedTableManager? get chickBirdId {
    final $_column = $_itemColumn<int>('chick_bird_id');
    if ($_column == null) return null;
    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chickBirdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EggsTableFilterComposer extends Composer<_$AppDatabase, $EggsTable> {
  $$EggsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get laidDate => $composableBuilder(
      column: $table.laidDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get hatchDate => $composableBuilder(
      column: $table.hatchDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$BreedingRecordsTableFilterComposer get breedingRecordId {
    final $$BreedingRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.breedingRecordId,
        referencedTable: $db.breedingRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingRecordsTableFilterComposer(
              $db: $db,
              $table: $db.breedingRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BirdsTableFilterComposer get chickBirdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chickBirdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EggsTableOrderingComposer extends Composer<_$AppDatabase, $EggsTable> {
  $$EggsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get laidDate => $composableBuilder(
      column: $table.laidDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get hatchDate => $composableBuilder(
      column: $table.hatchDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$BreedingRecordsTableOrderingComposer get breedingRecordId {
    final $$BreedingRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.breedingRecordId,
        referencedTable: $db.breedingRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.breedingRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BirdsTableOrderingComposer get chickBirdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chickBirdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EggsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EggsTable> {
  $$EggsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<DateTime> get laidDate =>
      $composableBuilder(column: $table.laidDate, builder: (column) => column);

  GeneratedColumn<DateTime> get hatchDate =>
      $composableBuilder(column: $table.hatchDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BreedingRecordsTableAnnotationComposer get breedingRecordId {
    final $$BreedingRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.breedingRecordId,
        referencedTable: $db.breedingRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.breedingRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BirdsTableAnnotationComposer get chickBirdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chickBirdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EggsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EggsTable,
    Egg,
    $$EggsTableFilterComposer,
    $$EggsTableOrderingComposer,
    $$EggsTableAnnotationComposer,
    $$EggsTableCreateCompanionBuilder,
    $$EggsTableUpdateCompanionBuilder,
    (Egg, $$EggsTableReferences),
    Egg,
    PrefetchHooks Function({bool breedingRecordId, bool chickBirdId})> {
  $$EggsTableTableManager(_$AppDatabase db, $EggsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EggsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EggsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EggsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> breedingRecordId = const Value.absent(),
            Value<DateTime> laidDate = const Value.absent(),
            Value<DateTime?> hatchDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> chickBirdId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EggsCompanion(
            id: id,
            uuid: uuid,
            breedingRecordId: breedingRecordId,
            laidDate: laidDate,
            hatchDate: hatchDate,
            status: status,
            chickBirdId: chickBirdId,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int breedingRecordId,
            required DateTime laidDate,
            Value<DateTime?> hatchDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> chickBirdId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EggsCompanion.insert(
            id: id,
            uuid: uuid,
            breedingRecordId: breedingRecordId,
            laidDate: laidDate,
            hatchDate: hatchDate,
            status: status,
            chickBirdId: chickBirdId,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EggsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {breedingRecordId = false, chickBirdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (breedingRecordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.breedingRecordId,
                    referencedTable:
                        $$EggsTableReferences._breedingRecordIdTable(db),
                    referencedColumn:
                        $$EggsTableReferences._breedingRecordIdTable(db).id,
                  ) as T;
                }
                if (chickBirdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.chickBirdId,
                    referencedTable:
                        $$EggsTableReferences._chickBirdIdTable(db),
                    referencedColumn:
                        $$EggsTableReferences._chickBirdIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EggsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EggsTable,
    Egg,
    $$EggsTableFilterComposer,
    $$EggsTableOrderingComposer,
    $$EggsTableAnnotationComposer,
    $$EggsTableCreateCompanionBuilder,
    $$EggsTableUpdateCompanionBuilder,
    (Egg, $$EggsTableReferences),
    Egg,
    PrefetchHooks Function({bool breedingRecordId, bool chickBirdId})>;
typedef $$MatingEventsTableCreateCompanionBuilder = MatingEventsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required int breedingRecordId,
  required DateTime observedDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
});
typedef $$MatingEventsTableUpdateCompanionBuilder = MatingEventsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> breedingRecordId,
  Value<DateTime> observedDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

final class $$MatingEventsTableReferences
    extends BaseReferences<_$AppDatabase, $MatingEventsTable, MatingEvent> {
  $$MatingEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BreedingRecordsTable _breedingRecordIdTable(_$AppDatabase db) =>
      db.breedingRecords.createAlias($_aliasNameGenerator(
          db.matingEvents.breedingRecordId, db.breedingRecords.id));

  $$BreedingRecordsTableProcessedTableManager get breedingRecordId {
    final $_column = $_itemColumn<int>('breeding_record_id')!;

    final manager =
        $$BreedingRecordsTableTableManager($_db, $_db.breedingRecords)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_breedingRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MatingEventsTableFilterComposer
    extends Composer<_$AppDatabase, $MatingEventsTable> {
  $$MatingEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get observedDate => $composableBuilder(
      column: $table.observedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$BreedingRecordsTableFilterComposer get breedingRecordId {
    final $$BreedingRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.breedingRecordId,
        referencedTable: $db.breedingRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingRecordsTableFilterComposer(
              $db: $db,
              $table: $db.breedingRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MatingEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $MatingEventsTable> {
  $$MatingEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get observedDate => $composableBuilder(
      column: $table.observedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$BreedingRecordsTableOrderingComposer get breedingRecordId {
    final $$BreedingRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.breedingRecordId,
        referencedTable: $db.breedingRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.breedingRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MatingEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatingEventsTable> {
  $$MatingEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<DateTime> get observedDate => $composableBuilder(
      column: $table.observedDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BreedingRecordsTableAnnotationComposer get breedingRecordId {
    final $$BreedingRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.breedingRecordId,
        referencedTable: $db.breedingRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BreedingRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.breedingRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MatingEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MatingEventsTable,
    MatingEvent,
    $$MatingEventsTableFilterComposer,
    $$MatingEventsTableOrderingComposer,
    $$MatingEventsTableAnnotationComposer,
    $$MatingEventsTableCreateCompanionBuilder,
    $$MatingEventsTableUpdateCompanionBuilder,
    (MatingEvent, $$MatingEventsTableReferences),
    MatingEvent,
    PrefetchHooks Function({bool breedingRecordId})> {
  $$MatingEventsTableTableManager(_$AppDatabase db, $MatingEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatingEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatingEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatingEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> breedingRecordId = const Value.absent(),
            Value<DateTime> observedDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MatingEventsCompanion(
            id: id,
            uuid: uuid,
            breedingRecordId: breedingRecordId,
            observedDate: observedDate,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int breedingRecordId,
            required DateTime observedDate,
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MatingEventsCompanion.insert(
            id: id,
            uuid: uuid,
            breedingRecordId: breedingRecordId,
            observedDate: observedDate,
            notes: notes,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MatingEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({breedingRecordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (breedingRecordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.breedingRecordId,
                    referencedTable: $$MatingEventsTableReferences
                        ._breedingRecordIdTable(db),
                    referencedColumn: $$MatingEventsTableReferences
                        ._breedingRecordIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MatingEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MatingEventsTable,
    MatingEvent,
    $$MatingEventsTableFilterComposer,
    $$MatingEventsTableOrderingComposer,
    $$MatingEventsTableAnnotationComposer,
    $$MatingEventsTableCreateCompanionBuilder,
    $$MatingEventsTableUpdateCompanionBuilder,
    (MatingEvent, $$MatingEventsTableReferences),
    MatingEvent,
    PrefetchHooks Function({bool breedingRecordId})>;
typedef $$ActivityLogsTableCreateCompanionBuilder = ActivityLogsCompanion
    Function({
  Value<int> id,
  required String uuid,
  Value<int?> birdId,
  required String pluginId,
  required String actionType,
  required String summary,
  Value<String?> details,
  Value<int?> relatedTaskId,
  Value<int?> operatedBy,
  Value<DateTime> operatedAt,
  Value<DateTime> createdAt,
});
typedef $$ActivityLogsTableUpdateCompanionBuilder = ActivityLogsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<int?> birdId,
  Value<String> pluginId,
  Value<String> actionType,
  Value<String> summary,
  Value<String?> details,
  Value<int?> relatedTaskId,
  Value<int?> operatedBy,
  Value<DateTime> operatedAt,
  Value<DateTime> createdAt,
});

final class $$ActivityLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ActivityLogsTable, ActivityLog> {
  $$ActivityLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BirdsTable _birdIdTable(_$AppDatabase db) => db.birds
      .createAlias($_aliasNameGenerator(db.activityLogs.birdId, db.birds.id));

  $$BirdsTableProcessedTableManager? get birdId {
    final $_column = $_itemColumn<int>('bird_id');
    if ($_column == null) return null;
    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_birdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TasksTable _relatedTaskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias(
          $_aliasNameGenerator(db.activityLogs.relatedTaskId, db.tasks.id));

  $$TasksTableProcessedTableManager? get relatedTaskId {
    final $_column = $_itemColumn<int>('related_task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_relatedTaskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _operatedByTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.activityLogs.operatedBy, db.users.id));

  $$UsersTableProcessedTableManager? get operatedBy {
    final $_column = $_itemColumn<int>('operated_by');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operatedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ActivityLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityLogsTable> {
  $$ActivityLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pluginId => $composableBuilder(
      column: $table.pluginId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get details => $composableBuilder(
      column: $table.details, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get operatedAt => $composableBuilder(
      column: $table.operatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$BirdsTableFilterComposer get birdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TasksTableFilterComposer get relatedTaskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.relatedTaskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableFilterComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get operatedBy {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.operatedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActivityLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityLogsTable> {
  $$ActivityLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pluginId => $composableBuilder(
      column: $table.pluginId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get details => $composableBuilder(
      column: $table.details, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get operatedAt => $composableBuilder(
      column: $table.operatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$BirdsTableOrderingComposer get birdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TasksTableOrderingComposer get relatedTaskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.relatedTaskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableOrderingComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get operatedBy {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.operatedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActivityLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityLogsTable> {
  $$ActivityLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get pluginId =>
      $composableBuilder(column: $table.pluginId, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<DateTime> get operatedAt => $composableBuilder(
      column: $table.operatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BirdsTableAnnotationComposer get birdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TasksTableAnnotationComposer get relatedTaskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.relatedTaskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableAnnotationComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get operatedBy {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.operatedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActivityLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActivityLogsTable,
    ActivityLog,
    $$ActivityLogsTableFilterComposer,
    $$ActivityLogsTableOrderingComposer,
    $$ActivityLogsTableAnnotationComposer,
    $$ActivityLogsTableCreateCompanionBuilder,
    $$ActivityLogsTableUpdateCompanionBuilder,
    (ActivityLog, $$ActivityLogsTableReferences),
    ActivityLog,
    PrefetchHooks Function(
        {bool birdId, bool relatedTaskId, bool operatedBy})> {
  $$ActivityLogsTableTableManager(_$AppDatabase db, $ActivityLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int?> birdId = const Value.absent(),
            Value<String> pluginId = const Value.absent(),
            Value<String> actionType = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String?> details = const Value.absent(),
            Value<int?> relatedTaskId = const Value.absent(),
            Value<int?> operatedBy = const Value.absent(),
            Value<DateTime> operatedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ActivityLogsCompanion(
            id: id,
            uuid: uuid,
            birdId: birdId,
            pluginId: pluginId,
            actionType: actionType,
            summary: summary,
            details: details,
            relatedTaskId: relatedTaskId,
            operatedBy: operatedBy,
            operatedAt: operatedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            Value<int?> birdId = const Value.absent(),
            required String pluginId,
            required String actionType,
            required String summary,
            Value<String?> details = const Value.absent(),
            Value<int?> relatedTaskId = const Value.absent(),
            Value<int?> operatedBy = const Value.absent(),
            Value<DateTime> operatedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ActivityLogsCompanion.insert(
            id: id,
            uuid: uuid,
            birdId: birdId,
            pluginId: pluginId,
            actionType: actionType,
            summary: summary,
            details: details,
            relatedTaskId: relatedTaskId,
            operatedBy: operatedBy,
            operatedAt: operatedAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ActivityLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {birdId = false, relatedTaskId = false, operatedBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (birdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.birdId,
                    referencedTable:
                        $$ActivityLogsTableReferences._birdIdTable(db),
                    referencedColumn:
                        $$ActivityLogsTableReferences._birdIdTable(db).id,
                  ) as T;
                }
                if (relatedTaskId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.relatedTaskId,
                    referencedTable:
                        $$ActivityLogsTableReferences._relatedTaskIdTable(db),
                    referencedColumn: $$ActivityLogsTableReferences
                        ._relatedTaskIdTable(db)
                        .id,
                  ) as T;
                }
                if (operatedBy) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.operatedBy,
                    referencedTable:
                        $$ActivityLogsTableReferences._operatedByTable(db),
                    referencedColumn:
                        $$ActivityLogsTableReferences._operatedByTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ActivityLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActivityLogsTable,
    ActivityLog,
    $$ActivityLogsTableFilterComposer,
    $$ActivityLogsTableOrderingComposer,
    $$ActivityLogsTableAnnotationComposer,
    $$ActivityLogsTableCreateCompanionBuilder,
    $$ActivityLogsTableUpdateCompanionBuilder,
    (ActivityLog, $$ActivityLogsTableReferences),
    ActivityLog,
    PrefetchHooks Function({bool birdId, bool relatedTaskId, bool operatedBy})>;
typedef $$BirdPhotosTableCreateCompanionBuilder = BirdPhotosCompanion Function({
  Value<int> id,
  required int birdId,
  required String filePath,
  Value<int> sortOrder,
  Value<String> mediaType,
  Value<String?> videoFilePath,
  Value<String?> thumbnailPath,
  Value<DateTime> createdAt,
});
typedef $$BirdPhotosTableUpdateCompanionBuilder = BirdPhotosCompanion Function({
  Value<int> id,
  Value<int> birdId,
  Value<String> filePath,
  Value<int> sortOrder,
  Value<String> mediaType,
  Value<String?> videoFilePath,
  Value<String?> thumbnailPath,
  Value<DateTime> createdAt,
});

final class $$BirdPhotosTableReferences
    extends BaseReferences<_$AppDatabase, $BirdPhotosTable, BirdPhoto> {
  $$BirdPhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BirdsTable _birdIdTable(_$AppDatabase db) => db.birds
      .createAlias($_aliasNameGenerator(db.birdPhotos.birdId, db.birds.id));

  $$BirdsTableProcessedTableManager get birdId {
    final $_column = $_itemColumn<int>('bird_id')!;

    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_birdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BirdPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $BirdPhotosTable> {
  $$BirdPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get videoFilePath => $composableBuilder(
      column: $table.videoFilePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$BirdsTableFilterComposer get birdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BirdPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $BirdPhotosTable> {
  $$BirdPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get videoFilePath => $composableBuilder(
      column: $table.videoFilePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$BirdsTableOrderingComposer get birdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BirdPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $BirdPhotosTable> {
  $$BirdPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get videoFilePath => $composableBuilder(
      column: $table.videoFilePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BirdsTableAnnotationComposer get birdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BirdPhotosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BirdPhotosTable,
    BirdPhoto,
    $$BirdPhotosTableFilterComposer,
    $$BirdPhotosTableOrderingComposer,
    $$BirdPhotosTableAnnotationComposer,
    $$BirdPhotosTableCreateCompanionBuilder,
    $$BirdPhotosTableUpdateCompanionBuilder,
    (BirdPhoto, $$BirdPhotosTableReferences),
    BirdPhoto,
    PrefetchHooks Function({bool birdId})> {
  $$BirdPhotosTableTableManager(_$AppDatabase db, $BirdPhotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BirdPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BirdPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BirdPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> birdId = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String?> videoFilePath = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BirdPhotosCompanion(
            id: id,
            birdId: birdId,
            filePath: filePath,
            sortOrder: sortOrder,
            mediaType: mediaType,
            videoFilePath: videoFilePath,
            thumbnailPath: thumbnailPath,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int birdId,
            required String filePath,
            Value<int> sortOrder = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String?> videoFilePath = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BirdPhotosCompanion.insert(
            id: id,
            birdId: birdId,
            filePath: filePath,
            sortOrder: sortOrder,
            mediaType: mediaType,
            videoFilePath: videoFilePath,
            thumbnailPath: thumbnailPath,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BirdPhotosTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({birdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (birdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.birdId,
                    referencedTable:
                        $$BirdPhotosTableReferences._birdIdTable(db),
                    referencedColumn:
                        $$BirdPhotosTableReferences._birdIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BirdPhotosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BirdPhotosTable,
    BirdPhoto,
    $$BirdPhotosTableFilterComposer,
    $$BirdPhotosTableOrderingComposer,
    $$BirdPhotosTableAnnotationComposer,
    $$BirdPhotosTableCreateCompanionBuilder,
    $$BirdPhotosTableUpdateCompanionBuilder,
    (BirdPhoto, $$BirdPhotosTableReferences),
    BirdPhoto,
    PrefetchHooks Function({bool birdId})>;
typedef $$BirdAvatarsTableCreateCompanionBuilder = BirdAvatarsCompanion
    Function({
  Value<int> id,
  required int birdId,
  required String filePath,
  Value<DateTime> updatedAt,
});
typedef $$BirdAvatarsTableUpdateCompanionBuilder = BirdAvatarsCompanion
    Function({
  Value<int> id,
  Value<int> birdId,
  Value<String> filePath,
  Value<DateTime> updatedAt,
});

final class $$BirdAvatarsTableReferences
    extends BaseReferences<_$AppDatabase, $BirdAvatarsTable, BirdAvatar> {
  $$BirdAvatarsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BirdsTable _birdIdTable(_$AppDatabase db) => db.birds
      .createAlias($_aliasNameGenerator(db.birdAvatars.birdId, db.birds.id));

  $$BirdsTableProcessedTableManager get birdId {
    final $_column = $_itemColumn<int>('bird_id')!;

    final manager = $$BirdsTableTableManager($_db, $_db.birds)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_birdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BirdAvatarsTableFilterComposer
    extends Composer<_$AppDatabase, $BirdAvatarsTable> {
  $$BirdAvatarsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$BirdsTableFilterComposer get birdId {
    final $$BirdsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableFilterComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BirdAvatarsTableOrderingComposer
    extends Composer<_$AppDatabase, $BirdAvatarsTable> {
  $$BirdAvatarsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$BirdsTableOrderingComposer get birdId {
    final $$BirdsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableOrderingComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BirdAvatarsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BirdAvatarsTable> {
  $$BirdAvatarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BirdsTableAnnotationComposer get birdId {
    final $$BirdsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.birdId,
        referencedTable: $db.birds,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BirdsTableAnnotationComposer(
              $db: $db,
              $table: $db.birds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BirdAvatarsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BirdAvatarsTable,
    BirdAvatar,
    $$BirdAvatarsTableFilterComposer,
    $$BirdAvatarsTableOrderingComposer,
    $$BirdAvatarsTableAnnotationComposer,
    $$BirdAvatarsTableCreateCompanionBuilder,
    $$BirdAvatarsTableUpdateCompanionBuilder,
    (BirdAvatar, $$BirdAvatarsTableReferences),
    BirdAvatar,
    PrefetchHooks Function({bool birdId})> {
  $$BirdAvatarsTableTableManager(_$AppDatabase db, $BirdAvatarsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BirdAvatarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BirdAvatarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BirdAvatarsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> birdId = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BirdAvatarsCompanion(
            id: id,
            birdId: birdId,
            filePath: filePath,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int birdId,
            required String filePath,
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BirdAvatarsCompanion.insert(
            id: id,
            birdId: birdId,
            filePath: filePath,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BirdAvatarsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({birdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (birdId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.birdId,
                    referencedTable:
                        $$BirdAvatarsTableReferences._birdIdTable(db),
                    referencedColumn:
                        $$BirdAvatarsTableReferences._birdIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BirdAvatarsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BirdAvatarsTable,
    BirdAvatar,
    $$BirdAvatarsTableFilterComposer,
    $$BirdAvatarsTableOrderingComposer,
    $$BirdAvatarsTableAnnotationComposer,
    $$BirdAvatarsTableCreateCompanionBuilder,
    $$BirdAvatarsTableUpdateCompanionBuilder,
    (BirdAvatar, $$BirdAvatarsTableReferences),
    BirdAvatar,
    PrefetchHooks Function({bool birdId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SpeciesTableTableManager get species =>
      $$SpeciesTableTableManager(_db, _db.species);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db, _db.rooms);
  $$EnclosuresTableTableManager get enclosures =>
      $$EnclosuresTableTableManager(_db, _db.enclosures);
  $$BirdsTableTableManager get birds =>
      $$BirdsTableTableManager(_db, _db.birds);
  $$WeightsTableTableManager get weights =>
      $$WeightsTableTableManager(_db, _db.weights);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$AlertRecordsTableTableManager get alertRecords =>
      $$AlertRecordsTableTableManager(_db, _db.alertRecords);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$BreedingPairsTableTableManager get breedingPairs =>
      $$BreedingPairsTableTableManager(_db, _db.breedingPairs);
  $$BreedingRecordsTableTableManager get breedingRecords =>
      $$BreedingRecordsTableTableManager(_db, _db.breedingRecords);
  $$EggsTableTableManager get eggs => $$EggsTableTableManager(_db, _db.eggs);
  $$MatingEventsTableTableManager get matingEvents =>
      $$MatingEventsTableTableManager(_db, _db.matingEvents);
  $$ActivityLogsTableTableManager get activityLogs =>
      $$ActivityLogsTableTableManager(_db, _db.activityLogs);
  $$BirdPhotosTableTableManager get birdPhotos =>
      $$BirdPhotosTableTableManager(_db, _db.birdPhotos);
  $$BirdAvatarsTableTableManager get birdAvatars =>
      $$BirdAvatarsTableTableManager(_db, _db.birdAvatars);
}
