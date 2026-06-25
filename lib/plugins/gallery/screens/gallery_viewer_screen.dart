import 'dart:io';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../gallery_storage_service.dart';

/// Full-screen photo viewer with swipe navigation, pinch-to-zoom,
/// and motion photo video playback.
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

  // Video playback state for motion photos
  VideoPlayerController? _videoController;
  bool _isVideoMuted = true;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Allow all orientations so landscape photos can be viewed full-width
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadPhotos();
  }

  @override
  void dispose() {
    // Restore portrait-only lock when leaving the viewer
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _pageController.dispose();
    _disposeVideo();
    super.dispose();
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
      // Initialize video for the starting page if it's a motion photo
      _initVideoForPage(_currentIndex);
    }
  }

  /// Immediately clears Dart-side video state. Native disposal runs in
  /// background (fire-and-forget) so it never blocks the UI thread or the
  /// next video initialization.
  void _disposeVideo() {
    final controller = _videoController;
    _videoController = null;
    _isVideoInitialized = false;
    // Dispose native resources in background; errors are logged, not thrown.
    controller?.dispose().catchError((e) {
      debugPrint('[GalleryViewer] Video dispose error: $e');
    });
  }

  Future<void> _initVideoForPage(int index) async {
    _disposeVideo(); // immediate cleanup — no await on native disposal
    if (index < 0 || index >= _photos.length) return;

    final photo = _photos[index];
    if (photo.mediaType != 'motion_photo' || photo.videoFilePath == null) {
      return;
    }

    final videoPath = _storage.resolve(photo.videoFilePath!);
    final videoFile = File(videoPath);
    if (!videoFile.existsSync()) return;

    final controller = VideoPlayerController.file(videoFile);
    _videoController = controller;

    controller.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await controller.initialize();
      // Guard: controller may have been replaced by a subsequent swipe
      // while we were awaiting initialization.
      if (!mounted || _videoController != controller) {
        // This controller is no longer needed — release native resources.
        controller.dispose().catchError((_) {});
        return;
      }
      setState(() => _isVideoInitialized = true);
      controller.setLooping(true);
      controller.setVolume(_isVideoMuted ? 0.0 : 1.0);
      controller.play();
    } catch (e) {
      debugPrint('[GalleryViewer] Video init failed: $e');
      // Only dispose if this controller is still the current one,
      // otherwise we'd kill a newer controller that is initializing.
      if (_videoController == controller) {
        _disposeVideo();
      } else {
        controller.dispose().catchError((_) {});
      }
    }
  }

  void _toggleMute() {
    if (_videoController == null) return;
    _isVideoMuted = !_isVideoMuted;
    _videoController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      backgroundColor: Colors.black,
      // Hide AppBar in landscape to maximize viewing area
      appBar: isLandscape
          ? null
          : AppBar(
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
                  onPageChanged: (i) {
                    setState(() => _currentIndex = i);
                    _initVideoForPage(i);
                  },
                  itemBuilder: (context, index) {
                    return _buildPhotoPage(_photos[index]);
                  },
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildPhotoPage(BirdPhoto photo) {
    // Motion photo: show video player
    if (photo.mediaType == 'motion_photo' &&
        photo.videoFilePath != null &&
        _isVideoInitialized &&
        _videoController != null) {
      return _buildVideoPage();
    }

    // Fall through to static image
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

  Widget _buildVideoPage() {
    final controller = _videoController!;
    final videoSize = controller.value.size;

    // Video with pinch-to-zoom, full-frame (no cropping)
    final videoChild = videoSize.width > 0 && videoSize.height > 0
        ? InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: videoSize.width,
                  height: videoSize.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          )
        : Center(child: VideoPlayer(controller));

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video — fills screen, maintains aspect ratio, pinch-to-zoom
        videoChild,
        // Tap anywhere to play/pause (below overlays so they still work)
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
                setState(() {});
              },
            ),
          ),
        ),
        // Play/pause indicator when paused
        if (!controller.value.isPlaying)
          const Center(
            child: Icon(Icons.play_circle_fill,
                size: 64, color: Colors.white54),
          ),
        // Mute / unmute toggle (on top so taps always reach it)
        Positioned(
          bottom: 20,
          right: 16,
          child: Material(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _toggleMute,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  _isVideoMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
