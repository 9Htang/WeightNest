import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/license_service.dart';
import '../test_helpers/test_clock.dart';

/// ── LicenseService.verifyCode / activate 单元测试 ────────────────────────
///
/// 用真实 HMAC 密钥（与 tools/generate_license.dart 一致）构造激活码，
/// 验证 verifyCode 的格式校验分支与签名验证，以及 activate 的时间窗口逻辑。

/// 与 tools/generate_license.dart 中 XOR 还原后的密钥一致。
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

List<int> _uint32ToBytes(int v) =>
    [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

/// 构造一个生成时间为 [genTimestampSec]（Unix 秒）的有效激活码。
String _makeCode(int genTimestampSec) {
  final tsBytes = _uint32ToBytes(genTimestampSec);
  final random = List<int>.generate(8, (_) => 42); // 固定随机数便于复现
  final payload = [...tsBytes, ...random];
  final digest = Hmac(sha256, _key).convert(payload).bytes;
  final sig = _bytesToHex(digest.sublist(0, 4));
  final tsHex = _bytesToHex(tsBytes);
  final randomHex = _bytesToHex(random);
  return 'WNPRO-$tsHex-$randomHex-$sig';
}

final _fakeNow = DateTime(2025, 6, 15, 12, 0, 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final svc = LicenseService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LicenseService.resetCacheForTest();
    await setTestClock(_fakeNow);
  });

  tearDown(() async {
    LicenseService.resetCacheForTest();
    await resetTestClock();
  });

  // ═════════════════════════════════════════════════════════════════════════
  // verifyCode — 格式校验分支
  // ═════════════════════════════════════════════════════════════════════════

  group('verifyCode 格式校验', () {
    test('正确格式 + 正确签名 → 返回时间戳', () {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      final code = _makeCode(ts);
      final result = svc.verifyCode(code);
      expect(result, isNotNull);
      expect(result, ts);
    });

    test('parts 数量不为 4 → null', () {
      expect(svc.verifyCode('WNPRO-abc-def'), isNull);
      expect(svc.verifyCode('WNPRO-a-b-c-d'), isNull);
    });

    test('前缀非 WNPRO → null', () {
      expect(
          svc.verifyCode('WNPR0-aaaaaaaa-bbbbbbbbbbbbbbbb-cccccccc'), isNull);
    });

    test('时间戳段长度非 8 → null', () {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      final code = _makeCode(ts);
      // 篡改时间戳段长度
      expect(svc.verifyCode(code.replaceFirst('WNPRO-', 'WNPRO-0')), isNull);
    });

    test('随机段长度非 16 → null', () {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      final code = _makeCode(ts);
      // 替换随机段为短串
      final parts = code.split('-');
      expect(
        svc.verifyCode('WNPRO-${parts[1]}-FFFF-CCCCCCCC'),
        isNull,
      );
    });

    test('签名段长度非 8 → null', () {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      final code = _makeCode(ts);
      final parts = code.split('-');
      expect(svc.verifyCode('WNPRO-${parts[1]}-${parts[2]}-FF'), isNull);
    });

    test('非 hex 字符 → null', () {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      final code = _makeCode(ts);
      // 用 G 替换首个 hex 字符（G 不是 hex）
      expect(svc.verifyCode(code.replaceFirst('WNPRO-', 'WNPRO-G')), isNull);
    });

    test('HMAC 签名不匹配 → null', () {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      final code = _makeCode(ts);
      // 篡改签名段
      final parts = code.split('-');
      final tampered = 'WNPRO-${parts[1]}-${parts[2]}-00000000';
      expect(svc.verifyCode(tampered), isNull);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // activate — 时间窗口逻辑
  // ═════════════════════════════════════════════════════════════════════════

  group('activate 时间窗口', () {
    test('生成后立即激活 → 成功，isPro=true', () async {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      final ok = await svc.activate(_makeCode(ts));
      expect(ok, isTrue);
      expect(svc.isPro, isTrue);
    });

    test('生成后 9 分钟激活（< 10min）→ 成功', () async {
      final genTs = _fakeNow.subtract(const Duration(minutes: 9));
      final ok =
          await svc.activate(_makeCode(genTs.millisecondsSinceEpoch ~/ 1000));
      expect(ok, isTrue);
      expect(svc.isPro, isTrue);
    });

    test('生成后 11 分钟激活（> 10min）→ 失败，isPro=false', () async {
      final genTs = _fakeNow.subtract(const Duration(minutes: 11));
      final ok =
          await svc.activate(_makeCode(genTs.millisecondsSinceEpoch ~/ 1000));
      expect(ok, isFalse);
      expect(svc.isPro, isFalse);
    });

    test('无效码 → 失败', () async {
      final ok = await svc.activate('invalid-code');
      expect(ok, isFalse);
      expect(svc.isPro, isFalse);
    });

    test('激活成功后持久化到 SharedPreferences', () async {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      await svc.activate(_makeCode(ts));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('premium_active'), isTrue);
      expect(prefs.getString('premium_code'), isNotNull);
    });
  });

  group('deactivate / clearAppOnly', () {
    test('激活后 deactivate → isPro=false，prefs 清除', () async {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      await svc.activate(_makeCode(ts));
      expect(svc.isPro, isTrue);

      await svc.deactivate();
      expect(svc.isPro, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('premium_active'), isFalse);
    });

    test('clearAppOnly 同样清除', () async {
      final ts = _fakeNow.millisecondsSinceEpoch ~/ 1000;
      await svc.activate(_makeCode(ts));
      await svc.clearAppOnly();
      expect(svc.isPro, isFalse);
    });
  });
}
