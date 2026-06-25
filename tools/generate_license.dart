/// 激活码生成工具（仅开发者使用，不打包进应用）
///
/// 用法：dart run tools/generate_license.dart [数量]
///
/// 生成格式：WNPRO-<16hex>-<8hex>
/// 原理：随机码 + HMAC-SHA256(密钥, 随机码) 签名

import 'dart:math';
import 'package:crypto/crypto.dart';

// 与 lib/services/license_service.dart 中 XOR 还原后的密钥一致
const _key = <int>[
  0xd4, 0x7c, 0x2f, 0x91, 0x83, 0x6a, 0x1e, 0xb5,
  0x42, 0x8f, 0x3d, 0x76, 0xc1, 0x9a, 0x0f, 0x58,
  0xe3, 0x27, 0x4b, 0x6d, 0x15, 0x80, 0x32, 0xae,
  0x7f, 0x19, 0x5c, 0x88, 0x0d, 0xb2, 0x46, 0xf3,
];

String _bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();

String generateCode() {
  final random = List<int>.generate(8, (_) => Random().nextInt(256));
  final hmac = Hmac(sha256, _key);
  final digest = hmac.convert(random).bytes;
  final sig = _bytesToHex(digest.sublist(0, 4));
  final code = _bytesToHex(random);
  return 'WNPRO-$code-$sig';
}

void main(List<String> args) {
  final count = args.isNotEmpty ? int.tryParse(args[0]) ?? 5 : 5;
  print('生成 $count 个激活码：\n');
  for (var i = 0; i < count; i++) {
    print('  ${generateCode()}');
  }
}
