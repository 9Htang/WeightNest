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
import 'plugins/nutrition/nutrition_import_service.dart';
import 'plugins/nutrition/screens/food_library_screen.dart';

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
            'readContentUri',
            {'uri': filePath},
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

      // 异步并发检测三种魔数，避免在主 Isolate 上同步读取整文件
      final results = await Future.wait([
        _isWnbakFile(filePath),
        _isWnbirdsFile(filePath),
        _isWnnutritionFile(filePath),
      ]);
      if (results[0]) {
        _handling = true;
        _handleRestore(File(filePath));
        return;
      }
      if (results[1]) {
        _handling = true;
        _handleBirdImport(File(filePath));
        return;
      }
      if (results[2]) {
        _handling = true;
        _handleNutritionImport(File(filePath));
        return;
      }
    }
    debugPrint('_onMediaReceived: no supported file found');
  }

  /// 读取文件头 4 字节，检查是否为 WNBK 备份文件
  ///
  /// 使用 [File.open] + [RandomAccessFile.read] 异步读取前 4 字节，避免
  /// [File.readAsBytesSync] 把整个文件加载进内存并阻塞 UI 线程。
  Future<bool> _isWnbakFile(String path) async {
    return _matchMagic(path, const [0x57, 0x4E, 0x42, 0x4B], 'WNBK', '_isWnbakFile');
  }

  /// 读取文件头 4 字节，检查是否为 WNBD 鹦鹉导出文件
  Future<bool> _isWnbirdsFile(String path) async {
    return _matchMagic(path, const [0x57, 0x4E, 0x42, 0x44], 'WNBD', '_isWnbirdsFile');
  }

  /// 读取文件头 4 字节，检查是否为 WNNR 营养导出文件
  Future<bool> _isWnnutritionFile(String path) async {
    return _matchMagic(path, const [0x57, 0x4E, 0x4E, 0x52], 'WNNR', '_isWnnutritionFile');
  }

  /// 共用的魔数匹配实现：异步打开文件 → 只读前 [expected.length] 字节 → 比较。
  Future<bool> _matchMagic(
    String path,
    List<int> expected,
    String tag,
    String logPrefix,
  ) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('$logPrefix: file not found at $path');
        return false;
      }
      RandomAccessFile? raf;
      try {
        raf = await file.open(mode: FileMode.read);
        final bytes = await raf.read(expected.length);
        if (bytes.length < expected.length) {
          debugPrint('$logPrefix: file too small (${bytes.length} bytes)');
          return false;
        }
        debugPrint(
            '$logPrefix: first ${expected.length} bytes = ${bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, "0")}').join(" ")}');
        for (var i = 0; i < expected.length; i++) {
          if (bytes[i] != expected[i]) return false;
        }
        return true;
      } finally {
        await raf?.close();
      }
    } catch (e) {
      debugPrint('$logPrefix error: $e');
      return false;
    }
  }

  /// 处理 .wnnutrition 营养文件导入。
  /// 流程：确认导入 → 执行 → 显示结果 → 跳转食材库
  Future<void> _handleNutritionImport(File file) async {
    debugPrint(
        '_handleNutritionImport: start, mounted=$mounted, navContext=${_navContext != null}');
    // 等待 navigator 就绪
    var nav = _navContext;
    if (nav == null && mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
      nav = _navContext;
    }
    if (!mounted || nav == null) {
      debugPrint('_handleNutritionImport: abort, mounted=$mounted nav=$nav');
      _handling = false;
      return;
    }

    // 调用导入服务（内部含冲突检测 + 确认弹窗）
    final result = await NutritionImportService()
        .importFromFileWithConfirm(file, nav);

    _handling = false;

    if (result == null) {
      // 文件无效
      if (mounted) {
        await showDialog(
          context: nav,
          builder: (ctx) => AlertDialog(
            title: const Text('文件无效'),
            content: const Text('该文件不是有效的营养导出文件，可能已损坏。'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 用户取消导入（取消冲突弹窗）
    if (result.hasNoChanges &&
        result.errors.isNotEmpty &&
        result.errors.first.contains('取消')) {
      return;
    }

    // 显示结果摘要 → 跳转食材库
    if (mounted) {
      await showDialog(
        context: nav,
        builder: (ctx) => AlertDialog(
          title: const Text('导入完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('新增 ${result.totalCreated} 项'),
              if (result.totalUpdated > 0) Text('更新 ${result.totalUpdated} 项'),
              if (result.totalSkipped > 0)
                Text('跳过 ${result.totalSkipped} 项'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('错误 ${result.errors.length} 条',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            if (result.errors.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showNutritionErrors(nav!, result.errors);
                },
                child: const Text('查看错误'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('查看食材库'),
            ),
          ],
        ),
      );
      // 跳转食材库
      Navigator.of(nav).push(
        MaterialPageRoute(builder: (_) => const FoodLibraryScreen()),
      );
    }
  }

  /// 显示导入错误详情
  Future<void> _showNutritionErrors(
      BuildContext nav, List<String> errors) async {
    await showDialog(
      context: nav,
      builder: (ctx) => AlertDialog(
        title: const Text('导入错误'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: errors
                .map((e) => Text(e, style: const TextStyle(fontSize: 13)))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Future<void> _handleBirdImport(File file) async {
    debugPrint(
        '_handleBirdImport: start, mounted=$mounted, navContext=${_navContext != null}');
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
    debugPrint(
        '_handleRestore: start, mounted=$mounted, navContext=${_navContext != null}');
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
      debugPrint(
          '_handleRestore: abort after verify, valid=$valid mounted=$mounted');
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
          content: Text(ok ? '数据已恢复。' : '备份文件无效或已损坏，请检查文件。'),
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
