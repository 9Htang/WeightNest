import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/debug_log_sink.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  Timer? _timer;
  String _query = '';
  String _tag = '';
  final _searchCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  bool _autoScroll = true;

  List<String> get _availableTags {
    final tags = <String>{};
    for (final e in DebugLogSink.entries) {
      final m = e.message;
      if (m.startsWith('[')) {
        final end = m.indexOf(']');
        if (end > 1 && end < 40) {
          tags.add(m.substring(0, end + 1));
        }
      }
    }
    return tags.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  List<LogEntry> get _filtered => DebugLogSink.filter(tag: _tag, query: _query);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日志查看器'),
        actions: [
          IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清空',
              onPressed: () => setState(() => DebugLogSink.clear())),
          IconButton(
            icon: Icon(_autoScroll
                ? Icons.vertical_align_bottom
                : Icons.vertical_align_top),
            tooltip: _autoScroll ? '自动滚动: 开' : '自动滚动: 关',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchCtl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: '搜索日志...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty || _tag.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtl.clear();
                          setState(() {
                            _query = '';
                            _tag = '';
                          });
                        })
                    : null,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),

          // Tag filter chips
          if (_availableTags.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _availableTags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final t = _availableTags[i];
                  final selected = _tag == t;
                  return ChoiceChip(
                    label: Text(t,
                        style:
                            TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    selected: selected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _tag = selected ? '' : t),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // Log entries
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      _query.isNotEmpty || _tag.isNotEmpty ? '无匹配日志' : '暂无日志',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(120)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtl,
                    itemCount: entries.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final ts = e.timestamp;
                      final time =
                          '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}.${ts.millisecond.toString().padLeft(3, '0')}';

                      Color? bg;
                      if (e.message.contains('[ERROR]')) {
                        bg = theme.colorScheme.error.withAlpha(12);
                      } else if (e.message.contains('[WARN')) {
                        bg = Colors.orange.withAlpha(12);
                      }

                      return InkWell(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: e.message));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('已复制'),
                                duration: Duration(seconds: 1)),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          color: bg,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(120),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.message,
                                  style: const TextStyle(
                                      fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.surfaceContainerLow,
            child: Text(
              '${entries.length} 条${_query.isNotEmpty || _tag.isNotEmpty ? " (已过滤)" : ""}  ·  缓冲区 ${DebugLogSink.entries.length}/${DebugLogSink.entries.length + 1} 条',
              style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withAlpha(120)),
            ),
          ),
        ],
      ),
    );
  }
}
