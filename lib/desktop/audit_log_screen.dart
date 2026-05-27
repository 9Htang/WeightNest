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
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 8),
            Text('${entry.actionLabel} — ${entry.entityLabel}'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('操作人', entry.userName),
              _detailRow('操作类型', entry.actionLabel),
              _detailRow('数据对象', entry.entityLabel),
              _detailRow('UUID', entry.entityUuid),
              _detailRow('时间', entry.createdAt.toLocal().toString().substring(0, 19)),
              const SizedBox(height: 12),
              const Text('变更明细', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 56, child: Text('$label:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  String _formatData(Map<String, dynamic> data) {
    final buf = StringBuffer();
    for (final entry in data.entries) {
      buf.writeln('${entry.key}: ${entry.value}');
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.filter_list, size: 18),
          const Text('筛选:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          // 操作类型
          DropdownMenu<String?>(
            initialSelection: _filterAction,
            hintText: '操作类型',
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: null, label: '全部'),
              DropdownMenuEntry(value: 'create_bird', label: '新建鹦鹉'),
              DropdownMenuEntry(value: 'update_bird', label: '编辑鹦鹉'),
              DropdownMenuEntry(value: 'add_weight', label: '记录体重'),
              DropdownMenuEntry(value: 'create_room', label: '新建房间'),
              DropdownMenuEntry(value: 'create_species', label: '新建品种'),
              DropdownMenuEntry(value: 'create_user', label: '新建用户'),
            ],
            onSelected: (v) {
              _filterAction = v;
              _applyFilters();
            },
          ),
          // 数据对象
          DropdownMenu<String?>(
            initialSelection: _filterEntityType,
            hintText: '数据对象',
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: null, label: '全部'),
              DropdownMenuEntry(value: 'bird', label: '鹦鹉'),
              DropdownMenuEntry(value: 'weight', label: '体重'),
              DropdownMenuEntry(value: 'room', label: '房间'),
              DropdownMenuEntry(value: 'species', label: '品种'),
              DropdownMenuEntry(value: 'user', label: '用户'),
            ],
            onSelected: (v) {
              _filterEntityType = v;
              _applyFilters();
            },
          ),
          // 时间范围
          ActionChip(
            avatar: const Icon(Icons.date_range, size: 16),
            label: Text(_filterDateRange == null
                ? '时间范围'
                : '${_filterDateRange!.start.toString().substring(0, 10)} ~ ${_filterDateRange!.end.toString().substring(0, 10)}'),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                locale: const Locale('zh'),
              );
              if (range != null) {
                setState(() => _filterDateRange = range);
                _applyFilters();
              }
            },
          ),
          if (hasFilter)
            ActionChip(
              avatar: const Icon(Icons.clear, size: 16),
              label: const Text('清除筛选'),
              onPressed: _clearFilters,
            ),
        ],
      ),
    );
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _actionColor(entry.action),
                          shape: BoxShape.circle,
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
                                      style: TextStyle(fontSize: 12, color: _actionColor(entry.action), fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                                Text(entry.entityLabel,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _dataSummary(entry),
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(entry.userName, style: const TextStyle(fontSize: 12)),
                          Text(
                            entry.createdAt.toLocal().toString().substring(11, 19),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
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
      case 'create_bird':
      case 'update_bird':
        return '${d['name'] ?? '?'}  ${d['gender'] ?? ''}';
      case 'add_weight':
        return '${d['weightG'] ?? '?'}g  ${d['isFasting'] == true ? '空腹' : '非空腹'}';
      case 'create_room':
      case 'create_species':
        return d['name'] ?? '';
      case 'create_user':
        return d['displayName'] ?? d['username'] ?? '';
      default:
        return d.toString();
    }
  }
}
