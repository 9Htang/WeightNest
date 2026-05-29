import 'package:flutter/material.dart';
import '../../services/audit_log_service.dart';

/// 操作日志审计页面
class AuditLogScreen extends StatefulWidget {
  final AuditLogService service;
  final ValueNotifier<int> refreshKey;

  const AuditLogScreen({super.key, required this.service, required this.refreshKey});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  AuditLogPage? _page;
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  static const _pageSize = 30;

  String? _filterAction;
  String? _filterEntityType;
  DateTimeRange? _filterDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
    widget.refreshKey.addListener(_onRefresh);
  }

  @override
  void dispose() {
    _dateOverlay?.remove();
    widget.refreshKey.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() => _loadData();

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final page = await widget.service.fetchLogs(
        action: _filterAction,
        entityType: _filterEntityType,
        startDate: _filterDateRange?.start,
        endDate: _filterDateRange?.end,
        page: _currentPage,
        pageSize: _pageSize,
      );
      setState(() { _page = page; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilters() {
    _currentPage = 1;
    _loadData();
  }

  void _clearFilters() {
    setState(() {
      _filterAction = null;
      _filterEntityType = null;
      _filterDateRange = null;
    });
    _currentPage = 1;
    _loadData();
  }

  void _showDetail(AuditLogEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _actionColor(entry.action).withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.info_outline, size: 18, color: _actionColor(entry.action)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_dataSummary(entry),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.person_outline, '操作人', entry.userName),
              _detailRow(Icons.access_time, '时间', entry.createdAt.toLocal().toString().substring(0, 19).replaceFirst('T', ' ')),
              _detailRow(Icons.category_outlined, '操作类型', entry.actionLabel),
              _detailRow(Icons.list_alt, '数据对象', entry.entityLabel),
              const SizedBox(height: 12),
              const Text('变更明细', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatData(entry.data),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          SizedBox(width: 50, child: Text('$label:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  static const _fieldLabels = {
    'name': '名称', 'weightG': '体重(g)', 'isFasting': '空腹',
    'gender': '性别', 'ringNumber': '脚环号', 'displayName': '显示姓名',
    'username': '用户名', 'birdId': '鹦鹉ID', 'recordedAt': '记录时间',
    'speciesId': '品种ID', 'roomId': '房间ID', 'birthDate': '出生日期',
    'notes': '备注', 'status': '状态', 'role': '角色',
    'password_hash': '密码', 'isActive': '启用', 'ageDays': '日龄',
    'birdUuid': '鹦鹉UUID', 'weighIntervalDays': '称重间隔(天)',
    'nestlingEndDays': '雏鸟期(天)', 'juvenileEndDays': '幼鸟期(天)',
    'nestlingWeighIntervalDays': '雏鸟称重间隔', 'juvenileWeighIntervalDays': '幼鸟称重间隔',
    'adultWeighIntervalDays': '成鸟称重间隔', 'sortOrder': '排序',
    'assignedUserId': '指派用户', 'speciesName': '品种', 'roomName': '房间',
  };

  static String _genderLabel(dynamic g) {
    switch (g) {
      case '雄性': return '雄性';
      case '雌性': return '雌性';
      default: return '未知';
    }
  }

  static String _roleLabel(dynamic r) {
    switch (r) {
      case 'admin': return '管理员';
      case 'keeper': return '饲养员';
      default: return r?.toString() ?? '饲养员';
    }
  }

  static String _fmtDt(String s) {
    if (s.length < 19) return s;
    return '${s.substring(0, 10)} ${s.substring(11, 19)}';
  }

  String _formatValue(String key, dynamic val) {
    if (val is bool) return val ? '是' : '否';
    if (val == null) return '-';
    final s = val.toString();
    switch (key) {
      case 'gender': return _genderLabel(s);
      case 'role': return _roleLabel(s);
      case 'recordedAt': case 'birthDate': return _fmtDt(s);
      case 'isActive': return val == true || val == 1 ? '启用' : '停用';
      default: return s;
    }
  }

  /// 字段名汉化 + 值翻译
  String _formatData(Map<String, dynamic> data) {
    final buf = StringBuffer();
    for (final entry in data.entries) {
      final label = _fieldLabels[entry.key] ?? entry.key;
      buf.writeln('$label: ${_formatValue(entry.key, entry.value)}');
    }
    return buf.toString().trimRight();
  }

  Color _actionColor(String? action) {
    switch (action) {
      case 'create_bird':
      case 'create_room':
      case 'create_species':
      case 'create_user':
        return Colors.green;
      case 'update_bird':
        return Colors.orange;
      case 'add_weight':
        return Colors.blue;
      case 'edit_weight':
        return Colors.indigo;
      case 'delete_weight':
        return Colors.red;
      case 'delete_bird':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── 筛选栏 ──
        _buildFilterBar(theme),
        const Divider(height: 1),

        // ── 内容区 ──
        Expanded(child: _buildContent(theme)),
      ],
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    final hasFilter = _filterAction != null || _filterEntityType != null || _filterDateRange != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerLowest,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _buildDropdownChip<String>(
            value: _filterAction,
            hint: '操作类型',
            itemLabel: _actionFilterLabel,
            items: const ['create_bird', 'update_bird', 'add_weight', 'edit_weight', 'delete_weight', 'create_room', 'create_species', 'create_user'],
            itemName: (v) => _actionFilterLabel(v),
            onSelected: (v) { _filterAction = v; _applyFilters(); },
          ),
          const SizedBox(width: 8),
          _buildDropdownChip<String>(
            value: _filterEntityType,
            hint: '数据对象',
            itemLabel: _entityFilterLabel,
            items: const ['bird', 'weight', 'room', 'species', 'user'],
            itemName: (v) => _entityFilterLabel(v),
            onSelected: (v) { _filterEntityType = v; _applyFilters(); },
          ),
          const SizedBox(width: 8),
          _buildDateChip(),
          if (hasFilter) ...[
            const SizedBox(width: 12),
            SizedBox(
              height: 32,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('清除', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  String _actionFilterLabel(String action) {
    switch (action) {
      case 'create_bird': return '新建鹦鹉';
      case 'update_bird': return '编辑鹦鹉';
      case 'add_weight': return '记录体重';
      case 'edit_weight': return '修改体重';
      case 'delete_weight': return '删除体重';
      case 'create_room': return '新建房间';
      case 'create_species': return '新建品种';
      case 'create_user': return '新建用户';
      default: return action;
    }
  }

  String _entityFilterLabel(String type) {
    switch (type) {
      case 'bird': return '鹦鹉';
      case 'weight': return '体重';
      case 'room': return '房间';
      case 'species': return '品种';
      case 'user': return '用户';
      default: return type;
    }
  }

  Widget _buildDropdownChip<T>({
    required T? value,
    required String hint,
    required String Function(T) itemLabel,
    required String Function(T) itemName,
    required List<T> items,
    required ValueChanged<T?> onSelected,
  }) {
    final theme = Theme.of(context);
    final active = value != null;
    return PopupMenuButton<T>(
      onSelected: onSelected,
      offset: const Offset(0, 36),
      itemBuilder: (_) => [
        PopupMenuItem<T>(value: null, height: 36, child: Text('全部$hint', style: const TextStyle(fontSize: 13, color: Colors.grey))),
        ...items.map((v) => PopupMenuItem<T>(
          value: v, height: 36,
          child: Text(itemName(v), style: const TextStyle(fontSize: 13)),
        )),
      ],
      child: Material(
        color: active ? theme.colorScheme.primaryContainer : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_drop_down, size: 16,
                  color: active ? theme.colorScheme.primary : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(value != null ? itemLabel(value) : hint, style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: active ? theme.colorScheme.primary : Colors.grey.shade700,
              )),
              if (active)
                GestureDetector(
                  onTap: () => onSelected(null),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 14, color: theme.colorScheme.primary.withAlpha(180)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  final _dateLink = LayerLink();
  OverlayEntry? _dateOverlay;

  Widget _buildDateChip() {
    final theme = Theme.of(context);
    final active = _filterDateRange != null;
    return CompositedTransformTarget(
      link: _dateLink,
      child: Material(
        color: active ? theme.colorScheme.primaryContainer : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _toggleDateOverlay,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.date_range, size: 16,
                    color: active ? theme.colorScheme.primary : Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  active
                      ? '${_filterDateRange!.start.toString().substring(0, 10)} ~ ${_filterDateRange!.end.toString().substring(0, 10)}'
                      : '时间范围',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? theme.colorScheme.primary : Colors.grey.shade700,
                  ),
                ),
                if (active)
                  GestureDetector(
                    onTap: () { _filterDateRange = null; _applyFilters(); },
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 14, color: theme.colorScheme.primary.withAlpha(180)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleDateOverlay() {
    if (_dateOverlay != null) {
      _dateOverlay!.remove();
      _dateOverlay = null;
      return;
    }
    _dateOverlay = _DateRangeDropdown(
      initialRange: _filterDateRange,
      link: _dateLink,
      onApply: (range) {
        _dateOverlay?.remove();
        _dateOverlay = null;
        setState(() => _filterDateRange = range);
        _applyFilters();
      },
      onDismiss: () {
        _dateOverlay?.remove();
        _dateOverlay = null;
      },
    ).createOverlay(context);
    Overlay.of(context).insert(_dateOverlay!);
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading && _page == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade400)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_page == null || _page!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('暂无操作日志', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _page!.items.length,
            itemBuilder: (context, i) {
              final entry = _page!.items[i];
              return InkWell(
                onTap: () => _showDetail(entry),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: _actionColor(entry.action),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _actionColor(entry.action).withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(entry.actionLabel,
                                      style: TextStyle(fontSize: 11, color: _actionColor(entry.action), fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _dataSummary(entry),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 13, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  entry.createdAt.toLocal().toString().substring(0, 16).replaceFirst('T', ' '),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                                const SizedBox(width: 14),
                                Icon(Icons.person_outline, size: 13, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  entry.userName,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
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

        // ── 分页栏 ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Text('共 ${_page!.total} 条', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: _currentPage > 1 ? () { _currentPage--; _loadData(); } : null,
              ),
              Text('$_currentPage / ${_page!.totalPages}', style: const TextStyle(fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: _currentPage < _page!.totalPages ? () { _currentPage++; _loadData(); } : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _dataSummary(AuditLogEntry entry) {
    final d = entry.data;
    switch (entry.action) {
      case 'add_weight':
        final w = d['weightG'];
        final fasting = d['isFasting'] == true || d['isFasting'] == 1 ? '空腹' : '非空腹';
        return '${w ?? '?'}g（$fasting）';
      case 'edit_weight':
        final w = d['weightG'];
        final parts = <String>[];
        if (w != null) parts.add('${w}g');
        if (d['isFasting'] != null) parts.add(d['isFasting'] == true || d['isFasting'] == 1 ? '空腹' : '非空腹');
        return parts.isEmpty ? '修改记录' : parts.join(' · ');
      case 'delete_weight':
        return '已删除';
      case 'create_bird':
        final name = d['name'] ?? '?';
        final gender = _genderLabel(d['gender']);
        final species = d['speciesName'] as String?;
        final parts = <String>['「$name」'];
        if (gender != '未知') parts.add(gender);
        if (species != null && species.isNotEmpty) parts.add(species);
        return parts.join(' · ');
      case 'update_bird':
        final name = d['name'] ?? '?';
        final changes = <String>[];
        if (d['ringNumber'] != null) changes.add('脚环号 ${d['ringNumber']}');
        if (d['gender'] != null) changes.add(_genderLabel(d['gender']));
        if (d['speciesName'] != null) changes.add('品种 ${d['speciesName']}');
        if (d['status'] != null) changes.add('状态 ${d['status']}');
        if (changes.isEmpty) return '「$name」';
        return '「$name」— ${changes.join(' · ')}';
      case 'create_room':
        return '「${d['name'] ?? '?'}」';
      case 'create_species':
        return '「${d['name'] ?? '?'}」';
      case 'create_user':
        final name = d['displayName'] ?? d['username'] ?? '?';
        final role = _roleLabel(d['role']);
        return '「$name」（$role）';
      default:
        return d.toString();
    }
  }
}

class _DateRangeDropdown {
  final DateTimeRange? initialRange;
  final LayerLink link;
  final ValueChanged<DateTimeRange?> onApply;
  final VoidCallback onDismiss;

  _DateRangeDropdown({required this.initialRange, required this.link, required this.onApply, required this.onDismiss});

  OverlayEntry createOverlay(BuildContext context) {
    return OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(onTap: onDismiss, child: const ColoredBox(color: Colors.transparent)),
          ),
          CompositedTransformFollower(
            link: link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: _CompactDateRangePicker(
                initialRange: initialRange,
                onApply: onApply,
                onDismiss: onDismiss,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange?> onApply;
  final VoidCallback onDismiss;

  const _CompactDateRangePicker({this.initialRange, required this.onApply, required this.onDismiss});

  @override
  State<_CompactDateRangePicker> createState() => _CompactDateRangePickerState();
}

class _CompactDateRangePickerState extends State<_CompactDateRangePicker> {
  late int _viewYear, _viewMonth;
  DateTime? _rangeStart, _rangeEnd;
  bool _pickingEnd = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewYear = now.year;
    _viewMonth = now.month;
    _rangeStart = widget.initialRange?.start;
    _rangeEnd = widget.initialRange?.end;
    if (_rangeStart != null && _rangeEnd != null && _rangeStart != _rangeEnd) _pickingEnd = true;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _onDayTapped(DateTime day) {
    if (!_pickingEnd || _rangeStart == null) {
      _rangeStart = day;
      _rangeEnd = day;
      _pickingEnd = true;
    } else {
      if (day.isBefore(_rangeStart!)) {
        _rangeStart = day;
        _rangeEnd = _rangeStart;
      } else {
        _rangeEnd = day;
        _pickingEnd = false;
      }
    }
    setState(() {});
  }

  void _apply() {
    if (_rangeStart != null && _rangeEnd != null) {
      final start = _rangeStart!;
      final end = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day, 23, 59, 59);
      widget.onApply(start.isAfter(end) ? DateTimeRange(start: end, end: start) : DateTimeRange(start: start, end: end));
    } else {
      widget.onApply(null);
    }
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    switch (preset) {
      case 'today':
        _rangeStart = today;
        _rangeEnd = today;
        break;
      case '7d':
        _rangeStart = today.subtract(const Duration(days: 6));
        _rangeEnd = today;
        break;
      case '30d':
        _rangeStart = today.subtract(const Duration(days: 29));
        _rangeEnd = today;
        break;
      case 'month':
        _rangeStart = DateTime(now.year, now.month, 1);
        _rangeEnd = today;
        break;
    }
    _pickingEnd = false;
    setState(() {});
  }

  void _prevMonth() {
    if (_viewMonth == 1) { _viewMonth = 12; _viewYear--; } else { _viewMonth--; }
    setState(() {});
  }

  void _nextMonth() {
    if (_viewMonth == 12) { _viewMonth = 1; _viewYear++; } else { _viewMonth++; }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = _dateOnly(now);
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    final firstWeekday = DateTime(_viewYear, _viewMonth, 1).weekday % 7;
    const dayNames = ['一', '二', '三', '四', '五', '六', '日'];

    final s = _rangeStart;
    final e = _rangeEnd;
    bool inRange(DateTime d) {
      if (s == null) return false;
      if (e == null) return d == s;
      return !d.isBefore(s) && !d.isAfter(e);
    }
    bool isEdge(DateTime d) => (s != null && d == s) || (e != null && d == e);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Presets
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              _presetBtn('今天', 'today'),
              const SizedBox(width: 6),
              _presetBtn('7天', '7d'),
              const SizedBox(width: 6),
              _presetBtn('30天', '30d'),
              const SizedBox(width: 6),
              _presetBtn('本月', 'month'),
            ]),
          ),
          const SizedBox(height: 8),
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left, size: 20), visualDensity: VisualDensity.compact),
              Text('$_viewYear 年 $_viewMonth 月', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: dayNames.map((d) => Expanded(
                child: Center(child: Text(d, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600))),
              )).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // Day grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildDayGrid(daysInMonth, firstWeekday, today, inRange, isEdge, theme),
          ),
          const Divider(height: 1),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Text(
                _rangeStart != null
                    ? '${_rangeStart!.toIso8601String().substring(0, 10)}  ~  ${_rangeEnd != null ? _rangeEnd!.toIso8601String().substring(0, 10) : '...'}'
                    : '请选择日期',
                style: TextStyle(fontSize: 12, color: _rangeStart != null ? theme.colorScheme.primary : Colors.grey.shade500),
              ),
              const Spacer(),
              TextButton(onPressed: _apply, child: const Text('确定', style: TextStyle(fontSize: 13))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _presetBtn(String label, String value) {
    return SizedBox(
      height: 26,
      child: OutlinedButton(
        onPressed: () => _applyPreset(value),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildDayGrid(int days, int firstWeekday, DateTime today, bool Function(DateTime) inRange,
      bool Function(DateTime) isEdge, ThemeData theme) {
    final rows = <Widget>[];
    var day = 1;
    for (var row = 0; row < 6; row++) {
      final cells = <Widget>[];
      for (var col = 0; col < 7; col++) {
        if (row == 0 && col < firstWeekday || day > days) {
          cells.add(const Expanded(child: SizedBox(height: 32)));
        } else {
          final date = DateTime(_viewYear, _viewMonth, day);
          final selected = isEdge(date);
          final mid = inRange(date) && !selected;
          final isToday = date == today;
          cells.add(Expanded(
            child: GestureDetector(
              onTap: () => _onDayTapped(date),
              child: Container(
                height: 32,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary : mid ? theme.colorScheme.primaryContainer : null,
                  borderRadius: selected ? BorderRadius.circular(6) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : isToday ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? theme.colorScheme.onPrimary : mid ? theme.colorScheme.primary : isToday ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
            ),
          ));
          day++;
        }
      }
      rows.add(Row(children: cells));
      if (day > days) break;
    }
    return Column(children: rows);
  }
}
