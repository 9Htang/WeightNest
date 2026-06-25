import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/license_service.dart';

enum PremiumStatus { free, pro }

class PremiumNotifier extends StateNotifier<PremiumStatus> {
  final LicenseService _license = LicenseService();

  PremiumNotifier() : super(PremiumStatus.free) {
    // 同步读取（LicenseService.init() 已在 main 中调用）
    state = _license.isPro ? PremiumStatus.pro : PremiumStatus.free;
  }

  bool get isPro => state == PremiumStatus.pro;

  /// 激活 Pro
  Future<bool> activate(String code) async {
    final ok = await _license.activate(code);
    if (ok) state = PremiumStatus.pro;
    return ok;
  }

  /// 取消激活（调试用）
  Future<void> deactivate() async {
    await _license.deactivate();
    state = PremiumStatus.free;
  }
}

/// Premium 状态提供者
final premiumStatusProvider =
    StateNotifierProvider<PremiumNotifier, PremiumStatus>((ref) {
  return PremiumNotifier();
});
