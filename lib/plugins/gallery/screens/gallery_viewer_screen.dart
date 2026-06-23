import 'dart:io';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../gallery_storage_service.dart';

/// Full-screen photo viewer with swipe navigation and pinch-to-zoom.
class GalleryViewerScreen extends StatefulWidget {
  final int birdId;
  final int initialIndex;

  const GalleryViewerScreen({
    super.key,
    required this.birdId,
    this.initialIndex = 0,
  });

  @override
  State<GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> {
  final _storage = GalleryStorageService();
  late final PageController _pageController;

  List<BirdPhoto> _photos = [];
  bool _loaded = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadPhotos();
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _photos.isNotEmpty
              ? '${_currentIndex + 1} / ${_photos.length}'
              : '',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _loaded && _photos.isEmpty
          ? const Center(
              child: Text('暂无照片',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            )
          : _loaded
              ? PageView.builder(
                  controller: _pageController,
                  itemCount: _photos.length,
                  onPageChanged: (i) =>
                      setState(() => _currentIndex = i),
                  itemBuilder: (context, index) {
                    return _buildPhotoPage(_photos[index]);
                  },
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildPhotoPage(BirdPhoto photo) {
    final path = _storage.resolve(photo.filePath);
    final file = File(path);

    if (!file.existsSync()) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.white38),
            SizedBox(height: 8),
            Text('照片文件不存在', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.white38),
          ),
        ),
      ),
    );
  }
}
