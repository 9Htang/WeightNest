import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class ConnectionStatusBar extends ConsumerWidget {
  final VoidCallback? onConnect;

  const ConnectionStatusBar({super.key, this.onConnect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncConnected = ref.watch(syncConnectedProvider);
    final engine = ref.watch(syncEngineProvider);
    final scheme = Theme.of(context).colorScheme;

    if (syncConnected && engine.isConnected) {
      return _buildConnected('${engine.serverHost}:${engine.serverPort}');
    }

    if (engine.isConnected && !syncConnected) {
      return _buildWarning(
        '${engine.serverHost}:${engine.serverPort} 同步中断',
        scheme: scheme,
      );
    }

    return _buildDisconnected(scheme);
  }

  Widget _buildConnected(String label) {
    return Container(
      width: double.infinity,
      height: 24,
      color: const Color(0xFF6B8F71).withAlpha(22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_done_rounded, size: 14, color: const Color(0xFF6B8F71)),
          const SizedBox(width: 8),
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6B8F71),
            ),
          ),
          const SizedBox(width: 8),
          SelectableText(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B8F71),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning(String label, {required ColorScheme scheme}) {
    return Container(
      width: double.infinity,
      height: 24,
      color: const Color(0xFFC4956A).withAlpha(26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_sync_rounded, size: 14, color: Color(0xFFC4956A)),
          const SizedBox(width: 8),
          SelectableText(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFC4956A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnected(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      height: 24,
      color: scheme.surfaceContainerHighest.withAlpha(140),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 14,
              color: scheme.onSurface.withAlpha(140)),
          const SizedBox(width: 8),
          Text(
            '未连接服务器',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withAlpha(160),
            ),
          ),
          if (onConnect != null) ...[
            const SizedBox(width: 16),
            Material(
              color: scheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: onConnect,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Text(
                    '连接',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
