import 'package:flutter/material.dart';
import '../../core/plugin.dart';
import '../../services/bird_archive_service.dart';
import '../plugins/plugins.dart';

/// 鹦鹉全息档案页面
class BirdArchiveScreen extends StatefulWidget {
  final BirdArchiveService service;
  final RoomService? roomService;
  final SpeciesService? speciesService;
  final ValueNotifier<int> refreshKey;
  final int? focusBirdId;
  final void Function(BirdInfo bird)? onBirdDragToSplit;
  final bool hideBirdList;
  final ValueNotifier<bool>? routeToRightPane;

  const BirdArchiveScreen({
    super.key,
    required this.service,
    this.roomService,
    this.speciesService,
    required this.refreshKey,
    this.focusBirdId,
    this.onBirdDragToSplit,
    this.hideBirdList = false,
    this.routeToRightPane,
  });

  @override
  State<BirdArchiveScreen> createState() => _BirdArchiveScreenState();
}

class _BirdArchiveScreenState extends State<BirdArchiveScreen> {
  List<BirdInfo> _birds = [];
  BirdInfo? _selected;
  List<WeightRecord> _weights = [];
  bool _loading = false;
  bool _loadingWeights = false;
  String? _error;
  final _searchCtrl = TextEditingController();
  double _leftPanelWidth = 280;
  double _chartHeight = 260;
  // Filters
  int? _filterRoomId;
  int? _filterSpeciesId;
  String? _filterGrowthStage;
  // Batch select
  bool _batchMode = false;
  final _selectedBirdIds = <int>{};
  // Collapsible bird list panel
  bool _panelCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadBirds();
    widget.refreshKey.addListener(_onRefresh);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    widget.refreshKey.removeListener(_onRefresh);
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _loadBirds();
    if (_selected != null) {
      await _selectBird(_selected!);
    }
  }

  Future<void> _loadBirds({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final birds = await widget.service.fetchBirds(search: search);
      setState(() { _birds = birds; _loading = false; });
      // 保留当前选中，或优先 focusBirdId，否则选第一只
      if (_selected != null) {
        final updated = birds.where((b) => b.id == _selected!.id).firstOrNull;
        if (updated != null) _selected = updated;
      } else if (widget.focusBirdId != null) {
        final target = birds.where((b) => b.id == widget.focusBirdId).firstOrNull;
        if (target != null) {
          _selectBird(target);
        } else if (birds.isNotEmpty) {
          _selectBird(birds.first);
        }
      } else if (birds.isNotEmpty) {
        _selectBird(birds.first);
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _selectBird(BirdInfo bird) async {
    setState(() { _selected = bird; _loadingWeights = true; });
    final targetId = bird.id;
    try {
      final weights = await widget.service.fetchWeights(bird.id);
      if (!mounted || _selected?.id != targetId) return;
      setState(() { _weights = weights; _loadingWeights = false; });
    } catch (_) {
      if (!mounted || _selected?.id != targetId) return;
      setState(() { _weights = []; _loadingWeights = false; });
    }
  }

  void _search() {
    _loadBirds(search: _searchCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.hideBirdList) {
      return _selected == null ? _buildEmpty() : _buildDetail(theme);
    }

    final scheme = theme.colorScheme;

    return Row(
      children: [
        if (_panelCollapsed)
          _buildCollapsedPanel(scheme)
        else
          SizedBox(
            width: _leftPanelWidth,
            child: Column(children: [
              _buildPanelHeader(theme),
              const Divider(height: 1),
              _buildBirdList(theme),
            ]),
          ),
        _buildSplitter(),
        Expanded(child: _selected == null ? _buildEmpty() : _buildDetail(theme)),
      ],
    );
  }

  Widget _buildCollapsedPanel(ColorScheme scheme) {
    return GestureDetector(
      onTap: () => setState(() => _panelCollapsed = false),
      child: Container(
        width: 32,
        color: scheme.surfaceContainerLow,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(Icons.chevron_right, size: 18, color: scheme.onSurface.withAlpha(120)),
            const Spacer(),
            RotatedBox(
              quarterTurns: 1,
              child: Text('鹦鹉列表',
                  style: TextStyle(fontSize: 11, color: scheme.onSurface.withAlpha(100))),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelHeader(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: scheme.surface,
      child: Row(children: [
        Expanded(
          child: Text('鹦鹉列表',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 18),
          tooltip: '折叠面板',
          onPressed: () => setState(() => _panelCollapsed = true),
          splashRadius: 14,
        ),
      ]),
    );
  }

  Widget _buildBirdList(ThemeData theme) {
    return Expanded(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '搜索名称/脚环号...',
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _search();
                      })
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        _buildFilterBar(theme),
        const Divider(height: 1),
        if (_batchMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.primaryContainer.withAlpha(60),
            child: Row(children: [
              Text('已选 ${_selectedBirdIds.length} 只', style: const TextStyle(fontSize: 12)),
              const Spacer(),
              TextButton(
                  onPressed: _batchPublishTasks,
                  child: const Text('发布任务', style: TextStyle(fontSize: 12))),
              TextButton(
                  onPressed: _batchChangeRoom,
                  child: const Text('批量改房间', style: TextStyle(fontSize: 12))),
              TextButton(
                  onPressed: () => setState(() {
                        _batchMode = false;
                        _selectedBirdIds.clear();
                      }),
                  child: const Text('取消', style: TextStyle(fontSize: 12))),
            ]),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _filteredBirds.isEmpty
                      ? Center(child: Text('暂无鹦鹉', style: TextStyle(color: Colors.grey.shade400)))
                      : ListView.builder(
                          itemCount: _filteredBirds.length,
                          itemBuilder: (context, i) => _buildBirdTile(theme, i),
                        ),
        ),
      ]),
    );
  }

  Widget _buildBirdTile(ThemeData theme, int i) {
    final bird = _filteredBirds[i];
    final isSelected = _selected?.id == bird.id;

    final onTapHandler = _batchMode
        ? () => setState(() {
              if (_selectedBirdIds.contains(bird.id)) {
                _selectedBirdIds.remove(bird.id);
              } else {
                _selectedBirdIds.add(bird.id);
              }
            })
        : () {
            if (widget.routeToRightPane != null &&
                widget.routeToRightPane!.value &&
                widget.onBirdDragToSplit != null) {
              widget.onBirdDragToSplit!(bird);
            } else {
              _selectBird(bird);
            }
          };

    final tile = ListTile(
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withAlpha(80),
      dense: true,
      leading: _batchMode
          ? Checkbox(
              value: _selectedBirdIds.contains(bird.id),
              onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedBirdIds.add(bird.id);
                    } else {
                      _selectedBirdIds.remove(bird.id);
                    }
                  }),
            )
          : CircleAvatar(
              radius: 16,
              backgroundColor:
                  isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
              child: Text(
                bird.name.isNotEmpty ? bird.name[0] : '?',
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontSize: 13),
              ),
            ),
      title:
          Text(bird.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${bird.speciesName}  ${bird.gender}  ${bird.ageDays}天  ${_growthLabel(bird.ageDays)}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!_batchMode)
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            tooltip: '编辑',
            onPressed: () => _showEditBirdDialog(bird),
          ),
        if (bird.ringNumber != null)
          Text(bird.ringNumber!,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ]),
      onTap: onTapHandler,
    );

    if (_batchMode || widget.onBirdDragToSplit == null) return tile;

    return LongPressDraggable<BirdInfo>(
      data: bird,
      delay: const Duration(milliseconds: 150),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragEnd: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.offset.dx > screenWidth * 0.55) {
          widget.onBirdDragToSplit!(bird);
        }
      },
      onDraggableCanceled: (_, offset) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (offset.dx > screenWidth * 0.55) {
          widget.onBirdDragToSplit!(bird);
        }
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.pets, size: 18,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              bird.ringNumber ?? bird.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: tile,
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 36, color: Colors.red.shade300),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => _loadBirds(), child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('选择一只鹦鹉查看详情', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDetail(ThemeData theme) {
    final bird = _selected!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 基本信息卡片 (主 App 负责) ──
          _buildInfoCard(theme, bird),
          const SizedBox(height: 20),

          // ── 插件贡献的详情区块 (动态渲染) ──
          for (final plugin in pluginRegistry.enabledPlugins)
            for (final section in plugin.buildDetailSections(bird.id))
              _buildPluginSection(section, theme),
        ],
      ),
    );
  }

  Widget _buildPluginSection(DetailSection s, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: s.defaultExpanded,
        title: Row(children: [
          if (s.icon != null) Icon(s.icon, size: 18),
          if (s.icon != null) const SizedBox(width: 8),
          Text(s.title, style: theme.textTheme.titleSmall),
        ]),
        children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: s.child)],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, BirdInfo bird) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(bird.name[0], style: const TextStyle(fontSize: 20, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bird.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${bird.speciesName} · ${bird.gender}', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bird.status == '正常' ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(bird.status, style: TextStyle(fontSize: 12, color: bird.status == '正常' ? Colors.green : Colors.orange)),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 32,
              runSpacing: 12,
              children: [
                _infoItem('脚环号', bird.ringNumber ?? '-'),
                _infoItem('品种', bird.speciesName),
                _infoItem('房间', bird.roomName ?? '-'),
                _infoItem('日龄', '${bird.ageDays} 天'),
                _infoItem('出生日期', bird.birthDate.toString().substring(0, 10)),
              ],
            ),
            if (bird.notes != null && bird.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('备注: ${bird.notes}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 12),
            // Weigh interval override — only shown when server data is available
            _buildIntervalSelector(theme, bird),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSelector(ThemeData theme, BirdInfo bird) {
    // The BirdInfo doesn't carry weighIntervalDays from the server API yet.
    // Show a simple dropdown. The actual value would need an API change to include it.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(children: [
        const Icon(Icons.schedule, size: 16, color: Colors.blue),
        const SizedBox(width: 8),
        const Text('称重间隔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const Spacer(),
        PopupMenuButton<int>(
          initialValue: null,
          tooltip: '设置单只称重间隔',
          onSelected: (v) => _updateBirdInterval(bird.id, v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 0, child: Text('跟随品种默认')),
            const PopupMenuItem(value: 1, child: Text('每天 (生病/观察)')),
            const PopupMenuItem(value: 3, child: Text('每 3 天')),
            const PopupMenuItem(value: 7, child: Text('每 7 天')),
            const PopupMenuItem(value: 14, child: Text('每 14 天')),
          ],
          child: Chip(
            label: const Text('修改', style: TextStyle(fontSize: 11)),
            backgroundColor: Colors.blue.shade100,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ]),
    );
  }

  Future<void> _updateBirdInterval(int birdId, int days) async {
    try {
      await widget.service.updateBird(birdId, weighIntervalDays: days == 0 ? null : days);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(days == 0 ? '已恢复品种默认间隔' : '已设为每 $days 天称重'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _infoItem(String label, String value) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildWeightTable(ThemeData theme) {
    if (_weights.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, size: 18),
                const SizedBox(width: 6),
                Text('体重记录', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _weights.length,
                itemBuilder: (context, i) {
                  final w = _weights[i];
                  // Determine if this entry is a decline from the previous
                  final prev = i + 1 < _weights.length ? _weights[i + 1] : null;
                  final isDecline = prev != null && w.weightG < prev.weightG;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        if (isDecline)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.trending_down, size: 14, color: Colors.red.shade400),
                          )
                        else
                          const SizedBox(width: 20),
                        Expanded(
                          child: Text(w.recordedAt.toString().substring(0, 19).replaceAll('T', ' '),
                              style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                        ),
                        const Spacer(),
                        Text('${w.weightG.toStringAsFixed(1)} g',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: isDecline ? Colors.red.shade700 : (w.isFasting ? Theme.of(context).colorScheme.primary : Colors.orange))),
                        if (!w.isFasting)
                          const Text(' *', style: TextStyle(fontSize: 11, color: Colors.orange)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Trend splitting for red/green chart segments ───

  List<BirdInfo> get _filteredBirds {
    return _birds.where((b) {
      if (_filterRoomId != null && b.roomId != _filterRoomId) return false;
      if (_filterSpeciesId != null && b.speciesId != _filterSpeciesId) return false;
      if (_filterGrowthStage != null && _growthLabel(b.ageDays) != _filterGrowthStage) return false;
      if (_searchCtrl.text.isNotEmpty) {
        final q = _searchCtrl.text.toLowerCase();
        if (!b.name.toLowerCase().contains(q) && (b.ringNumber == null || !b.ringNumber!.toLowerCase().contains(q))) return false;
      }
      return true;
    }).toList();
  }

  String _growthLabel(int ageDays) {
    // Use a simplified stage check — real stages would need species info
    if (ageDays <= 45) return '雏鸟';
    if (ageDays <= 120) return '幼鸟';
    return '成鸟';
  }

  Widget _buildFilterBar(ThemeData theme) {
    // Collect unique rooms and species from loaded birds
    final rooms = <int, String>{};
    final species = <int, String>{};
    for (final b in _birds) {
      if (b.roomId != null && b.roomName != null) rooms[b.roomId!] = b.roomName!;
      species[b.speciesId] = b.speciesName;
    }
    final stages = ['雏鸟', '幼鸟', '成鸟'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('筛选', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
          if (_filterRoomId != null || _filterSpeciesId != null || _filterGrowthStage != null)
            GestureDetector(
              onTap: () => setState(() { _filterRoomId = null; _filterSpeciesId = null; _filterGrowthStage = null; }),
              child: Text('清除', style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
            ),
          const Spacer(),
          if (_birds.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() { _batchMode = !_batchMode; _selectedBirdIds.clear(); }),
              icon: Icon(Icons.checklist, size: 14),
              label: Text(_batchMode ? '退出批量' : '批量操作', style: const TextStyle(fontSize: 10)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            ),
        ]),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _buildFilterChip('房间', rooms, _filterRoomId, (v) => setState(() => _filterRoomId = v)),
            const SizedBox(width: 4),
            _buildFilterChip('品种', species, _filterSpeciesId, (v) => setState(() => _filterSpeciesId = v)),
            const SizedBox(width: 4),
            _buildFilterChip('阶段', {for (final s in stages) s.hashCode: s}, _filterGrowthStage?.hashCode, (v) {
              final idx = stages.indexWhere((s) => s.hashCode == v);
              setState(() => _filterGrowthStage = idx >= 0 ? stages[idx] : null);
            }),
          ]),
        ),
      ]),
    );
  }

  Widget _buildFilterChip(String label, Map<int, String> options, int? selected, void Function(int?) onSelect) {
    return PopupMenuButton<int?>(
      tooltip: label,
      onSelected: (v) => onSelect(v),
      itemBuilder: (_) => [
        PopupMenuItem(value: null, child: Text('全部$label', style: const TextStyle(fontSize: 12))),
        ...options.entries.map((e) => PopupMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12)))),
      ],
      child: Chip(
        label: Text(selected != null ? (options[selected] ?? label) : label, style: TextStyle(fontSize: 10, color: selected != null ? Colors.white : null)),
        backgroundColor: selected != null ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _showEditBirdDialog(BirdInfo bird) async {
    // Fetch full bird list for room/species options
    final nameCtrl = TextEditingController(text: bird.name);
    final ringCtrl = TextEditingController(text: bird.ringNumber ?? '');
    int? roomId = bird.roomId;
    int? speciesId = bird.speciesId;
    String status = bird.status;
    String? notes = bird.notes;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text('编辑: ${bird.name}'),
        content: SizedBox(width: 360, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称', isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: ringCtrl, decoration: const InputDecoration(labelText: '脚环号', isDense: true)),
          const SizedBox(height: 10),
          // Room dropdown — need to fetch options
          FutureBuilder<List<RoomInfo>>(
            future: widget.roomService?.fetchAll(),
            builder: (_, snap) {
              final rooms = snap.data ?? [];
              return DropdownButtonFormField<int?>(
                value: roomId, isDense: true,
                decoration: const InputDecoration(labelText: '房间'),
                items: [const DropdownMenuItem(value: null, child: Text('无')), ...rooms.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))],
                onChanged: (v) => setD(() => roomId = v),
              );
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<SpeciesInfo>>(
            future: widget.speciesService?.fetchAll(),
            builder: (_, snap) {
              final spList = snap.data ?? [];
              return DropdownButtonFormField<int?>(
                value: speciesId, isDense: true,
                decoration: const InputDecoration(labelText: '品种'),
                items: spList.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setD(() => speciesId = v),
              );
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: status, isDense: true,
            decoration: const InputDecoration(labelText: '状态'),
            items: ['正常', '偏瘦', '偏胖', '生病', '换羽', '已离舍'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setD(() => status = v!),
          ),
          const SizedBox(height: 8),
          TextField(controller: TextEditingController(text: notes ?? ''), decoration: const InputDecoration(labelText: '备注', isDense: true),
            maxLines: 2, onChanged: (v) => notes = v),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () async {
            try {
              await widget.service.updateBird(bird.id, name: nameCtrl.text.trim(),
                ringNumber: ringCtrl.text.trim(), roomId: roomId, speciesId: speciesId, status: status, notes: notes);
              Navigator.pop(ctx, true);
            } catch (e) {
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('保存失败: $e'), behavior: SnackBarBehavior.floating));
            }
          }, child: const Text('保存')),
        ],
      )),
    );
    if (ok == true) _loadBirds();
  }

  Future<void> _batchPublishTasks() async {
    if (_selectedBirdIds.isEmpty) return;
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('发布称重任务 (${_selectedBirdIds.length} 只)'),
          content: const Text('将为选中的鹦鹉发布今日称重任务。\n即使今天已有任务，手机端也会收到新的任务通知。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认发布')),
          ],
        ),
      );
      if (ok != true) return;

      await widget.service.publishTasks(_selectedBirdIds.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已为 ${_selectedBirdIds.length} 只鹦鹉发布称重任务'), behavior: SnackBarBehavior.floating),
        );
        _selectedBirdIds.clear();
        _batchMode = false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('网络错误: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _batchChangeRoom() async {
    if (_selectedBirdIds.isEmpty) return;
    int? roomId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text('批量修改房间 (${_selectedBirdIds.length} 只)'),
        content: FutureBuilder<List<RoomInfo>>(
          future: widget.roomService?.fetchAll(),
          builder: (_, snap) {
            final rooms = snap.data ?? [];
            return DropdownButtonFormField<int?>(
              value: roomId, isDense: true,
              decoration: const InputDecoration(labelText: '目标房间'),
              items: [const DropdownMenuItem(value: null, child: Text('清除房间')), ...rooms.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))],
              onChanged: (v) => setD(() => roomId = v),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认修改')),
        ],
      )),
    );
    if (ok != true) return;
    try {
      for (final id in _selectedBirdIds) {
        await widget.service.updateBird(id, roomId: roomId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已更新 ${_selectedBirdIds.length} 只鹦鹉'), behavior: SnackBarBehavior.floating),
        );
      }
      _selectedBirdIds.clear();
      _batchMode = false;
      _loadBirds();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('批量修改失败: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  Widget _buildSplitter() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) {
        setState(() {
          _leftPanelWidth = (_leftPanelWidth + d.delta.dx).clamp(200, 500);
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 5,
          color: Colors.transparent,
          child: Center(
            child: Container(width: 1, color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }


}

