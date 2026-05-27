import 'package:uuid/uuid.dart';

/// 全局唯一 ID 生成工具
const _uuid = Uuid();

/// 生成 UUID v4
String genUuid() => _uuid.v4();

/// 生成简短 ID（时间戳 + 随机数），用于显示
String genShortId() => _uuid.v4().substring(0, 8);
