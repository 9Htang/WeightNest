import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

/// Singleton file-storage service for the gallery plugin.
/// Photos and avatars are stored under the app documents directory
/// at `gallery/{birdId}/`. The database stores relative paths only.
class GalleryStorageService {
  static final GalleryStorageService _instance = GalleryStorageService._();
  factory GalleryStorageService() => _instance;
  GalleryStorageService._();

  String? _baseDir;

  /// Must be called before any read/write. Idempotent.
  Future<void> ensureInitialized() async {
    if (_baseDir != null) return;
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = appDir.path;
  }

  /// The absolute path to the gallery root directory.
  String get baseDir {
    assert(_baseDir != null, 'Call ensureInitialized() first');
    return _baseDir!;
  }

  // ── path helpers ──

  String _birdDir(int birdId) => 'gallery/$birdId';

  String _avatarRelPath(int birdId) => '${_birdDir(birdId)}/avatar.jpg';

  String _photoRelPath(int birdId, String filename) =>
      '${_birdDir(birdId)}/$filename';

  /// Convert a relative path (stored in DB) to an absolute filesystem path.
  String resolve(String relativePath) {
    assert(_baseDir != null, 'Call ensureInitialized() first');
    return '$_baseDir/$relativePath';
  }

  // ── avatar ──

  /// Copy the (already cropped) source file to the avatar location.
  /// Returns the relative path for DB storage.
  Future<String> saveAvatar(int birdId, String sourceFile) async {
    await ensureInitialized();
    final dir = Directory(resolve(_birdDir(birdId)));
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = resolve(_avatarRelPath(birdId));
    await File(sourceFile).copy(dest);
    return _avatarRelPath(birdId);
  }

  /// Delete the avatar file for [birdId] if it exists.
  Future<void> deleteAvatar(int birdId) async {
    await ensureInitialized();
    final file = File(resolve(_avatarRelPath(birdId)));
    if (await file.exists()) await file.delete();
  }

  // ── photos ──

  /// Copy a photo into the bird's gallery directory.
  /// Returns the relative path for DB storage.
  Future<String> savePhoto(int birdId, String sourceFile) async {
    await ensureInitialized();
    final dir = Directory(resolve(_birdDir(birdId)));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ts = DateTime.now().microsecondsSinceEpoch;
    final r = Random().nextInt(9000) + 1000;
    final filename = 'photo_${ts}_$r.jpg';
    final dest = resolve(_photoRelPath(birdId, filename));
    await File(sourceFile).copy(dest);
    return _photoRelPath(birdId, filename);
  }

  /// Copy a motion photo video into the bird's gallery directory.
  /// Returns the relative path for DB storage.
  Future<String> saveVideo(int birdId, String sourceFile) async {
    await ensureInitialized();
    final dir = Directory(resolve(_birdDir(birdId)));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ts = DateTime.now().microsecondsSinceEpoch;
    final r = Random().nextInt(9000) + 1000;
    final filename = 'video_${ts}_$r.mp4';
    final dest = resolve(_photoRelPath(birdId, filename));
    await File(sourceFile).copy(dest);
    return _photoRelPath(birdId, filename);
  }

  /// Delete a single photo file and its paired video + thumbnail if present.
  Future<void> deletePhoto(String relativePath, {String? videoPath, String? thumbnailPath}) async {
    await ensureInitialized();
    final file = File(resolve(relativePath));
    if (await file.exists()) await file.delete();
    if (videoPath != null) {
      final videoFile = File(resolve(videoPath));
      if (await videoFile.exists()) await videoFile.delete();
    }
    if (thumbnailPath != null) {
      final thumbFile = File(resolve(thumbnailPath));
      if (await thumbFile.exists()) await thumbFile.delete();
    }
  }

  /// Remove all gallery files for a bird (photos + avatar).
  Future<void> deleteAllForBird(int birdId) async {
    await ensureInitialized();
    final dir = Directory(resolve(_birdDir(birdId)));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  // ── compression ──

  /// Compress a JPEG photo in-place: max 1920px long edge, quality 85.
  /// Keeps the original if compression fails.
  Future<void> compressPhoto(String absolutePath) async {
    try {
      final tmpPath = '$absolutePath.tmp';
      final result = await FlutterImageCompress.compressAndGetFile(
        absolutePath,
        tmpPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1920,
        format: CompressFormat.jpeg,
      );
      if (result != null) {
        final tmpFile = File(result.path);
        if (await tmpFile.exists()) {
          await tmpFile.rename(absolutePath);
        }
      }
    } catch (e) {
      // Silently keep original on failure
      debugPrint('compressPhoto failed: $e');
    }
  }

  /// Compress a JPEG to a specific max dimension (for avatars).
  Future<void> compressToSize(String absolutePath, {int maxSize = 512, int quality = 85}) async {
    try {
      final tmpPath = '$absolutePath.tmp';
      final result = await FlutterImageCompress.compressAndGetFile(
        absolutePath,
        tmpPath,
        quality: quality,
        minWidth: maxSize,
        minHeight: maxSize,
        format: CompressFormat.jpeg,
      );
      if (result != null) {
        final tmpFile = File(result.path);
        if (await tmpFile.exists()) {
          await tmpFile.rename(absolutePath);
        }
      }
    } catch (e) {
      debugPrint('compressToSize failed: $e');
    }
  }

  /// Compress a motion photo video to 480p in-place.
  Future<void> compressVideo(String absolutePath) async {
    try {
      final info = await VideoCompress.compressVideo(
        absolutePath,
        quality: VideoQuality.MediumQuality,
        includeAudio: false,
      );
      final videoPath = info?.file?.path;
      if (videoPath != null) {
        final compressed = File(videoPath);
        if (await compressed.exists()) {
          await compressed.rename(absolutePath);
        }
      }
    } catch (e) {
      debugPrint('compressVideo failed: $e');
    }
  }
}
