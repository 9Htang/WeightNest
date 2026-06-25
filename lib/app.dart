import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'theme/theme.dart';
import 'providers.dart';
import 'services/backup_service.dart';
import 'screens/settings/bird_import_preview_dialog.dart';
import 'screens/shell/mobile_shell.dart';

/// MethodChannel：处理 content:// URI（QQ 等 App 用此格式分享文件）
const _fileChannel = MethodChannel('com.weightnest/file_helper');

class WeightNestApp extends StatelessWidget {
  const WeightNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: const _AppContent(),
    );
  }
}

class _AppContent extends ConsumerStatefulWidget {
  const _AppContent();

  @override
  ConsumerState<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends ConsumerState<_AppContent> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;
  bool _handling = false;

  /// 获取 MaterialApp 内部的 context（有 MaterialLocalizations）
  BuildContext? get _navContext => _navigatorKey.currentContext;

  @override
  void initState() {
    super.initState();
    // 首帧后检查冷启动（通过文件关联打开 App）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkColdStart();
      // 监听热启动（App 在后台时点击文件）
      _mediaSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen(_onMediaReceived);
    });
  }

  @override
  void dispose() {
    _mediaSubscription?.cancel();
    super.dispose();
  }

  /// 冷启动：App 未运行时通过文件关联打开
  Future<void> _checkColdStart() async {
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      await _onMediaReceived(initial);
    } catch (e) {
      debugPrint('_checkColdStart error: $e');
    }
  }

  /// 收到文件时触发（冷启动 + 热启动共用）
  Future<void> _onMediaReceived(List<SharedMediaFile> media) async {
    debugPrint('_onMediaReceived: ${media.length} files');
    if (_handling) {
      debugPrint('_onMediaReceived: already handling, skip');
      return;
    }
    for (final f in media) {
      debugPrint('  checking path=${f.path}');

      // QQ 等 App 传 content:// URI，需要先转换为本地文件
      String filePath = f.path;
      if (filePath.startsWith('content://')) {
        try {
          final resolved = await _fileChannel.invokeMethod<String>(
            'readContentUri', {'uri': filePath},
          );
          if (resolved != null) {
            filePath = resolved;
            debugPrint('  content URI resolved to $filePath');
          } else {
            debugPrint('  content URI resolve returned null');
            continue;
          }
        } catch (e) {
          debugPrint('  content URI resolve failed: $e');
          continue;
        }
      }

      if (_isWnbakFile(filePath)) {
        _handling = true;
        _handleRestore(File(filePath));
        return;
      }
      if (_isWnbirdsFile(filePath)) {
        _handling = true;
        _handleBirdImport(File(filePath));
        return;
      }
    }
    debugPrint('_onMediaReceived: no supported file found');
  }

  /// 读取文件头 4 字节，检查是否为 WNBK 备份文件
  bool _isWnbakFile(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        debugPrint('_isWnbakFile: file not found at $path');
        return false;
      }
      final bytes = file.readAsBytesSync().take(4).toList();
      if (bytes.length < 4) {
        debugPrint('_isWnbakFile: file too small (${bytes.length} bytes)');
        return false;
      }
      debugPrint('_isWnbakFile: first 4 bytes = ${bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, "0")}').join(" ")}');
      return bytes[0] == 0x57 && bytes[1] == 0x4E &&
             bytes[2] == 0x42 && bytes[3] == 0x4B; // W N B K
    } catch (e) {
      debugPrint('_isWnbakFile error: $e');
      return false;
    }
  }

  /// 读取文件头 4 字节，检查是否为 WNBD 鹦鹉导出文件
  bool _isWnbirdsFile(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        debugPrint('_isWnbirdsFile: file not found at $path');
        return false;
      }
      final bytes = file.readAsBytesSync().take(4).toList();
      if (bytes.length < 4) {
        debugPrint('_isWnbirdsFile: file too small (${bytes.length} bytes)');
        return false;
      }
      debugPrint('_isWnbirdsFile: first 4 bytes = ${bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, "0")}').join(" ")}');
      return bytes[0] == 0x57 && bytes[1] == 0x4E &&
             bytes[2] == 0x42 && bytes[3] == 0x44; // W N B D
    } catch (e) {
      debugPrint('_isWnbirdsFile error: $e');
      return false;
    }
  }

  Future<void> _handleBirdImport(File file) async {
    debugPrint('_handleBirdImport: start, mounted=$mounted, navContext=${_navContext != null}');
    var nav = _navContext;
    if (nav == null && mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
      nav = _navContext;
    }
    if (!mounted || nav == null) {
      debugPrint('_handleBirdImport: abort, mounted=$mounted nav=$nav');
      _handling = false;
      return;
    }

    final confirmed = await showDialog<bool>(
      context: nav,
      builder: (ctx) => BirdImportPreviewDialog(file: file),
    );

    debugPrint('_handleBirdImport: dialog dismissed, confirmed=$confirmed');
    _handling = false;
  }

  Future<void> _handleRestore(File file) async {
    debugPrint('_handleRestore: start, mounted=$mounted, navContext=${_navContext != null}');
    // 等待 navigator 就绪（首帧时可能还没 attach）
    var nav = _navContext;
    if (nav == null && mounted) {
      debugPrint('_handleRestore: navContext null, waiting...');
      // 延迟等待 MaterialApp 构建完成
      await Future.delayed(const Duration(milliseconds: 200));
      nav = _navContext;
    }
    debugPrint('_handleRestore: after wait, navContext=${nav != null}');
    if (!mounted || nav == null) {
      debugPrint('_handleRestore: abort, mounted=$mounted nav=$nav');
      _handling = false;
      return;
    }

    debugPrint('_handleRestore: calling verifyBackup...');
    final valid = await BackupService().verifyBackup(file);
    debugPrint('_handleRestore: verifyBackup=$valid, mounted=$mounted');
    if (!valid || !mounted) {
      debugPrint('_handleRestore: abort after verify, valid=$valid mounted=$mounted');
      _handling = false;
      return;
    }

    final confirm = await showDialog<bool>(
      context: nav,
      builder: (ctx) => AlertDialog(
        title: const Text('检测到备份文件'),
        content: const Text(
          '是否从此备份文件恢复数据？\n\n'
          '此操作将覆盖当前所有数据（包括体重记录、鹦鹉信息、照片等），不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      _handling = false;
      return;
    }

    // 显示进度
    if (mounted) {
      showDialog(
        context: nav,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    final ok = await BackupService().restoreFrom(file);

    if (mounted) Navigator.of(nav).pop(); // 关闭进度

    if (ok && mounted) {
      // 强制刷新数据库连接，无需重启
      ref.invalidate(databaseProvider);
    }

    if (mounted) {
      await showDialog(
        context: nav,
        builder: (ctx) => AlertDialog(
          title: Text(ok ? '恢复成功' : '恢复失败'),
          content: Text(ok
              ? '数据已恢复。'
              : '备份文件无效或已损坏，请检查文件。'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    }

    _handling = false;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'WeightNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: child,
          ),
        );
      },
      home: const MobileShell(),
    );
  }
}
