import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Variable;
import '../../core/plugin_registry.dart';

class DbInspectorScreen extends StatefulWidget {
  const DbInspectorScreen({super.key});

  @override
  State<DbInspectorScreen> createState() => _DbInspectorScreenState();
}

class _DbInspectorScreenState extends State<DbInspectorScreen> {
  List<String> _tableNames = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _rows = [];
  bool _loadingTables = true;
  bool _loadingRows = false;
  String? _error;

  // Custom SQL
  final _sqlCtl = TextEditingController();
  List<Map<String, dynamic>> _queryResult = [];
  String? _queryError;
  bool _writeMode = false;
  bool _queryRunning = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _sqlCtl.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    final db = pluginRegistry.db;
    if (db == null) {
      setState(() {
        _loadingTables = false;
        _error = '数据库未初始化';
      });
      return;
    }
    try {
      final result = await db.customSelect(
        'SELECT name FROM sqlite_master WHERE type = ? ORDER BY name',
        variables: [const Variable('table')],
      ).get();
      setState(() {
        _tableNames = result.map((r) => r.data['name'] as String).toList();
        _loadingTables = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loadingTables = false;
        _error = '$e';
      });
    }
  }

  Future<void> _loadRows(String table) async {
    final db = pluginRegistry.db!;
    setState(() {
      _selectedTable = table;
      _loadingRows = true;
      _error = null;
    });
    try {
      final result =
          await db.customSelect('SELECT * FROM "$table" LIMIT 100').get();
      setState(() {
        _rows = result.map((r) => Map<String, dynamic>.from(r.data)).toList();
        _loadingRows = false;
      });
    } catch (e) {
      setState(() {
        _loadingRows = false;
        _error = '$e';
      });
    }
  }

  bool _isReadOnly(String sql) {
    final t = sql.trim().toUpperCase();
    return t.startsWith('SELECT') ||
        t.startsWith('PRAGMA') ||
        t.startsWith('EXPLAIN');
  }

  Future<void> _runQuery() async {
    final db = pluginRegistry.db!;
    final sql = _sqlCtl.text.trim();
    if (sql.isEmpty) return;

    if (!_writeMode && !_isReadOnly(sql)) {
      setState(() {
        _queryError = '只读模式：仅允许 SELECT / PRAGMA / EXPLAIN。开启"写模式"以执行修改操作。';
      });
      return;
    }

    setState(() {
      _queryRunning = true;
      _queryError = null;
      _queryResult = [];
    });
    try {
      if (_isReadOnly(sql)) {
        final result = await db.customSelect(sql).get();
        _queryResult =
            result.map((r) => Map<String, dynamic>.from(r.data)).toList();
      } else {
        // Confirm before write
        await db.customStatement(sql);
        _queryResult = [
          {'result': 'OK — 语句已执行'}
        ];
      }
    } catch (e) {
      setState(() {
        _queryError = '$e';
      });
    } finally {
      setState(() {
        _queryRunning = false;
      });
    }
  }

  String _toTsv(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    final keys = rows.first.keys.toList();
    final buf = StringBuffer();
    buf.writeln(keys.join('\t'));
    for (final row in rows) {
      buf.writeln(keys.map((k) => _fmtCell(row[k], columnName: k)).join('\t'));
    }
    return buf.toString();
  }

  Future<void> _copyRows(List<Map<String, dynamic>> rows) async {
    final tsv = _toTsv(rows);
    if (tsv.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: tsv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('已复制 ${rows.length} 行数据到剪贴板'),
            duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('数据库检查器')),
      body: Column(
        children: [
          // ── Section 1: Table Browser ──
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: theme.colorScheme.error.withAlpha(20),
              child: Text(_error!,
                  style:
                      TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text('表列表', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (_rows.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyRows(_rows),
                    tooltip: '复制全部数据 (TSV)',
                  ),
                IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _loadTables,
                    tooltip: '刷新'),
              ],
            ),
          ),
          if (_loadingTables)
            const LinearProgressIndicator()
          else
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _tableNames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _tableNames[i];
                  final selected = t == _selectedTable;
                  return ChoiceChip(
                    label: Text(t, style: TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => _loadRows(t),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          if (_loadingRows)
            const LinearProgressIndicator()
          else if (_rows.isNotEmpty)
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerLow),
                    columnSpacing: 24,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 48,
                    columns: _rows.first.keys
                        .map((k) => DataColumn(
                            label: Text(k,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12))))
                        .toList(),
                    rows: _rows
                        .map((r) => DataRow(
                              cells: r.entries
                                  .map((e) => DataCell(
                                        Text(
                                          _fmtCell(e.value, columnName: e.key),
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),

          const Divider(height: 1),

          // ── Section 2: Custom Query ──
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('自定义 SQL', style: theme.textTheme.titleSmall),
                      if (_queryResult.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () => _copyRows(_queryResult),
                          tooltip: '复制查询结果 (TSV)',
                          visualDensity: VisualDensity.compact,
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Text('写模式',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _writeMode
                                      ? theme.colorScheme.error
                                      : null)),
                          Switch(
                            value: _writeMode,
                            onChanged: (v) => setState(() => _writeMode = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextField(
                    controller: _sqlCtl,
                    maxLines: 3,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'SELECT * FROM birds LIMIT 10',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.all(8),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: FilledButton.icon(
                      onPressed: _queryRunning ? null : _runQuery,
                      icon: _queryRunning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_arrow, size: 18),
                      label: const Text('执行'),
                    ),
                  ),
                  if (_queryError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: theme.colorScheme.error.withAlpha(60)),
                      ),
                      child: Text(
                        _queryError!,
                        style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                            fontFamily: 'monospace'),
                      ),
                    ),
                  if (_queryResult.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                                theme.colorScheme.surfaceContainerLow),
                            columnSpacing: 20,
                            dataRowMinHeight: 28,
                            columns: _queryResult.first.keys
                                .map((k) => DataColumn(
                                    label: Text(k,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11))))
                                .toList(),
                            rows: _queryResult
                                .map((r) => DataRow(
                                      cells: r.entries
                                          .map((e) => DataCell(
                                                Text(
                                                    _fmtCell(e.value,
                                                        columnName: e.key),
                                                    style: const TextStyle(
                                                        fontSize: 11),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ))
                                          .toList(),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Drift stores datetime as `YYYY-MM-DD HH:MM:SS.000` (TEXT).
  static final _driftTimeRe =
      RegExp(r'^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2})(:\d{2}(?:\.\d+)?)?$');

  /// Column names that are likely to contain timestamps / dates.
  bool _isTimeColumn(String? col) {
    if (col == null) return false;
    final lower = col.toLowerCase();
    return lower.contains('at') ||
        lower.contains('date') ||
        lower.contains('time') ||
        lower == 'deadline' ||
        lower == 'birthdate' ||
        lower == 'createdat' ||
        lower == 'updatedat' ||
        lower == 'deletedat' ||
        lower == 'recordedat' ||
        lower == 'completedat' ||
        lower == 'dueDate'; // Drift lowercases in customSelect, but be safe
  }

  String _fmtCell(dynamic v, {String? columnName}) {
    if (v == null) return 'NULL';
    if (v is DateTime) {
      final y = v.year,
          m = v.month.toString().padLeft(2, '0'),
          d = v.day.toString().padLeft(2, '0');
      final hh = v.hour.toString().padLeft(2, '0'),
          mm = v.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm';
    }
    // Drift datetime string: "2025-06-22 08:30:00.000" or "2025-06-22 08:30:00"
    if (v is String) {
      final m = _driftTimeRe.firstMatch(v);
      if (m != null) {
        // m[1] = date, m[2] = HH:MM, m[3] = :SS.xxx (optional)
        if (m[3] != null) {
          return '${m[1]} ${m[2]}${m[3]}';
        }
        return '${m[1]} ${m[2]}';
      }
    }
    // Unix timestamp integer (10-digit seconds or 13-digit millis) — only if column looks like time
    if (v is int && _isTimeColumn(columnName)) {
      if (v > 1e12 && v < 2e13) {
        // milliseconds
        final dt = DateTime.fromMillisecondsSinceEpoch(v);
        return _fmtCell(dt);
      }
      if (v > 1e9 && v < 2e10) {
        // seconds
        final dt = DateTime.fromMillisecondsSinceEpoch(v * 1000);
        return _fmtCell(dt);
      }
    }
    return v.toString();
  }
}
