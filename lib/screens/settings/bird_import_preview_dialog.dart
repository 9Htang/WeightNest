import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../services/bird_import_service.dart';

/// 导入预览 + 确认对话框
class BirdImportPreviewDialog extends ConsumerStatefulWidget {
  final File file;
  const BirdImportPreviewDialog({super.key, required this.file});

  @override
  ConsumerState<BirdImportPreviewDialog> createState() => _BirdImportPreviewDialogState();
}

class _BirdImportPreviewDialogState extends ConsumerState<BirdImportPreviewDialog> {
  BirdImportPreview? _preview;
  bool _isLoading = true;
  bool _isImporting = false;
  bool _autoCreateSpecies = true;
  BirdImportResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final db = ref.read(databaseProvider);
    final preview = await BirdImportService().previewImport(widget.file, db);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (preview != null) {
        _preview = preview;
      } else {
        _error = '无法读取文件，请确认选择了正确的 .wnbirds 文件';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 结果状态
    if (_result != null) {
      return AlertDialog(
        title: const Text('导入完成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('成功导入', '${_result!.importedCount} 只', Colors.green),
            const SizedBox(height: 4),
            _infoRow('已跳过', '${_result!.skippedCount} 只（UUID 已存在）', Colors.grey),
            if (_result!.hasErrors) ...[
              const SizedBox(height: 12),
              const Text('错误:', style: TextStyle(fontWeight: FontWeight.w600)),
              ...(_result!.errors.map((e) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('· $e', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ))),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              ref.invalidate(allBirdsProvider);
              Navigator.pop(context);
            },
            child: const Text('完成'),
          ),
        ],
      );
    }

    // 错误状态
    if (_error != null) {
      return AlertDialog(
        title: const Text('导入失败'),
        content: Text(_error!),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('返回')),
        ],
      );
    }

    return AlertDialog(
      title: const Text('导入预览'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _preview == null
                ? const Center(child: Text('无法解析文件'))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 汇总
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(60),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '共 ${_preview!.totalBirds} 只鹦鹉，'
                                '${_preview!.birds.where((b) => b.isNew).length} 只新建，'
                                '${_preview!.birds.where((b) => !b.isNew).length} 只已存在（将跳过）',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 缺失物种提示
                      if (_preview!.missingSpecies.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withAlpha(80)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('以下物种在本地不存在：',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ...(_preview!.missingSpecies.map((ms) => Padding(
                                    padding: const EdgeInsets.only(left: 26, top: 2),
                                    child: Text('· ${ms.name}',
                                        style: const TextStyle(fontSize: 12)),
                                  ))),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '自动创建缺失物种',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                    ),
                                  ),
                                  Switch(
                                    value: _autoCreateSpecies,
                                    onChanged: (v) => setState(() => _autoCreateSpecies = v),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // 鸟列表
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _preview!.birds.length,
                          itemBuilder: (_, i) {
                            final info = _preview!.birds[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Flexible(
                                              child: Text(info.name,
                                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 8),
                                            _badge(
                                              info.isNew ? '新建' : '已存在',
                                              info.isNew ? Colors.green : Colors.grey,
                                            ),
                                          ]),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              info.speciesName,
                                              '体重×${info.weightCount}',
                                              if (info.medicationCount > 0) '喂药×${info.medicationCount}',
                                              if (info.photoCount > 0) '照片×${info.photoCount}',
                                            ].join(' · '),
                                            style: TextStyle(
                                                fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isImporting || _preview == null ? null : () => _doImport(),
          child: _isImporting
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('确认导入'),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withAlpha(25),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Row(children: [
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    ]);
  }

  Future<void> _doImport() async {
    setState(() => _isImporting = true);

    final db = ref.read(databaseProvider);
    final result = await BirdImportService().importBirds(
      widget.file,
      db,
      missingSpecies: _autoCreateSpecies && _preview != null ? _preview!.missingSpecies : [],
    );

    if (!mounted) return;
    setState(() {
      _isImporting = false;
      _result = result;
    });
  }
}
