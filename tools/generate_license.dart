/// 激活码生成工具（仅开发者使用，不打包进应用）
///
/// 用法：dart run tools/generate_license.dart [数量]
///
/// 生成格式：WNPRO-<8hex_gen_timestamp>-<16hex_random>-<8hex_sig>
/// - gen_timestamp: 生成时的 Unix 时间戳（4 字节 hex）
/// - random: 8 字节随机数
/// - sig: HMAC-SHA256(密钥, timestamp + random) 前 4 字节
///
/// 码生成后 10 分钟内有效，过期无法激活新设备。

import 'dart:math';
import 'package:crypto/crypto.dart';

// 与 lib/services/license_service.dart 中 XOR 还原后的密钥一致
const _key = <int>[
  0xd4,
  0x7c,
  0x2f,
  0x91,
  0x83,
  0x6a,
  0x1e,
  0xb5,
  0x42,
  0x8f,
  0x3d,
  0x76,
  0xc1,
  0x9a,
  0x0f,
  0x58,
  0xe3,
  0x27,
  0x4b,
  0x6d,
  0x15,
  0x80,
  0x32,
  0xae,
  0x7f,
  0x19,
  0x5c,
  0x88,
  0x0d,
  0xb2,
  0x46,
  0xf3,
];

String _bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

/// 4 字节大端 int → bytes
List<int> _uint32ToBytes(int v) {
  return [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];
}

String generateCode() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final tsBytes = _uint32ToBytes(now);
  final random = List<int>.generate(8, (_) => Random().nextInt(256));

  final payload = [...tsBytes, ...random];
  final hmac = Hmac(sha256, _key);
  final digest = hmac.convert(payload).bytes;
  final sig = _bytesToHex(digest.sublist(0, 4));

  final tsHex = _bytesToHex(tsBytes);
  final randomHex = _bytesToHex(random);

  return 'WNPRO-$tsHex-$randomHex-$sig';
}

void main(List<String> args) {
  final count = args.isNotEmpty ? int.tryParse(args[0]) ?? 5 : 5;
  print('生成 $count 个激活码（10 分钟内有效）：\n');
  for (var i = 0; i < count; i++) {
    print('  ${generateCode()}');
  }
}
