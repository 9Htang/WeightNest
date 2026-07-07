import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/license_service.dart';

enum PremiumStatus { free, pro }

class PremiumNotifier extends StateNotifier<PremiumStatus> {
  final LicenseService _license;

  PremiumNotifier({LicenseService? license})
      : _license = license ?? LicenseService(),
        super(PremiumStatus.free) {
    // 同步读取（LicenseService.init() 已在 main 中调用）
    state = _license.isPro ? PremiumStatus.pro : PremiumStatus.free;
  }

  bool get isPro => state == PremiumStatus.pro;

  /// 验证激活码并持久化（不改变 state，由 UI 层在安全时机调用 [setPro]）
  Future<bool> activate(String code) async {
    return _license.activate(code);
  }

  /// UI 层确认动画已完成、widget tree 稳定后调用此方法改 state
  void setPro() {
    if (mounted) state = PremiumStatus.pro;
  }

  /// 取消激活（调试用，清理全部）
  Future<void> deactivate() async {
    await _license.deactivate();
    state = PremiumStatus.free;
  }

  /// 清除应用内 Pro 状态（调试用）
  Future<void> clearAppOnly() async {
    await _license.clearAppOnly();
    state = PremiumStatus.free;
  }
}

/// Premium 状态提供者
final premiumStatusProvider =
    StateNotifierProvider<PremiumNotifier, PremiumStatus>((ref) {
  return PremiumNotifier();
});
