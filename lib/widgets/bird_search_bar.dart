import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../plugins/stage/stage_constants.dart';
import '../providers.dart';

/// Combined search bar + multi-field filter chips for bird lists.
///
/// Each section is controlled by a boolean `show*` param.
/// Calls [onChanged] with the complete filter state whenever anything changes.
class BirdSearchBar extends ConsumerStatefulWidget {
  final bool showSearchBox;
  final bool showGenderFilter;
  final bool showSpeciesFilter;
  final bool showStageFilter;
  final bool showRoomFilter;
  final String? searchHint;
  final void Function({
    required String searchText,
    required Set<String> genders,
    required Set<int> speciesIds,
    required Set<String> stages,
    required Set<int> roomIds,
  }) onChanged;

  const BirdSearchBar({
    super.key,
    this.showSearchBox = true,
    this.showGenderFilter = false,
    this.showSpeciesFilter = false,
    this.showStageFilter = false,
    this.showRoomFilter = false,
    this.searchHint,
    required this.onChanged,
  });

  @override
  ConsumerState<BirdSearchBar> createState() => _BirdSearchBarState();
}

class _BirdSearchBarState extends ConsumerState<BirdSearchBar> {
  final _searchCtrl = TextEditingController();
  var _genderFilter = <String>{};
  var _speciesFilter = <int>{};
  var _stageFilter = <String>{};
  var _roomFilter = <int>{};

  static const _genderLabels = ['公', '母', '未知'];

  bool get _hasAnyFilter =>
      _genderFilter.isNotEmpty ||
      _speciesFilter.isNotEmpty ||
      _stageFilter.isNotEmpty ||
      _roomFilter.isNotEmpty;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      searchText: _searchCtrl.text,
      genders: _genderFilter,
      speciesIds: _speciesFilter,
      stages: _stageFilter,
      roomIds: _roomFilter,
    );
  }

  void _clearAll() {
    setState(() {
      _searchCtrl.clear();
      _genderFilter = {};
      _speciesFilter = {};
      _stageFilter = {};
      _roomFilter = {};
    });
    _emit();
  }

  bool get _hasAnyWidget =>
      widget.showSearchBox ||
      widget.showGenderFilter ||
      widget.showSpeciesFilter ||
      widget.showStageFilter ||
      widget.showRoomFilter;

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyWidget) return const SizedBox.shrink();

    final speciesAsync = ref.watch(allSpeciesProvider);
    final roomsAsync = ref.watch(allRoomsProvider);
    final speciesList = speciesAsync.valueOrNull ?? <Specy>[];
    final roomList = roomsAsync.valueOrNull ?? <Room>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search box
        if (widget.showSearchBox)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: widget.searchHint ?? '搜索名称或脚环号...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _emit();
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (_) => _emit(),
            ),
          ),

        // Filter chips
        if (widget.showGenderFilter ||
            widget.showSpeciesFilter ||
            widget.showStageFilter ||
            widget.showRoomFilter)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (widget.showSpeciesFilter) ...[
                    _buildFilterChip(
                      label: '品种',
                      selected: _speciesFilter.isNotEmpty,
                      displayText: _speciesFilter.isEmpty
                          ? null
                          : _speciesFilter.length == 1
                              ? speciesList
                                  .where(
                                      (s) => _speciesFilter.contains(s.id))
                                  .firstOrNull
                                  ?.name
                              : '${_speciesFilter.length}个品种',
                      onTap: () => _showMultiSelectSheet<int>(
                        title: '选择品种',
                        items: speciesList.map((s) => s.id).toList(),
                        selectedIds: _speciesFilter,
                        labelOf: (id) => speciesList
                            .firstWhere((s) => s.id == id)
                            .name,
                        onConfirm: (ids) {
                          setState(() => _speciesFilter = ids);
                          _emit();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.showStageFilter) ...[
                    _buildFilterChip(
                      label: '阶段',
                      selected: _stageFilter.isNotEmpty,
                      displayText: _stageFilter.isEmpty
                          ? null
                          : _stageFilter.length == 1
                              ? _stageFilter.first
                              : '${_stageFilter.length}个阶段',
                      onTap: () => _showMultiSelectSheet<String>(
                        title: '选择生理阶段',
                        items: RecipeStage.all,
                        selectedIds: _stageFilter,
                        labelOf: (s) => s,
                        onConfirm: (ids) {
                          setState(() => _stageFilter = ids);
                          _emit();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.showGenderFilter) ...[
                    _buildFilterChip(
                      label: '性别',
                      selected: _genderFilter.isNotEmpty,
                      displayText: _genderFilter.isEmpty
                          ? null
                          : _genderFilter.length == 1
                              ? _genderFilter.first
                              : '${_genderFilter.length}种性别',
                      onTap: () => _showMultiSelectSheet<String>(
                        title: '选择性别',
                        items: _genderLabels,
                        selectedIds: _genderFilter,
                        labelOf: (g) => g,
                        onConfirm: (ids) {
                          setState(() => _genderFilter = ids);
                          _emit();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.showRoomFilter) ...[
                    _buildFilterChip(
                      label: '房间',
                      selected: _roomFilter.isNotEmpty,
                      displayText: _roomFilter.isEmpty
                          ? null
                          : _roomFilter.length == 1
                              ? roomList
                                  .where(
                                      (r) => _roomFilter.contains(r.id))
                                  .firstOrNull
                                  ?.name
                              : '${_roomFilter.length}个房间',
                      onTap: () => _showMultiSelectSheet<int>(
                        title: '选择房间',
                        items: roomList.map((r) => r.id).toList(),
                        selectedIds: _roomFilter,
                        labelOf: (id) => roomList
                            .firstWhere((r) => r.id == id)
                            .name,
                        onConfirm: (ids) {
                          setState(() => _roomFilter = ids);
                          _emit();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_hasAnyFilter)
                    ActionChip(
                      label: const Text('清除', style: TextStyle(fontSize: 13)),
                      visualDensity: VisualDensity.compact,
                      onPressed: _clearAll,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    String? displayText,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selected ? displayText ?? label : label,
            style: const TextStyle(fontSize: 13),
          ),
          if (selected) ...[
            const SizedBox(width: 2),
            const Icon(Icons.close, size: 14),
          ],
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  void _showMultiSelectSheet<T>({
    required String title,
    required List<T> items,
    required Set<T> selectedIds,
    required String Function(T) labelOf,
    required void Function(Set<T> ids) onConfirm,
  }) {
    final temp = Set<T>.from(selectedIds);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onConfirm(temp);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    CheckboxListTile(
                      title: const Text('全部'),
                      value: temp.isEmpty,
                      onChanged: (_) {
                        setSheetState(() => temp.clear());
                      },
                    ),
                    ...items.map((item) {
                      return CheckboxListTile(
                        title: Text(labelOf(item)),
                        value: temp.contains(item),
                        onChanged: (_) {
                          setSheetState(() {
                            if (temp.contains(item)) {
                              temp.remove(item);
                            } else {
                              temp.add(item);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
