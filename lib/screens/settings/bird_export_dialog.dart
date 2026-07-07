import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers.dart';
import '../../services/bird_export_service.dart';

/// 批量导出鹦鹉数据对话框 — 多选鸟 → 导出 → 分享
class BirdExportDialog extends ConsumerStatefulWidget {
  const BirdExportDialog({super.key});

  @override
  ConsumerState<BirdExportDialog> createState() => _BirdExportDialogState();
}

class _BirdExportDialogState extends ConsumerState<BirdExportDialog> {
  final _selectedIds = <int>{};
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final birdsAsync = ref.watch(allBirdsProvider);

    return AlertDialog(
      title: const Text('导出鹦鹉数据'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isExporting
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在导出，请稍候...'),
                  ],
                ),
              )
            : birdsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败: $e')),
                data: (birds) {
                  if (birds.isEmpty) {
                    return const Center(child: Text('暂无鹦鹉数据'));
                  }

                  final selectedCount = _selectedIds
                      .where((id) => birds.any((b) => b.bird.id == id))
                      .length;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 操作栏
                      Row(
                        children: [
                          TextButton(
                            onPressed: _isExporting
                                ? null
                                : () {
                                    setState(() {
                                      if (selectedCount == birds.length) {
                                        _selectedIds.clear();
                                      } else {
                                        _selectedIds.addAll(
                                            birds.map((b) => b.bird.id));
                                      }
                                    });
                                  },
                            child: Text(
                                selectedCount == birds.length ? '取消全选' : '全选'),
                          ),
                          const Spacer(),
                          Text('已选择 $selectedCount 只',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                      const Divider(),
                      // 鸟列表
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: birds.length,
                          itemBuilder: (_, i) {
                            final bwd = birds[i];
                            final bird = bwd.bird;
                            final isSelected = _selectedIds.contains(bird.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: _isExporting
                                  ? null
                                  : (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedIds.add(bird.id);
                                        } else {
                                          _selectedIds.remove(bird.id);
                                        }
                                      });
                                    },
                              dense: true,
                              title: Text(bird.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                [
                                  if (bird.ringNumber?.isNotEmpty == true)
                                    bird.ringNumber!,
                                  bwd.species.name,
                                ].join(' · '),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed:
              _isExporting || _selectedIds.isEmpty ? null : () => _doExport(),
          child: const Text('导出'),
        ),
      ],
    );
  }

  Future<void> _doExport() async {
    final count = _selectedIds.length;
    debugPrint('[ExportDialog] 开始导出 $count 只鹦鹉: ${_selectedIds.toList()}');
    setState(() => _isExporting = true);

    // 让 loading UI 先渲染出来
    await Future.delayed(const Duration(milliseconds: 50));
    debugPrint('[ExportDialog] loading UI 已渲染，开始调用 exportBirds');

    final db = ref.read(databaseProvider);
    debugPrint('[ExportDialog] 获取到 databaseProvider');

    final file =
        await BirdExportService().exportBirds(_selectedIds.toList(), db);
    debugPrint('[ExportDialog] exportBirds 返回: ${file?.path ?? "null"}');

    if (!mounted) return;
    setState(() => _isExporting = false);

    if (file != null) {
      Navigator.pop(context);
      debugPrint('[ExportDialog] 开始分享文件');
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'WeightNest 鹦鹉数据导出',
      );
      debugPrint('[ExportDialog] 分享完成，清理临时文件');
      try {
        await file.delete();
      } catch (_) {}
    } else if (mounted) {
      debugPrint('[ExportDialog] 导出失败');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出失败，请重试')),
      );
    }
    debugPrint('[ExportDialog] _doExport 结束');
  }
}
