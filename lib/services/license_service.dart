import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_clock.dart';

/// SharedPreferences keys
const _kPremiumActive = 'premium_active';
const _kPremiumCode = 'premium_code';
const _kPremiumActivatedAt = 'premium_activated_at';

/// Activation code validity window (minutes from generation)
const _kValidityMinutes = 10;

/// 激活码格式：WNPRO-<8hex_gen_timestamp>-<16hex_random>-<8hex_sig>
///
/// - gen_timestamp: 4 字节 Unix 时间戳，标记码的生成时间
/// - random: 8 字节随机数
/// - sig: HMAC-SHA256(密钥, gen_timestamp + random) 前 4 字节
///
/// 码生成后 10 分钟内可激活，过期作废。
/// Pro 状态存储在 SharedPreferences，由 Android Auto Backup 自动备份，
/// 卸载重装后由系统恢复。
class LicenseService {
  static final LicenseService _instance = LicenseService._();
  factory LicenseService() => _instance;
  LicenseService._();

  bool? _cachedPro;

  /// 同步获取 Pro 状态（需先调用 [init]）
  bool get isPro => _cachedPro ?? false;

  /// 测试专用：重置内存缓存。仅 debug 模式可用。
  @visibleForTesting
  static void resetCacheForTest() {
    _instance._cachedPro = null;
  }

  /// 应用启动时调用，从 SharedPreferences 恢复状态。
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedPro = prefs.getBool(_kPremiumActive) ?? false;
    } catch (_) {
      _cachedPro = false;
    }
  }

  /// 验证并激活。
  /// 返回 true 表示激活成功。
  Future<bool> activate(String code) async {
    try {
      final genTimestamp = verifyCode(code);
      if (genTimestamp == null) return false;

      // 检查 10 分钟时间窗口
      final now = AppClock.now.millisecondsSinceEpoch ~/ 1000;
      if (now - genTimestamp > _kValidityMinutes * 60) return false;

      // 写入本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPremiumActive, true);
      await prefs.setString(_kPremiumCode, code);
      await prefs.setInt(_kPremiumActivatedAt, now);
      _cachedPro = true;

      return true;
    } catch (_) {
      return false;
    }
  }

  /// 取消激活（调试用）
  Future<void> deactivate() async {
    await clearAppOnly();
  }

  /// 清除应用内 Pro 状态
  Future<void> clearAppOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPremiumActive, false);
    await prefs.remove(_kPremiumCode);
    await prefs.remove(_kPremiumActivatedAt);
    _cachedPro = false;
  }

  /// 获取已保存的激活码
  Future<String?> getSavedCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPremiumCode);
  }

  // ── 验证 ──

  /// 验证激活码格式和 HMAC 签名。
  /// 返回生成时间戳（Unix 秒），验证失败返回 null。
  @visibleForTesting
  int? verifyCode(String code) {
    // 1. 格式校验：WNPRO-<8hex>-<16hex>-<8hex>
    final parts = code.toUpperCase().split('-');
    if (parts.length != 4) return null;
    if (parts[0] != 'WNPRO') return null;
    if (parts[1].length != 8) return null;
    if (parts[2].length != 16) return null;
    if (parts[3].length != 8) return null;

    // 2. hex 合法性
    final tsHex = parts[1];
    final randomHex = parts[2];
    final sigHex = parts[3];
    if (!_isHex(tsHex) || !_isHex(randomHex) || !_isHex(sigHex)) return null;

    // 3. 解析时间戳
    final tsBytes = _hexToBytes(tsHex);
    final genTimestamp = _bytesToUint32(tsBytes);

    // 4. HMAC 签名验证（覆盖时间戳 + 随机数）
    final randomBytes = _hexToBytes(randomHex);
    final payload = [...tsBytes, ...randomBytes];
    final expectedSig = _computeHmac(payload);
    if (expectedSig.length < 4) return null;

    final expectedHex = _bytesToHex(expectedSig.sublist(0, 4));
    if (expectedHex != sigHex) return null;

    return genTimestamp;
  }

  // ── HMAC 工具 ──

  List<int> _computeHmac(List<int> data) {
    final key = _getKey();
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    return digest.bytes;
  }

  bool _isHex(String s) {
    return RegExp(r'^[0-9A-F]+$').hasMatch(s);
  }

  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  /// 4 字节大端 → int
  int _bytesToUint32(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  // ── 密钥（XOR 混淆） ──

  List<int> _getKey() {
    const stored = <int>[
      0x8a,
      0x1d,
      0x36,
      0x23,
      0xff,
      0x28,
      0x21,
      0x66,
      0x57,
      0xe0,
      0xf5,
      0x9b,
      0xca,
      0xc2,
      0x21,
      0xac,
      0xd4,
      0x76,
      0xad,
      0xa1,
      0x78,
      0xca,
      0x3b,
      0x15,
      0x0f,
      0x3a,
      0xa1,
      0x2f,
      0x44,
      0x6e,
      0x58,
      0x76,
    ];
    const mask = <int>[
      0x5e,
      0x61,
      0x19,
      0xb2,
      0x7c,
      0x42,
      0x3f,
      0xd3,
      0x15,
      0x6f,
      0xc8,
      0xed,
      0x0b,
      0x58,
      0x2e,
      0xf4,
      0x37,
      0x51,
      0xe6,
      0xcc,
      0x6d,
      0x4a,
      0x09,
      0xbb,
      0x70,
      0x23,
      0xfd,
      0xa7,
      0x49,
      0xdc,
      0x1e,
      0x85,
    ];
    final key = <int>[];
    for (var i = 0; i < stored.length; i++) {
      key.add(stored[i] ^ mask[i]);
    }
    return key;
  }
}
