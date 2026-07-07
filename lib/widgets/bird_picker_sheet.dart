import 'package:flutter/material.dart';
import '../database/database.dart';
import '../repositories/bird_repository.dart';
import 'bird_list_tile.dart';
import 'bird_search_bar.dart';

/// A bottom sheet that lets the user search and pick a bird.
///
/// Uses [BirdSearchBar] for consistent search + multi-field filter UX.
///
/// Returns the selected [BirdWithDetails], or null if dismissed.
class BirdPickerSheet extends StatefulWidget {
  final String title;
  final List<BirdWithDetails> birds;
  final String? hintText;

  // Silent pre-filters (not shown as chips, applied before visible filters)
  final Set<String>? genderFilter;
  final Set<int>? speciesFilter;
  final int? excludeBirdId;

  // Visible filter chips
  final bool showSearchBox;
  final bool showGenderFilter;
  final bool showSpeciesFilter;
  final bool showStageFilter;

  const BirdPickerSheet({
    super.key,
    required this.title,
    required this.birds,
    this.hintText,
    this.genderFilter,
    this.speciesFilter,
    this.excludeBirdId,
    this.showSearchBox = true,
    this.showGenderFilter = false,
    this.showSpeciesFilter = false,
    this.showStageFilter = false,
  });

  /// Show the picker as a modal bottom sheet. Returns the selected bird or null.
  static Future<BirdWithDetails?> show(
    BuildContext context, {
    required String title,
    required List<BirdWithDetails> birds,
    String? hintText,
    Set<String>? genderFilter,
    Set<int>? speciesFilter,
    int? excludeBirdId,
    bool showSearchBox = true,
    bool showGenderFilter = false,
    bool showSpeciesFilter = false,
    bool showStageFilter = false,
  }) {
    return showModalBottomSheet<BirdWithDetails>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => BirdPickerSheet(
        title: title,
        birds: birds,
        hintText: hintText,
        genderFilter: genderFilter,
        speciesFilter: speciesFilter,
        excludeBirdId: excludeBirdId,
        showSearchBox: showSearchBox,
        showGenderFilter: showGenderFilter,
        showSpeciesFilter: showSpeciesFilter,
        showStageFilter: showStageFilter,
      ),
    );
  }

  @override
  State<BirdPickerSheet> createState() => _BirdPickerSheetState();
}

class _BirdPickerSheetState extends State<BirdPickerSheet> {
  String _searchText = '';
  Set<String> _genderChip = {};
  Set<int> _speciesChip = {};
  Set<String> _stageChip = {};

  List<BirdWithDetails> get _filtered {
    var result = widget.birds;

    // Silent pre-filters
    if (widget.excludeBirdId != null) {
      result =
          result.where((b) => b.bird.id != widget.excludeBirdId).toList();
    }
    if (widget.genderFilter != null && widget.genderFilter!.isNotEmpty) {
      result = result
          .where((b) => widget.genderFilter!.contains(b.bird.gender))
          .toList();
    }
    if (widget.speciesFilter != null && widget.speciesFilter!.isNotEmpty) {
      result = result
          .where((b) => widget.speciesFilter!.contains(b.bird.speciesId))
          .toList();
    }

    // Visible filter chips
    if (_genderChip.isNotEmpty) {
      result = result
          .where((b) => _genderChip.contains(b.bird.gender))
          .toList();
    }
    if (_speciesChip.isNotEmpty) {
      result = result
          .where((b) => _speciesChip.contains(b.bird.speciesId))
          .toList();
    }
    if (_stageChip.isNotEmpty) {
      result = result
          .where((b) => _stageChip.contains(b.physioStage))
          .toList();
    }

    // Text search: name + ring number only
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      result = result
          .where((b) =>
              b.bird.name.toLowerCase().contains(q) ||
              (b.bird.ringNumber?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    '${filtered.length}/${widget.birds.length}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Search + filter bar
            BirdSearchBar(
              showSearchBox: widget.showSearchBox,
              showGenderFilter: widget.showGenderFilter,
              showSpeciesFilter: widget.showSpeciesFilter,
              showStageFilter: widget.showStageFilter,
              showRoomFilter: false,
              searchHint: widget.hintText ?? '搜索名称或脚环号...',
              onChanged: ({
                required searchText,
                required genders,
                required speciesIds,
                required stages,
                required roomIds,
              }) =>
                  setState(() {
                _searchText = searchText;
                _genderChip = genders;
                _speciesChip = speciesIds;
                _stageChip = stages;
              }),
            ),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _searchText.isNotEmpty || _hasAnyFilter
                            ? '无匹配结果'
                            : '暂无鹦鹉',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final b = filtered[i];
                        return BirdListTile(
                          bird: b,
                          onTap: () => Navigator.pop(context, b),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasAnyFilter =>
      _genderChip.isNotEmpty ||
      _speciesChip.isNotEmpty ||
      _stageChip.isNotEmpty;
}
