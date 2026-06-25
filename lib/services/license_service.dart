import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for Pro activation state
const _kPremiumActive = 'premium_active';
const _kPremiumCode = 'premium_code';

/// 激活码格式：WNPRO-<16hex>-<8hex>
/// 前 16 位 hex = 8 字节随机码
/// 后 8 位 hex = HMAC-SHA256(密钥, 随机码) 的前 4 字节
///
/// 通过 HMAC 签名验证，无需后端服务器，无需存储有效码列表。
class LicenseService {
  static final LicenseService _instance = LicenseService._();
  factory LicenseService() => _instance;
  LicenseService._();

  bool? _cachedPro;

  /// 同步获取 Pro 状态（需先调用 [init]）
  bool get isPro => _cachedPro ?? false;

  /// 应用启动时调用，从 SharedPreferences 恢复状态
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPro = prefs.getBool(_kPremiumActive) ?? false;
  }

  /// 验证并激活
  ///
  /// 返回 true 表示激活成功
  Future<bool> activate(String code) async {
    if (!_verifyCode(code)) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPremiumActive, true);
    await prefs.setString(_kPremiumCode, code);
    _cachedPro = true;
    return true;
  }

  /// 取消激活（调试用）
  Future<void> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPremiumActive, false);
    await prefs.remove(_kPremiumCode);
    _cachedPro = false;
  }

  /// 获取已保存的激活码（用于显示）
  Future<String?> getSavedCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPremiumCode);
  }

  /// 验证激活码格式和 HMAC 签名
  bool _verifyCode(String code) {
    // 1. 格式校验
    final parts = code.toUpperCase().split('-');
    if (parts.length != 3) return false;
    if (parts[0] != 'WNPRO') return false;
    if (parts[1].length != 16) return false;
    if (parts[2].length != 8) return false;

    // 2. hex 合法性
    final randomHex = parts[1];
    final sigHex = parts[2];
    if (!_isHex(randomHex) || !_isHex(sigHex)) return false;

    // 3. HMAC 验证
    final randomBytes = _hexToBytes(randomHex);
    final expectedSig = _computeHmac(randomBytes);
    if (expectedSig.length < 4) return false;

    final expectedHex = _bytesToHex(expectedSig.sublist(0, 4));
    return expectedHex == sigHex;
  }

  /// 计算 HMAC-SHA256(密钥, data)
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
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }

  /// XOR 混淆后的密钥 — 仅供离线激活码验证使用
  List<int> _getKey() {
    // 混淆存储：实际密钥 XOR 固定掩码
    const stored = <int>[
      0x8a, 0x1d, 0x36, 0x23, 0xff, 0x28, 0x21, 0x66,
      0x57, 0xe0, 0xf5, 0x9b, 0xca, 0xc2, 0x21, 0xac,
      0xd4, 0x76, 0xad, 0xa1, 0x78, 0xca, 0x3b, 0x15,
      0x0f, 0x3a, 0xa1, 0x2f, 0x44, 0x6e, 0x58, 0x76,
    ];
    const mask = <int>[
      0x5e, 0x61, 0x19, 0xb2, 0x7c, 0x42, 0x3f, 0xd3,
      0x15, 0x6f, 0xc8, 0xed, 0x0b, 0x58, 0x2e, 0xf4,
      0x37, 0x51, 0xe6, 0xcc, 0x6d, 0x4a, 0x09, 0xbb,
      0x70, 0x23, 0xfd, 0xa7, 0x49, 0xdc, 0x1e, 0x85,
    ];
    final key = <int>[];
    for (var i = 0; i < stored.length; i++) {
      key.add(stored[i] ^ mask[i]);
    }
    return key;
  }
}
