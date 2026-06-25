import 'dart:io';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../../../services/motion_photo_service.dart';
import '../gallery_storage_service.dart';
import '../screens/gallery_viewer_screen.dart';

/// Photo gallery section contributed to the bird detail page via
/// [FeaturePlugin.buildDetailSections]. Supports thumbnail grid,
/// swipe browsing, batch-add, batch delete, drag-to-reorder, and full-screen viewing.
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
  final Set<int> _selectedIds = {};

  // Pagination: 3×3 grid per page
  static const _photosPerPage = 9;
  int _currentPage = 0;
  late final PageController _gridPageController;

  @override
  void initState() {
    super.initState();
    _gridPageController = PageController();
    _loadPhotos();
  }

  @override
  void dispose() {
    _gridPageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GallerySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.birdId != widget.birdId) {
      _photos = [];
      _loaded = false;
      _isSwipeMode = false;
      _batchMode = false;
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
          _buildPaginatedGrid(),
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
                _selectedIds.clear();
              }
            });
          },
          visualDensity: VisualDensity.compact,
        ),
        // Delete mode toggle (pencil)
        if (!_isSwipeMode && _photos.isNotEmpty)
          IconButton(
            icon: Icon(_batchMode ? Icons.check : Icons.edit, size: 20),
            tooltip: _batchMode ? '完成' : '选择删除',
            onPressed: () {
              setState(() {
                _batchMode = !_batchMode;
                if (_batchMode) {
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

  Widget _buildPaginatedGrid() {
    const crossAxisCount = 3;
    const spacing = 6.0;
    final availableWidth = MediaQuery.of(context).size.width - 32;
    final thumbSize =
        (availableWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
    final totalPages = (_photos.length / _photosPerPage).ceil();
    // 3 rows × thumb + 2 gaps between rows
    final gridHeight = thumbSize * 3 + spacing * 2;

    return Column(
      children: [
        SizedBox(
          height: gridHeight,
          child: PageView.builder(
            controller: _gridPageController,
            itemCount: totalPages,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, page) {
              final start = page * _photosPerPage;
              final end =
                  (start + _photosPerPage).clamp(0, _photos.length);
              final pagePhotos = _photos.sublist(start, end);

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(pagePhotos.length, (i) {
                  final photo = pagePhotos[i];
                  final globalIndex = start + i;
                  final thumb = _buildThumbnail(
                    photo,
                    thumbSize,
                    index: globalIndex,
                  );

                  if (_batchMode) return thumb;

                  // Drag-to-reorder within the full list
                  return DragTarget<BirdPhoto>(
                    onWillAcceptWithDetails: (details) =>
                        details.data.id != photo.id,
                    onAcceptWithDetails: (details) {
                      final oldIndex = _photos.indexOf(details.data);
                      _onReorder(oldIndex, globalIndex);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isOver = candidateData.isNotEmpty;
                      return LongPressDraggable<BirdPhoto>(
                        data: photo,
                        delay: const Duration(milliseconds: 400),
                        hapticFeedbackOnStart: true,
                        feedback: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: thumbSize * 1.05,
                            height: thumbSize * 1.05,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.blue, width: 2.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Opacity(
                                opacity: 0.85,
                                child:
                                    _buildStaticImage(photo, thumbSize),
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.2,
                          child: thumb,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          transform: isOver
                              ? (Matrix4.identity()..scale(1.10))
                              : Matrix4.identity(),
                          child: thumb,
                        ),
                      );
                    },
                  );
                }),
              );
            },
          ),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 10),
          _buildPageIndicator(totalPages),
        ],
      ],
    );
  }

  Widget _buildPageIndicator(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 10 : 7,
          height: isActive ? 10 : 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildThumbnail(
    BirdPhoto photo,
    double size, {
    int? index,
  }) {
    final effectiveIndex = index ?? _photos.indexOf(photo);

    final isSelected = _selectedIds.contains(photo.id);

    final Widget stack = Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Colors.red : Colors.grey.shade300,
              width: isSelected ? 2 : 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: _buildImage(photo, size),
          ),
        ),
        // Batch select checkbox (shown in delete mode)
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
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected ? Colors.red : Colors.grey,
              ),
            ),
          ),
        // LIVE badge for motion photos
        if (photo.mediaType == 'motion_photo')
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 10, color: Colors.white),
                  SizedBox(width: 1),
                  Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: () {
        if (_batchMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(photo.id);
              if (_selectedIds.isEmpty) _batchMode = false;
            } else {
              _selectedIds.add(photo.id);
            }
          });
        } else {
          _openViewer(effectiveIndex);
        }
      },
      child: stack,
    );
  }

  /// Static still image used for drag feedback.
  Widget _buildStaticImage(BirdPhoto photo, double size) {
    final path = _storage.resolve(photo.filePath);
    final file = File(path);
    if (file.existsSync()) {
      final cacheDim = (size * 2).toInt();
      return Image.file(file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: cacheDim);
    }
    return const Icon(Icons.broken_image, color: Colors.grey);
  }

  Widget _buildImage(BirdPhoto photo, double size) {
    final path = _storage.resolve(photo.filePath);
    final file = File(path);
    if (file.existsSync()) {
      final cacheDim = (size * 2).toInt();
      return Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheDim,
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

  Future<void> _openViewer(int index) async {
    await Navigator.of(context).push(
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
    final picked = await picker.pickMultiImage(
      imageQuality: 100, // 100 to preserve motion photo embedded MP4 data
    );
    if (picked.isEmpty) return;

    final db = pluginRegistry.db;
    if (db == null) return;

    int nextOrder = _photos.isEmpty
        ? 0
        : _photos.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    for (final xfile in picked) {
      // Save the still image first
      final relPath = await _storage.savePhoto(widget.birdId, xfile.path);

      // Check if it's a motion photo and extract video
      String? videoRelPath;
      String mediaType = 'photo';

      final savedPath = _storage.resolve(relPath);
      final extractedVideo = await MotionPhotoService.extractVideo(savedPath);
      if (extractedVideo != null) {
        videoRelPath = await _storage.saveVideo(widget.birdId, extractedVideo);
        mediaType = 'motion_photo';
        // Clean up the temp extracted video file
        try {
          await File(extractedVideo).delete();
        } catch (_) {}
      }

      // Compress the saved JPEG (now that motion photo data has been extracted)
      await _storage.compressPhoto(savedPath);

      // Compress the extracted motion video to 480p
      if (videoRelPath != null) {
        await _storage.compressVideo(_storage.resolve(videoRelPath));
      }

      await db.into(db.birdPhotos).insert(
            BirdPhotosCompanion(
              birdId: Value(widget.birdId),
              filePath: Value(relPath),
              sortOrder: Value(nextOrder++),
              mediaType: Value(mediaType),
              videoFilePath: videoRelPath != null
                  ? Value(videoRelPath)
                  : const Value.absent(),
              createdAt: Value(DateTime.now()),
            ),
          );
    }

    // 记录操作日志
    await pluginRegistry.operationService.record(
      pluginId: 'gallery',
      actionType: 'photo_added',
      birdId: widget.birdId,
      summary: '添加了${picked.length}张照片',
      details: {'count': picked.length},
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

    final deletedCount = _selectedIds.length;

    for (final id in _selectedIds) {
      final photo = _photos.firstWhere((p) => p.id == id);
      await _storage.deletePhoto(photo.filePath,
          videoPath: photo.videoFilePath,
          thumbnailPath: photo.thumbnailPath);
      await (db.delete(db.birdPhotos)..where((t) => t.id.equals(id))).go();
    }

    // 记录操作日志
    await pluginRegistry.operationService.record(
      pluginId: 'gallery',
      actionType: 'photo_deleted',
      birdId: widget.birdId,
      summary: '删除了$deletedCount张照片',
      details: {'count': deletedCount},
    );

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
