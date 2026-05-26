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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        nestlingEndDays,
        juvenileEndDays,
        adultWeighIntervalDays,
        createdAt
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
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      nestlingEndDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}nestling_end_days'])!,
      juvenileEndDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}juvenile_end_days'])!,
      adultWeighIntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}adult_weigh_interval_days'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SpeciesTable createAlias(String alias) {
    return $SpeciesTable(attachedDatabase, alias);
  }
}

class Specy extends DataClass implements Insertable<Specy> {
  final int id;
  final String name;

  /// 雏鸟阶段结束天数
  final int nestlingEndDays;

  /// 幼鸟阶段结束天数
  final int juvenileEndDays;

  /// 称重周期（天），成鸟用
  final int adultWeighIntervalDays;
  final DateTime createdAt;
  const Specy(
      {required this.id,
      required this.name,
      required this.nestlingEndDays,
      required this.juvenileEndDays,
      required this.adultWeighIntervalDays,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['nestling_end_days'] = Variable<int>(nestlingEndDays);
    map['juvenile_end_days'] = Variable<int>(juvenileEndDays);
    map['adult_weigh_interval_days'] = Variable<int>(adultWeighIntervalDays);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SpeciesCompanion toCompanion(bool nullToAbsent) {
    return SpeciesCompanion(
      id: Value(id),
      name: Value(name),
      nestlingEndDays: Value(nestlingEndDays),
      juvenileEndDays: Value(juvenileEndDays),
      adultWeighIntervalDays: Value(adultWeighIntervalDays),
      createdAt: Value(createdAt),
    );
  }

  factory Specy.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Specy(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nestlingEndDays: serializer.fromJson<int>(json['nestlingEndDays']),
      juvenileEndDays: serializer.fromJson<int>(json['juvenileEndDays']),
      adultWeighIntervalDays:
          serializer.fromJson<int>(json['adultWeighIntervalDays']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nestlingEndDays': serializer.toJson<int>(nestlingEndDays),
      'juvenileEndDays': serializer.toJson<int>(juvenileEndDays),
      'adultWeighIntervalDays': serializer.toJson<int>(adultWeighIntervalDays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Specy copyWith(
          {int? id,
          String? name,
          int? nestlingEndDays,
          int? juvenileEndDays,
          int? adultWeighIntervalDays,
          DateTime? createdAt}) =>
      Specy(
        id: id ?? this.id,
        name: name ?? this.name,
        nestlingEndDays: nestlingEndDays ?? this.nestlingEndDays,
        juvenileEndDays: juvenileEndDays ?? this.juvenileEndDays,
        adultWeighIntervalDays:
            adultWeighIntervalDays ?? this.adultWeighIntervalDays,
        createdAt: createdAt ?? this.createdAt,
      );
  Specy copyWithCompanion(SpeciesCompanion data) {
    return Specy(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nestlingEndDays: data.nestlingEndDays.present
          ? data.nestlingEndDays.value
          : this.nestlingEndDays,
      juvenileEndDays: data.juvenileEndDays.present
          ? data.juvenileEndDays.value
          : this.juvenileEndDays,
      adultWeighIntervalDays: data.adultWeighIntervalDays.present
          ? data.adultWeighIntervalDays.value
          : this.adultWeighIntervalDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Specy(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nestlingEndDays: $nestlingEndDays, ')
          ..write('juvenileEndDays: $juvenileEndDays, ')
          ..write('adultWeighIntervalDays: $adultWeighIntervalDays, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, nestlingEndDays, juvenileEndDays,
      adultWeighIntervalDays, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Specy &&
          other.id == this.id &&
          other.name == this.name &&
          other.nestlingEndDays == this.nestlingEndDays &&
          other.juvenileEndDays == this.juvenileEndDays &&
          other.adultWeighIntervalDays == this.adultWeighIntervalDays &&
          other.createdAt == this.createdAt);
}

class SpeciesCompanion extends UpdateCompanion<Specy> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> nestlingEndDays;
  final Value<int> juvenileEndDays;
  final Value<int> adultWeighIntervalDays;
  final Value<DateTime> createdAt;
  const SpeciesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nestlingEndDays = const Value.absent(),
    this.juvenileEndDays = const Value.absent(),
    this.adultWeighIntervalDays = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SpeciesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.nestlingEndDays = const Value.absent(),
    this.juvenileEndDays = const Value.absent(),
    this.adultWeighIntervalDays = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Specy> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? nestlingEndDays,
    Expression<int>? juvenileEndDays,
    Expression<int>? adultWeighIntervalDays,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nestlingEndDays != null) 'nestling_end_days': nestlingEndDays,
      if (juvenileEndDays != null) 'juvenile_end_days': juvenileEndDays,
      if (adultWeighIntervalDays != null)
        'adult_weigh_interval_days': adultWeighIntervalDays,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SpeciesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? nestlingEndDays,
      Value<int>? juvenileEndDays,
      Value<int>? adultWeighIntervalDays,
      Value<DateTime>? createdAt}) {
    return SpeciesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nestlingEndDays: nestlingEndDays ?? this.nestlingEndDays,
      juvenileEndDays: juvenileEndDays ?? this.juvenileEndDays,
      adultWeighIntervalDays:
          adultWeighIntervalDays ?? this.adultWeighIntervalDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    if (adultWeighIntervalDays.present) {
      map['adult_weigh_interval_days'] =
          Variable<int>(adultWeighIntervalDays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nestlingEndDays: $nestlingEndDays, ')
          ..write('juvenileEndDays: $juvenileEndDays, ')
          ..write('adultWeighIntervalDays: $adultWeighIntervalDays, ')
          ..write('createdAt: $createdAt')
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
  @override
  List<GeneratedColumn> get $columns =>
      [id, username, displayName, passwordHash, role, createdAt];
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
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String username;
  final String displayName;
  final String passwordHash;
  final String role;
  final DateTime createdAt;
  const User(
      {required this.id,
      required this.username,
      required this.displayName,
      required this.passwordHash,
      required this.role,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['display_name'] = Variable<String>(displayName);
    map['password_hash'] = Variable<String>(passwordHash);
    map['role'] = Variable<String>(role);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      displayName: Value(displayName),
      passwordHash: Value(passwordHash),
      role: Value(role),
      createdAt: Value(createdAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String>(json['displayName']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      role: serializer.fromJson<String>(json['role']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String>(displayName),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'role': serializer.toJson<String>(role),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  User copyWith(
          {int? id,
          String? username,
          String? displayName,
          String? passwordHash,
          String? role,
          DateTime? createdAt}) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      role: data.role.present ? data.role.value : this.role,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, username, displayName, passwordHash, role, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.passwordHash == this.passwordHash &&
          other.role == this.role &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> displayName;
  final Value<String> passwordHash;
  final Value<String> role;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String displayName,
    required String passwordHash,
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : username = Value(username),
        displayName = Value(displayName),
        passwordHash = Value(passwordHash);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? passwordHash,
    Expression<String>? role,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? username,
      Value<String>? displayName,
      Value<String>? passwordHash,
      Value<String>? role,
      Value<DateTime>? createdAt}) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt')
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
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, sortOrder, assignedUserId, createdAt];
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
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      assignedUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}assigned_user_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class Room extends DataClass implements Insertable<Room> {
  final int id;
  final String name;

  /// 排序序号
  final int sortOrder;

  /// 负责该房间的用户 ID
  final int? assignedUserId;
  final DateTime createdAt;
  const Room(
      {required this.id,
      required this.name,
      required this.sortOrder,
      this.assignedUserId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || assignedUserId != null) {
      map['assigned_user_id'] = Variable<int>(assignedUserId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      assignedUserId: assignedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedUserId),
      createdAt: Value(createdAt),
    );
  }

  factory Room.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Room(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      assignedUserId: serializer.fromJson<int?>(json['assignedUserId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'assignedUserId': serializer.toJson<int?>(assignedUserId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Room copyWith(
          {int? id,
          String? name,
          int? sortOrder,
          Value<int?> assignedUserId = const Value.absent(),
          DateTime? createdAt}) =>
      Room(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        assignedUserId:
            assignedUserId.present ? assignedUserId.value : this.assignedUserId,
        createdAt: createdAt ?? this.createdAt,
      );
  Room copyWithCompanion(RoomsCompanion data) {
    return Room(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      assignedUserId: data.assignedUserId.present
          ? data.assignedUserId.value
          : this.assignedUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Room(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, sortOrder, assignedUserId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Room &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.assignedUserId == this.assignedUserId &&
          other.createdAt == this.createdAt);
}

class RoomsCompanion extends UpdateCompanion<Room> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int?> assignedUserId;
  final Value<DateTime> createdAt;
  const RoomsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RoomsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Room> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? assignedUserId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (assignedUserId != null) 'assigned_user_id': assignedUserId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RoomsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? sortOrder,
      Value<int?>? assignedUserId,
      Value<DateTime>? createdAt}) {
    return RoomsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('createdAt: $createdAt')
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        ringNumber,
        speciesId,
        roomId,
        birthDate,
        gender,
        sortOrder,
        status,
        notes,
        createdAt,
        updatedAt
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
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      ringNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ring_number']),
      speciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}species_id'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}room_id']),
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birth_date'])!,
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BirdsTable createAlias(String alias) {
    return $BirdsTable(attachedDatabase, alias);
  }
}

class Bird extends DataClass implements Insertable<Bird> {
  final int id;
  final String name;

  /// 脚环号
  final String? ringNumber;

  /// 品种 ID
  final int speciesId;

  /// 所在房间 ID
  final int? roomId;

  /// 出生日期
  final DateTime birthDate;

  /// 性别：公/母/未知
  final String gender;

  /// 自定义排序
  final int sortOrder;

  /// 状态：正常/异常/已离舍
  final String status;

  /// 备注
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Bird(
      {required this.id,
      required this.name,
      this.ringNumber,
      required this.speciesId,
      this.roomId,
      required this.birthDate,
      required this.gender,
      required this.sortOrder,
      required this.status,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || ringNumber != null) {
      map['ring_number'] = Variable<String>(ringNumber);
    }
    map['species_id'] = Variable<int>(speciesId);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<int>(roomId);
    }
    map['birth_date'] = Variable<DateTime>(birthDate);
    map['gender'] = Variable<String>(gender);
    map['sort_order'] = Variable<int>(sortOrder);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BirdsCompanion toCompanion(bool nullToAbsent) {
    return BirdsCompanion(
      id: Value(id),
      name: Value(name),
      ringNumber: ringNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(ringNumber),
      speciesId: Value(speciesId),
      roomId:
          roomId == null && nullToAbsent ? const Value.absent() : Value(roomId),
      birthDate: Value(birthDate),
      gender: Value(gender),
      sortOrder: Value(sortOrder),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Bird.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bird(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ringNumber: serializer.fromJson<String?>(json['ringNumber']),
      speciesId: serializer.fromJson<int>(json['speciesId']),
      roomId: serializer.fromJson<int?>(json['roomId']),
      birthDate: serializer.fromJson<DateTime>(json['birthDate']),
      gender: serializer.fromJson<String>(json['gender']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      status: serializer.fromJson<String>(json['status']),
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
      'name': serializer.toJson<String>(name),
      'ringNumber': serializer.toJson<String?>(ringNumber),
      'speciesId': serializer.toJson<int>(speciesId),
      'roomId': serializer.toJson<int?>(roomId),
      'birthDate': serializer.toJson<DateTime>(birthDate),
      'gender': serializer.toJson<String>(gender),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Bird copyWith(
          {int? id,
          String? name,
          Value<String?> ringNumber = const Value.absent(),
          int? speciesId,
          Value<int?> roomId = const Value.absent(),
          DateTime? birthDate,
          String? gender,
          int? sortOrder,
          String? status,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Bird(
        id: id ?? this.id,
        name: name ?? this.name,
        ringNumber: ringNumber.present ? ringNumber.value : this.ringNumber,
        speciesId: speciesId ?? this.speciesId,
        roomId: roomId.present ? roomId.value : this.roomId,
        birthDate: birthDate ?? this.birthDate,
        gender: gender ?? this.gender,
        sortOrder: sortOrder ?? this.sortOrder,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Bird copyWithCompanion(BirdsCompanion data) {
    return Bird(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ringNumber:
          data.ringNumber.present ? data.ringNumber.value : this.ringNumber,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      gender: data.gender.present ? data.gender.value : this.gender,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bird(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ringNumber: $ringNumber, ')
          ..write('speciesId: $speciesId, ')
          ..write('roomId: $roomId, ')
          ..write('birthDate: $birthDate, ')
          ..write('gender: $gender, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, ringNumber, speciesId, roomId,
      birthDate, gender, sortOrder, status, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bird &&
          other.id == this.id &&
          other.name == this.name &&
          other.ringNumber == this.ringNumber &&
          other.speciesId == this.speciesId &&
          other.roomId == this.roomId &&
          other.birthDate == this.birthDate &&
          other.gender == this.gender &&
          other.sortOrder == this.sortOrder &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BirdsCompanion extends UpdateCompanion<Bird> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> ringNumber;
  final Value<int> speciesId;
  final Value<int?> roomId;
  final Value<DateTime> birthDate;
  final Value<String> gender;
  final Value<int> sortOrder;
  final Value<String> status;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BirdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ringNumber = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.gender = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BirdsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.ringNumber = const Value.absent(),
    required int speciesId,
    this.roomId = const Value.absent(),
    required DateTime birthDate,
    this.gender = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        speciesId = Value(speciesId),
        birthDate = Value(birthDate);
  static Insertable<Bird> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? ringNumber,
    Expression<int>? speciesId,
    Expression<int>? roomId,
    Expression<DateTime>? birthDate,
    Expression<String>? gender,
    Expression<int>? sortOrder,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ringNumber != null) 'ring_number': ringNumber,
      if (speciesId != null) 'species_id': speciesId,
      if (roomId != null) 'room_id': roomId,
      if (birthDate != null) 'birth_date': birthDate,
      if (gender != null) 'gender': gender,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BirdsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? ringNumber,
      Value<int>? speciesId,
      Value<int?>? roomId,
      Value<DateTime>? birthDate,
      Value<String>? gender,
      Value<int>? sortOrder,
      Value<String>? status,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return BirdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ringNumber: ringNumber ?? this.ringNumber,
      speciesId: speciesId ?? this.speciesId,
      roomId: roomId ?? this.roomId,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
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
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BirdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ringNumber: $ringNumber, ')
          ..write('speciesId: $speciesId, ')
          ..write('roomId: $roomId, ')
          ..write('birthDate: $birthDate, ')
          ..write('gender: $gender, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
      defaultValue: const Constant(false));
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        birdId,
        weightG,
        recordedAt,
        recordedBy,
        isFasting,
        notes,
        createdAt
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
    );
  }

  @override
  $WeightsTable createAlias(String alias) {
    return $WeightsTable(attachedDatabase, alias);
  }
}

class Weight extends DataClass implements Insertable<Weight> {
  final int id;

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
  const Weight(
      {required this.id,
      required this.birdId,
      required this.weightG,
      required this.recordedAt,
      this.recordedBy,
      required this.isFasting,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
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
    return map;
  }

  WeightsCompanion toCompanion(bool nullToAbsent) {
    return WeightsCompanion(
      id: Value(id),
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
    );
  }

  factory Weight.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Weight(
      id: serializer.fromJson<int>(json['id']),
      birdId: serializer.fromJson<int>(json['birdId']),
      weightG: serializer.fromJson<double>(json['weightG']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      recordedBy: serializer.fromJson<int?>(json['recordedBy']),
      isFasting: serializer.fromJson<bool>(json['isFasting']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'birdId': serializer.toJson<int>(birdId),
      'weightG': serializer.toJson<double>(weightG),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'recordedBy': serializer.toJson<int?>(recordedBy),
      'isFasting': serializer.toJson<bool>(isFasting),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Weight copyWith(
          {int? id,
          int? birdId,
          double? weightG,
          DateTime? recordedAt,
          Value<int?> recordedBy = const Value.absent(),
          bool? isFasting,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      Weight(
        id: id ?? this.id,
        birdId: birdId ?? this.birdId,
        weightG: weightG ?? this.weightG,
        recordedAt: recordedAt ?? this.recordedAt,
        recordedBy: recordedBy.present ? recordedBy.value : this.recordedBy,
        isFasting: isFasting ?? this.isFasting,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  Weight copyWithCompanion(WeightsCompanion data) {
    return Weight(
      id: data.id.present ? data.id.value : this.id,
      birdId: data.birdId.present ? data.birdId.value : this.birdId,
      weightG: data.weightG.present ? data.weightG.value : this.weightG,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      recordedBy:
          data.recordedBy.present ? data.recordedBy.value : this.recordedBy,
      isFasting: data.isFasting.present ? data.isFasting.value : this.isFasting,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Weight(')
          ..write('id: $id, ')
          ..write('birdId: $birdId, ')
          ..write('weightG: $weightG, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('isFasting: $isFasting, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, birdId, weightG, recordedAt, recordedBy, isFasting, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Weight &&
          other.id == this.id &&
          other.birdId == this.birdId &&
          other.weightG == this.weightG &&
          other.recordedAt == this.recordedAt &&
          other.recordedBy == this.recordedBy &&
          other.isFasting == this.isFasting &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class WeightsCompanion extends UpdateCompanion<Weight> {
  final Value<int> id;
  final Value<int> birdId;
  final Value<double> weightG;
  final Value<DateTime> recordedAt;
  final Value<int?> recordedBy;
  final Value<bool> isFasting;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const WeightsCompanion({
    this.id = const Value.absent(),
    this.birdId = const Value.absent(),
    this.weightG = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.isFasting = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WeightsCompanion.insert({
    this.id = const Value.absent(),
    required int birdId,
    required double weightG,
    required DateTime recordedAt,
    this.recordedBy = const Value.absent(),
    this.isFasting = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : birdId = Value(birdId),
        weightG = Value(weightG),
        recordedAt = Value(recordedAt);
  static Insertable<Weight> custom({
    Expression<int>? id,
    Expression<int>? birdId,
    Expression<double>? weightG,
    Expression<DateTime>? recordedAt,
    Expression<int>? recordedBy,
    Expression<bool>? isFasting,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (birdId != null) 'bird_id': birdId,
      if (weightG != null) 'weight_g': weightG,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (isFasting != null) 'is_fasting': isFasting,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WeightsCompanion copyWith(
      {Value<int>? id,
      Value<int>? birdId,
      Value<double>? weightG,
      Value<DateTime>? recordedAt,
      Value<int?>? recordedBy,
      Value<bool>? isFasting,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return WeightsCompanion(
      id: id ?? this.id,
      birdId: birdId ?? this.birdId,
      weightG: weightG ?? this.weightG,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
      isFasting: isFasting ?? this.isFasting,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightsCompanion(')
          ..write('id: $id, ')
          ..write('birdId: $birdId, ')
          ..write('weightG: $weightG, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('isFasting: $isFasting, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
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
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
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
        roomId,
        assignedUserId,
        dueDate,
        status,
        completedAt,
        completedBy,
        createdAt
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
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    } else if (isInserting) {
      context.missing(_dueDateMeta);
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
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
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
      birdId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bird_id'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}room_id']),
      assignedUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}assigned_user_id']),
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      completedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_by']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;

  /// 鹦鹉 ID
  final int birdId;

  /// 房间 ID（冗余，方便按房间看任务）
  final int? roomId;

  /// 指派人
  final int? assignedUserId;

  /// 任务日期
  final DateTime dueDate;

  /// 任务状态：待完成/已完成/逾期
  final String status;

  /// 完成时间
  final DateTime? completedAt;

  /// 完成人
  final int? completedBy;
  final DateTime createdAt;
  const Task(
      {required this.id,
      required this.birdId,
      this.roomId,
      this.assignedUserId,
      required this.dueDate,
      required this.status,
      this.completedAt,
      this.completedBy,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bird_id'] = Variable<int>(birdId);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<int>(roomId);
    }
    if (!nullToAbsent || assignedUserId != null) {
      map['assigned_user_id'] = Variable<int>(assignedUserId);
    }
    map['due_date'] = Variable<DateTime>(dueDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || completedBy != null) {
      map['completed_by'] = Variable<int>(completedBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      birdId: Value(birdId),
      roomId:
          roomId == null && nullToAbsent ? const Value.absent() : Value(roomId),
      assignedUserId: assignedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedUserId),
      dueDate: Value(dueDate),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completedBy: completedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(completedBy),
      createdAt: Value(createdAt),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      birdId: serializer.fromJson<int>(json['birdId']),
      roomId: serializer.fromJson<int?>(json['roomId']),
      assignedUserId: serializer.fromJson<int?>(json['assignedUserId']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      completedBy: serializer.fromJson<int?>(json['completedBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'birdId': serializer.toJson<int>(birdId),
      'roomId': serializer.toJson<int?>(roomId),
      'assignedUserId': serializer.toJson<int?>(assignedUserId),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'status': serializer.toJson<String>(status),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'completedBy': serializer.toJson<int?>(completedBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Task copyWith(
          {int? id,
          int? birdId,
          Value<int?> roomId = const Value.absent(),
          Value<int?> assignedUserId = const Value.absent(),
          DateTime? dueDate,
          String? status,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<int?> completedBy = const Value.absent(),
          DateTime? createdAt}) =>
      Task(
        id: id ?? this.id,
        birdId: birdId ?? this.birdId,
        roomId: roomId.present ? roomId.value : this.roomId,
        assignedUserId:
            assignedUserId.present ? assignedUserId.value : this.assignedUserId,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        completedBy: completedBy.present ? completedBy.value : this.completedBy,
        createdAt: createdAt ?? this.createdAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      birdId: data.birdId.present ? data.birdId.value : this.birdId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      assignedUserId: data.assignedUserId.present
          ? data.assignedUserId.value
          : this.assignedUserId,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      completedBy:
          data.completedBy.present ? data.completedBy.value : this.completedBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('birdId: $birdId, ')
          ..write('roomId: $roomId, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedBy: $completedBy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, birdId, roomId, assignedUserId, dueDate,
      status, completedAt, completedBy, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.birdId == this.birdId &&
          other.roomId == this.roomId &&
          other.assignedUserId == this.assignedUserId &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.completedBy == this.completedBy &&
          other.createdAt == this.createdAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<int> birdId;
  final Value<int?> roomId;
  final Value<int?> assignedUserId;
  final Value<DateTime> dueDate;
  final Value<String> status;
  final Value<DateTime?> completedAt;
  final Value<int?> completedBy;
  final Value<DateTime> createdAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.birdId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedBy = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required int birdId,
    this.roomId = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    required DateTime dueDate,
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedBy = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : birdId = Value(birdId),
        dueDate = Value(dueDate);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<int>? birdId,
    Expression<int>? roomId,
    Expression<int>? assignedUserId,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<DateTime>? completedAt,
    Expression<int>? completedBy,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (birdId != null) 'bird_id': birdId,
      if (roomId != null) 'room_id': roomId,
      if (assignedUserId != null) 'assigned_user_id': assignedUserId,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (completedBy != null) 'completed_by': completedBy,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TasksCompanion copyWith(
      {Value<int>? id,
      Value<int>? birdId,
      Value<int?>? roomId,
      Value<int?>? assignedUserId,
      Value<DateTime>? dueDate,
      Value<String>? status,
      Value<DateTime?>? completedAt,
      Value<int?>? completedBy,
      Value<DateTime>? createdAt}) {
    return TasksCompanion(
      id: id ?? this.id,
      birdId: birdId ?? this.birdId,
      roomId: roomId ?? this.roomId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
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
    if (roomId.present) {
      map['room_id'] = Variable<int>(roomId.value);
    }
    if (assignedUserId.present) {
      map['assigned_user_id'] = Variable<int>(assignedUserId.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('birdId: $birdId, ')
          ..write('roomId: $roomId, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedBy: $completedBy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncLogTable extends SyncLog with TableInfo<$SyncLogTable, SyncLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entityType, entityId, operation, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log';
  @override
  VerificationContext validateIntegrity(Insertable<SyncLogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $SyncLogTable createAlias(String alias) {
    return $SyncLogTable(attachedDatabase, alias);
  }
}

class SyncLogData extends DataClass implements Insertable<SyncLogData> {
  final int id;

  /// 实体类型
  final String entityType;

  /// 实体 ID
  final int entityId;

  /// 操作类型：create/update/delete
  final String operation;

  /// 同步时间
  final DateTime syncedAt;
  const SyncLogData(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<int>(entityId);
    map['operation'] = Variable<String>(operation);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  SyncLogCompanion toCompanion(bool nullToAbsent) {
    return SyncLogCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      syncedAt: Value(syncedAt),
    );
  }

  factory SyncLogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<int>(entityId),
      'operation': serializer.toJson<String>(operation),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  SyncLogData copyWith(
          {int? id,
          String? entityType,
          int? entityId,
          String? operation,
          DateTime? syncedAt}) =>
      SyncLogData(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  SyncLogData copyWithCompanion(SyncLogCompanion data) {
    return SyncLogData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityType, entityId, operation, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.syncedAt == this.syncedAt);
}

class SyncLogCompanion extends UpdateCompanion<SyncLogData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<int> entityId;
  final Value<String> operation;
  final Value<DateTime> syncedAt;
  const SyncLogCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  SyncLogCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required int entityId,
    required String operation,
    this.syncedAt = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation);
  static Insertable<SyncLogData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<int>? entityId,
    Expression<String>? operation,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  SyncLogCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<int>? entityId,
      Value<String>? operation,
      Value<DateTime>? syncedAt}) {
    return SyncLogCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('syncedAt: $syncedAt')
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
  late final $BirdsTable birds = $BirdsTable(this);
  late final $WeightsTable weights = $WeightsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $SyncLogTable syncLog = $SyncLogTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [species, users, rooms, birds, weights, tasks, syncLog];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
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
        ],
      );
}

typedef $$SpeciesTableCreateCompanionBuilder = SpeciesCompanion Function({
  Value<int> id,
  required String name,
  Value<int> nestlingEndDays,
  Value<int> juvenileEndDays,
  Value<int> adultWeighIntervalDays,
  Value<DateTime> createdAt,
});
typedef $$SpeciesTableUpdateCompanionBuilder = SpeciesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> nestlingEndDays,
  Value<int> juvenileEndDays,
  Value<int> adultWeighIntervalDays,
  Value<DateTime> createdAt,
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

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nestlingEndDays => $composableBuilder(
      column: $table.nestlingEndDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get juvenileEndDays => $composableBuilder(
      column: $table.juvenileEndDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get adultWeighIntervalDays => $composableBuilder(
      column: $table.adultWeighIntervalDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nestlingEndDays => $composableBuilder(
      column: $table.nestlingEndDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get juvenileEndDays => $composableBuilder(
      column: $table.juvenileEndDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get adultWeighIntervalDays => $composableBuilder(
      column: $table.adultWeighIntervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get nestlingEndDays => $composableBuilder(
      column: $table.nestlingEndDays, builder: (column) => column);

  GeneratedColumn<int> get juvenileEndDays => $composableBuilder(
      column: $table.juvenileEndDays, builder: (column) => column);

  GeneratedColumn<int> get adultWeighIntervalDays => $composableBuilder(
      column: $table.adultWeighIntervalDays, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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
            Value<String> name = const Value.absent(),
            Value<int> nestlingEndDays = const Value.absent(),
            Value<int> juvenileEndDays = const Value.absent(),
            Value<int> adultWeighIntervalDays = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SpeciesCompanion(
            id: id,
            name: name,
            nestlingEndDays: nestlingEndDays,
            juvenileEndDays: juvenileEndDays,
            adultWeighIntervalDays: adultWeighIntervalDays,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> nestlingEndDays = const Value.absent(),
            Value<int> juvenileEndDays = const Value.absent(),
            Value<int> adultWeighIntervalDays = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SpeciesCompanion.insert(
            id: id,
            name: name,
            nestlingEndDays: nestlingEndDays,
            juvenileEndDays: juvenileEndDays,
            adultWeighIntervalDays: adultWeighIntervalDays,
            createdAt: createdAt,
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
  required String username,
  required String displayName,
  required String passwordHash,
  Value<String> role,
  Value<DateTime> createdAt,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> username,
  Value<String> displayName,
  Value<String> passwordHash,
  Value<String> role,
  Value<DateTime> createdAt,
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
    PrefetchHooks Function({bool weightsRefs})> {
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
            Value<String> username = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            username: username,
            displayName: displayName,
            passwordHash: passwordHash,
            role: role,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String username,
            required String displayName,
            required String passwordHash,
            Value<String> role = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            username: username,
            displayName: displayName,
            passwordHash: passwordHash,
            role: role,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UsersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({weightsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (weightsRefs) db.weights],
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
    PrefetchHooks Function({bool weightsRefs})>;
typedef $$RoomsTableCreateCompanionBuilder = RoomsCompanion Function({
  Value<int> id,
  required String name,
  Value<int> sortOrder,
  Value<int?> assignedUserId,
  Value<DateTime> createdAt,
});
typedef $$RoomsTableUpdateCompanionBuilder = RoomsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<int?> assignedUserId,
  Value<DateTime> createdAt,
});

final class $$RoomsTableReferences
    extends BaseReferences<_$AppDatabase, $RoomsTable, Room> {
  $$RoomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

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

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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
    PrefetchHooks Function({bool birdsRefs, bool tasksRefs})> {
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
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> assignedUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RoomsCompanion(
            id: id,
            name: name,
            sortOrder: sortOrder,
            assignedUserId: assignedUserId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> sortOrder = const Value.absent(),
            Value<int?> assignedUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RoomsCompanion.insert(
            id: id,
            name: name,
            sortOrder: sortOrder,
            assignedUserId: assignedUserId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RoomsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({birdsRefs = false, tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (birdsRefs) db.birds,
                if (tasksRefs) db.tasks
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
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
    PrefetchHooks Function({bool birdsRefs, bool tasksRefs})>;
typedef $$BirdsTableCreateCompanionBuilder = BirdsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> ringNumber,
  required int speciesId,
  Value<int?> roomId,
  required DateTime birthDate,
  Value<String> gender,
  Value<int> sortOrder,
  Value<String> status,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$BirdsTableUpdateCompanionBuilder = BirdsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> ringNumber,
  Value<int> speciesId,
  Value<int?> roomId,
  Value<DateTime> birthDate,
  Value<String> gender,
  Value<int> sortOrder,
  Value<String> status,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
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

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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
        {bool speciesId, bool roomId, bool weightsRefs, bool tasksRefs})> {
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
            Value<String> name = const Value.absent(),
            Value<String?> ringNumber = const Value.absent(),
            Value<int> speciesId = const Value.absent(),
            Value<int?> roomId = const Value.absent(),
            Value<DateTime> birthDate = const Value.absent(),
            Value<String> gender = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BirdsCompanion(
            id: id,
            name: name,
            ringNumber: ringNumber,
            speciesId: speciesId,
            roomId: roomId,
            birthDate: birthDate,
            gender: gender,
            sortOrder: sortOrder,
            status: status,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> ringNumber = const Value.absent(),
            required int speciesId,
            Value<int?> roomId = const Value.absent(),
            required DateTime birthDate,
            Value<String> gender = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BirdsCompanion.insert(
            id: id,
            name: name,
            ringNumber: ringNumber,
            speciesId: speciesId,
            roomId: roomId,
            birthDate: birthDate,
            gender: gender,
            sortOrder: sortOrder,
            status: status,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BirdsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {speciesId = false,
              roomId = false,
              weightsRefs = false,
              tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (weightsRefs) db.weights,
                if (tasksRefs) db.tasks
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
        {bool speciesId, bool roomId, bool weightsRefs, bool tasksRefs})>;
typedef $$WeightsTableCreateCompanionBuilder = WeightsCompanion Function({
  Value<int> id,
  required int birdId,
  required double weightG,
  required DateTime recordedAt,
  Value<int?> recordedBy,
  Value<bool> isFasting,
  Value<String?> notes,
  Value<DateTime> createdAt,
});
typedef $$WeightsTableUpdateCompanionBuilder = WeightsCompanion Function({
  Value<int> id,
  Value<int> birdId,
  Value<double> weightG,
  Value<DateTime> recordedAt,
  Value<int?> recordedBy,
  Value<bool> isFasting,
  Value<String?> notes,
  Value<DateTime> createdAt,
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
            Value<int> birdId = const Value.absent(),
            Value<double> weightG = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<int?> recordedBy = const Value.absent(),
            Value<bool> isFasting = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WeightsCompanion(
            id: id,
            birdId: birdId,
            weightG: weightG,
            recordedAt: recordedAt,
            recordedBy: recordedBy,
            isFasting: isFasting,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int birdId,
            required double weightG,
            required DateTime recordedAt,
            Value<int?> recordedBy = const Value.absent(),
            Value<bool> isFasting = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WeightsCompanion.insert(
            id: id,
            birdId: birdId,
            weightG: weightG,
            recordedAt: recordedAt,
            recordedBy: recordedBy,
            isFasting: isFasting,
            notes: notes,
            createdAt: createdAt,
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
  required int birdId,
  Value<int?> roomId,
  Value<int?> assignedUserId,
  required DateTime dueDate,
  Value<String> status,
  Value<DateTime?> completedAt,
  Value<int?> completedBy,
  Value<DateTime> createdAt,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<int> birdId,
  Value<int?> roomId,
  Value<int?> assignedUserId,
  Value<DateTime> dueDate,
  Value<String> status,
  Value<DateTime?> completedAt,
  Value<int?> completedBy,
  Value<DateTime> createdAt,
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

  ColumnFilters<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedBy => $composableBuilder(
      column: $table.completedBy, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedBy => $composableBuilder(
      column: $table.completedBy, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get assignedUserId => $composableBuilder(
      column: $table.assignedUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get completedBy => $composableBuilder(
      column: $table.completedBy, builder: (column) => column);

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
    PrefetchHooks Function({bool birdId, bool roomId})> {
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
            Value<int> birdId = const Value.absent(),
            Value<int?> roomId = const Value.absent(),
            Value<int?> assignedUserId = const Value.absent(),
            Value<DateTime> dueDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int?> completedBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            birdId: birdId,
            roomId: roomId,
            assignedUserId: assignedUserId,
            dueDate: dueDate,
            status: status,
            completedAt: completedAt,
            completedBy: completedBy,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int birdId,
            Value<int?> roomId = const Value.absent(),
            Value<int?> assignedUserId = const Value.absent(),
            required DateTime dueDate,
            Value<String> status = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int?> completedBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            birdId: birdId,
            roomId: roomId,
            assignedUserId: assignedUserId,
            dueDate: dueDate,
            status: status,
            completedAt: completedAt,
            completedBy: completedBy,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TasksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({birdId = false, roomId = false}) {
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
                return [];
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
    PrefetchHooks Function({bool birdId, bool roomId})>;
typedef $$SyncLogTableCreateCompanionBuilder = SyncLogCompanion Function({
  Value<int> id,
  required String entityType,
  required int entityId,
  required String operation,
  Value<DateTime> syncedAt,
});
typedef $$SyncLogTableUpdateCompanionBuilder = SyncLogCompanion Function({
  Value<int> id,
  Value<String> entityType,
  Value<int> entityId,
  Value<String> operation,
  Value<DateTime> syncedAt,
});

class $$SyncLogTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncLogTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SyncLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncLogTable,
    SyncLogData,
    $$SyncLogTableFilterComposer,
    $$SyncLogTableOrderingComposer,
    $$SyncLogTableAnnotationComposer,
    $$SyncLogTableCreateCompanionBuilder,
    $$SyncLogTableUpdateCompanionBuilder,
    (SyncLogData, BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogData>),
    SyncLogData,
    PrefetchHooks Function()> {
  $$SyncLogTableTableManager(_$AppDatabase db, $SyncLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<int> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
          }) =>
              SyncLogCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required int entityId,
            required String operation,
            Value<DateTime> syncedAt = const Value.absent(),
          }) =>
              SyncLogCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncLogTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncLogTable,
    SyncLogData,
    $$SyncLogTableFilterComposer,
    $$SyncLogTableOrderingComposer,
    $$SyncLogTableAnnotationComposer,
    $$SyncLogTableCreateCompanionBuilder,
    $$SyncLogTableUpdateCompanionBuilder,
    (SyncLogData, BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogData>),
    SyncLogData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SpeciesTableTableManager get species =>
      $$SpeciesTableTableManager(_db, _db.species);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db, _db.rooms);
  $$BirdsTableTableManager get birds =>
      $$BirdsTableTableManager(_db, _db.birds);
  $$WeightsTableTableManager get weights =>
      $$WeightsTableTableManager(_db, _db.weights);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$SyncLogTableTableManager get syncLog =>
      $$SyncLogTableTableManager(_db, _db.syncLog);
}
