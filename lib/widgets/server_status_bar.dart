import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/network_service.dart';

/// 局域网服务器状态栏
/// 显示在页面底部，仅在服务器运行时可见
class ServerStatusBar extends ConsumerWidget {
  const ServerStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final net = ref.watch(networkProvider);

    if (!net.isServerRunning) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final address = net.localIp != null
        ? '${net.localIp}:${net.serverPort}'
        : '启动中...';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(180),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withAlpha(60),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 地址行
          Row(
            children: [
              // 在线指示灯
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha(100),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '局域网服务器',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              // 复制按钮
              SizedBox(
                height: 32,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已复制: $address'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('复制', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // IP 地址
          SelectableText(
            address,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
              color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '其他设备可通过此地址连接并同步数据',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onPrimaryContainer.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}
