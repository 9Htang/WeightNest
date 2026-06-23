import 'dart:io';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../gallery_storage_service.dart';
import '../screens/gallery_viewer_screen.dart';

/// Photo gallery section contributed to the bird detail page via
/// [FeaturePlugin.buildDetailSections]. Supports thumbnail grid,
/// swipe browsing, batch delete, drag-to-reorder, and full-screen viewing.
class GallerySection extends StatefulWidget {
  final int birdId;
  const GallerySection({super.key, required this.birdId});

  @override
  State<GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends State<GallerySection> {
  final _storage = GalleryStorageService();

  List<BirdPhoto> _photos = [];
  bool _loaded = false;
  bool _isSwipeMode = false;
  bool _batchMode = false;
  bool _isEditing = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void didUpdateWidget(GallerySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.birdId != widget.birdId) {
      _photos = [];
      _loaded = false;
      _isSwipeMode = false;
      _batchMode = false;
      _isEditing = false;
      _selectedIds.clear();
      _loadPhotos();
    }
  }

  Future<void> _loadPhotos() async {
    final db = pluginRegistry.db;
    if (db == null) return;
    await _storage.ensureInitialized();
    final photos = await (db.select(db.birdPhotos)
          ..where((t) => t.birdId.equals(widget.birdId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    if (mounted) {
      setState(() {
        _photos = photos;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(),
        const SizedBox(height: 8),
        if (_photos.isEmpty)
          _buildEmptyState()
        else if (_isSwipeMode)
          _buildSwipeView()
        else
          _buildGridView(),
      ],
    );
  }

  // ── toolbar ──

  Widget _buildToolbar() {
    return Row(
      children: [
        Text('共 ${_photos.length} 张照片',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        // Mode toggle
        IconButton(
          icon: Icon(_isSwipeMode ? Icons.grid_view : Icons.view_carousel,
              size: 20),
          tooltip: _isSwipeMode ? '缩略图模式' : '滑动浏览',
          onPressed: () {
            setState(() {
              _isSwipeMode = !_isSwipeMode;
              if (_isSwipeMode) {
                _batchMode = false;
                _isEditing = false;
                _selectedIds.clear();
              }
            });
          },
          visualDensity: VisualDensity.compact,
        ),
        // Edit / Done
        if (!_isSwipeMode && _photos.isNotEmpty)
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 20),
            tooltip: _isEditing ? '完成' : '排序',
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (_isEditing) {
                  _batchMode = false;
                  _selectedIds.clear();
                }
              });
            },
            visualDensity: VisualDensity.compact,
          ),
        // Add photo
        IconButton(
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
          tooltip: '添加照片',
          onPressed: _addPhoto,
          visualDensity: VisualDensity.compact,
        ),
        // Batch delete
        if (_batchMode)
          IconButton(
            icon: Icon(Icons.delete, size: 20, color: Colors.red.shade400),
            tooltip: '删除选中 (${_selectedIds.length})',
            onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  // ── empty state ──

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('暂无照片', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text('点击右上角 + 添加', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── grid view ──

  Widget _buildGridView() {
    const crossAxisCount = 4;
    const spacing = 6.0;
    final availableWidth = MediaQuery.of(context).size.width - 32;
    final thumbSize =
        (availableWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

    if (_isEditing) {
      return SizedBox(
        height: thumbSize + 40,
        child: ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _photos.length,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final photo = _photos[index];
            return _buildThumbnail(
              photo,
              thumbSize,
              index: index,
              key: ValueKey(photo.id),
              showDragHandle: true,
            );
          },
        ),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(_photos.length, (i) {
        return _buildThumbnail(_photos[i], thumbSize, index: i);
      }),
    );
  }

  Widget _buildThumbnail(
    BirdPhoto photo,
    double size, {
    int? index,
    Key? key,
    bool showDragHandle = false,
  }) {
    return GestureDetector(
      key: key,
      onTap: () {
        if (_batchMode) {
          setState(() {
            if (_selectedIds.contains(photo.id)) {
              _selectedIds.remove(photo.id);
              if (_selectedIds.isEmpty) _batchMode = false;
            } else {
              _selectedIds.add(photo.id);
            }
          });
        } else {
          _openViewer(index ?? _photos.indexOf(photo));
        }
      },
      onLongPress: () {
        if (!_isEditing) {
          setState(() {
            _batchMode = true;
            _selectedIds.add(photo.id);
          });
        }
      },
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _selectedIds.contains(photo.id)
                    ? Colors.red
                    : Colors.grey.shade300,
                width: _selectedIds.contains(photo.id) ? 2 : 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: _buildImage(photo, size),
            ),
          ),
          // Drag handle
          if (showDragHandle)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    topRight: Radius.circular(5),
                  ),
                ),
                child: const Icon(Icons.drag_handle, size: 14, color: Colors.white),
              ),
            ),
          // Batch select checkbox
          if (_batchMode)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedIds.contains(photo.id)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: _selectedIds.contains(photo.id)
                      ? Colors.red
                      : Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(BirdPhoto photo, double size) {
    final path = _storage.resolve(photo.filePath);
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    return const Icon(Icons.broken_image, color: Colors.grey);
  }

  // ── swipe view ──

  Widget _buildSwipeView() {
    final index = _swipeIndex;
    return SizedBox(
      height: 280,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: _photos.length,
              controller: PageController(initialPage: index),
              onPageChanged: (i) => setState(() => _swipeIndex = i),
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () => _openViewer(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImage(_photos[i], double.infinity),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${index + 1} / ${_photos.length}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  int _swipeIndex = 0;

  // ── full-screen viewer ──

  void _openViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryViewerScreen(
          birdId: widget.birdId,
          initialIndex: index.clamp(0, (_photos.length - 1).clamp(0, 9999)),
        ),
      ),
    );
  }

  // ── add photo ──

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    final db = pluginRegistry.db;
    if (db == null) return;

    // Save file
    final relPath = await _storage.savePhoto(widget.birdId, picked.path);

    // Get next sort order
    final nextOrder = _photos.isEmpty ? 0 : _photos.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    // Insert record
    await db.into(db.birdPhotos).insert(
          BirdPhotosCompanion(
            birdId: Value(widget.birdId),
            filePath: Value(relPath),
            sortOrder: Value(nextOrder),
            createdAt: Value(DateTime.now()),
          ),
        );

    await _loadPhotos();
  }

  // ── batch delete ──

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 张照片吗？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final db = pluginRegistry.db;
    if (db == null) return;

    for (final id in _selectedIds) {
      final photo = _photos.firstWhere((p) => p.id == id);
      await _storage.deletePhoto(photo.filePath);
      await (db.delete(db.birdPhotos)..where((t) => t.id.equals(id))).go();
    }

    setState(() {
      _batchMode = false;
      _selectedIds.clear();
    });
    await _loadPhotos();
  }

  // ── reorder ──

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final reordered = List<BirdPhoto>.from(_photos);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    setState(() => _photos = reordered);

    final db = pluginRegistry.db;
    if (db == null) return;

    // Persist sort orders
    for (int i = 0; i < reordered.length; i++) {
      await (db.update(db.birdPhotos)
            ..where((t) => t.id.equals(reordered[i].id)))
          .write(BirdPhotosCompanion(sortOrder: Value(i)));
    }
  }
}
