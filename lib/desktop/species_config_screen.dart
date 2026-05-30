import 'package:flutter/material.dart';
import '../services/bird_archive_service.dart';

/// 品种配置页面 — 编辑各品种的生长阶段和称重间隔
class SpeciesConfigScreen extends StatefulWidget {
  final SpeciesService service;
  final ValueNotifier<int> refreshKey;

  const SpeciesConfigScreen({super.key, required this.service, required this.refreshKey});

  @override
  State<SpeciesConfigScreen> createState() => _SpeciesConfigScreenState();
}

class _SpeciesConfigScreenState extends State<SpeciesConfigScreen> {
  List<SpeciesInfo> _species = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    widget.refreshKey.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshKey.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() => _load();

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await widget.service.fetchAll();
      if (mounted) setState(() { _species = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _update(SpeciesInfo sp, String field, int value) async {
    try {
      final s = widget.service;
      switch (field) {
        case 'nestlingEnd': await s.update(sp.id, nestlingEndDays: value);
        case 'juvenileEnd': await s.update(sp.id, juvenileEndDays: value);
        case 'nestlingInterval': await s.update(sp.id, nestlingWeighIntervalDays: value);
        case 'juvenileInterval': await s.update(sp.id, juvenileWeighIntervalDays: value);
        case 'adultInterval': await s.update(sp.id, adultWeighIntervalDays: value);
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateDialog(onSave: (String name, Map<String, int> fields) {
        Navigator.pop(ctx);
        _create(name, fields);
      }),
    );
  }

  Future<void> _create(String name, Map<String, int> fields) async {
    try {
      await widget.service.create(name,
        nestlingEndDays: fields['nestlingEndDays'],
        juvenileEndDays: fields['juvenileEndDays'],
        nestlingWeighIntervalDays: fields['nestlingWeighIntervalDays'],
        juvenileWeighIntervalDays: fields['juvenileWeighIntervalDays'],
        adultWeighIntervalDays: fields['adultWeighIntervalDays'],
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showEditDialog(SpeciesInfo sp) {
    showDialog(
      context: context,
      builder: (ctx) => _EditDialog(sp: sp, onSave: (field, value) {
        Navigator.pop(ctx);
        _update(sp, field, value);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(children: [
          const Icon(Icons.science, size: 20),
          const SizedBox(width: 8),
          Text('品种配置', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${_species.length} 个品种', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(width: 12),
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加品种'),
            onPressed: _showCreateDialog,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ]),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
              const SizedBox(height: 8), Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
              const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('重试')),
            ]))
          : ListView(padding: const EdgeInsets.all(16), children: _species.map((sp) =>
              _SpeciesCard(sp: sp, onEdit: () => _showEditDialog(sp)),
            ).toList()),
      ),
    ]);
  }
}

class _SpeciesCard extends StatelessWidget {
  final SpeciesInfo sp;
  final VoidCallback onEdit;
  const _SpeciesCard({required this.sp, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(sp.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit, tooltip: '编辑'),
          ]),
          const Divider(),
          Wrap(spacing: 24, runSpacing: 8, children: [
            _Field(label: '雏鸟期', value: '0 ~ ${sp.nestlingEndDays} 天'),
            _Field(label: '幼鸟期', value: '${sp.nestlingEndDays} ~ ${sp.juvenileEndDays} 天'),
            _Field(label: '成鸟期', value: '> ${sp.juvenileEndDays} 天'),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 24, runSpacing: 8, children: [
            _Field(label: '雏鸟称重', value: '每 ${sp.nestlingWeighIntervalDays} 天', color: Colors.blue),
            _Field(label: '幼鸟称重', value: '每 ${sp.juvenileWeighIntervalDays} 天', color: Colors.teal),
            _Field(label: '成鸟称重', value: '每 ${sp.adultWeighIntervalDays} 天', color: Colors.green),
          ]),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Field({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 160, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    ]));
  }
}

// ─── Edit Dialog ───

class _EditDialog extends StatefulWidget {
  final SpeciesInfo sp;
  final void Function(String field, int value) onSave;

  const _EditDialog({required this.sp, required this.onSave});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _controllers = <String, TextEditingController>{
    'nestlingEnd': TextEditingController(text: '${widget.sp.nestlingEndDays}'),
    'juvenileEnd': TextEditingController(text: '${widget.sp.juvenileEndDays}'),
    'nestlingInterval': TextEditingController(text: '${widget.sp.nestlingWeighIntervalDays}'),
    'juvenileInterval': TextEditingController(text: '${widget.sp.juvenileWeighIntervalDays}'),
    'adultInterval': TextEditingController(text: '${widget.sp.adultWeighIntervalDays}'),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('编辑: ${widget.sp.name}'),
      content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildSection('生长阶段'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _numField('nestlingEnd', '雏鸟结束天数')),
          const SizedBox(width: 12),
          Expanded(child: _numField('juvenileEnd', '幼鸟结束天数')),
        ]),
        const SizedBox(height: 16),
        _buildSection('称重间隔'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _numField('nestlingInterval', '雏鸟 (天)')),
          const SizedBox(width: 12),
          Expanded(child: _numField('juvenileInterval', '幼鸟 (天)')),
          const SizedBox(width: 12),
          Expanded(child: _numField('adultInterval', '成鸟 (天)')),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: () {
          for (final e in _controllers.entries) {
            final v = int.tryParse(e.value.text);
            if (v == null || v <= 0) continue;
            widget.onSave(e.key, v);
          }
        }, child: const Text('保存')),
      ],
    );
  }

  Widget _buildSection(String title) => Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13));

  Widget _numField(String key, String label) {
    return TextField(
      controller: _controllers[key],
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      keyboardType: TextInputType.number,
    );
  }
}

// ─── Create Dialog ───

class _CreateDialog extends StatefulWidget {
  final void Function(String name, Map<String, int> fields) onSave;

  const _CreateDialog({required this.onSave});

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _nameCtrl = TextEditingController();
  final _controllers = <String, TextEditingController>{
    'nestlingEndDays': TextEditingController(text: '45'),
    'juvenileEndDays': TextEditingController(text: '120'),
    'nestlingWeighIntervalDays': TextEditingController(text: '1'),
    'juvenileWeighIntervalDays': TextEditingController(text: '3'),
    'adultWeighIntervalDays': TextEditingController(text: '7'),
  };
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加品种'),
      content: SizedBox(width: 400, child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '品种名称', hintText: '例如: 虎皮鹦鹉', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? '请输入品种名称' : null,
          ),
          const SizedBox(height: 16),
          const Text('生长阶段（以下均使用默认值，可后续编辑）', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _numField('nestlingEndDays', '雏鸟结束天数')),
            const SizedBox(width: 12),
            Expanded(child: _numField('juvenileEndDays', '幼鸟结束天数')),
          ]),
          const SizedBox(height: 12),
          const Text('称重间隔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _numField('nestlingWeighIntervalDays', '雏鸟 (天)')),
            const SizedBox(width: 12),
            Expanded(child: _numField('juvenileWeighIntervalDays', '幼鸟 (天)')),
            const SizedBox(width: 12),
            Expanded(child: _numField('adultWeighIntervalDays', '成鸟 (天)')),
          ]),
        ]),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          final fields = <String, int>{};
          for (final e in _controllers.entries) {
            final v = int.tryParse(e.value.text);
            if (v != null && v > 0) fields[e.key] = v;
          }
          widget.onSave(_nameCtrl.text.trim(), fields);
        }, child: const Text('创建')),
      ],
    );
  }

  Widget _numField(String key, String label) {
    return TextField(
      controller: _controllers[key],
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      keyboardType: TextInputType.number,
    );
  }
}
