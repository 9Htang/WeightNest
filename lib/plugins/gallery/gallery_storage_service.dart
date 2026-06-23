import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
    final ts = DateTime.now().millisecondsSinceEpoch;
    final filename = 'photo_$ts.jpg';
    final dest = resolve(_photoRelPath(birdId, filename));
    await File(sourceFile).copy(dest);
    return _photoRelPath(birdId, filename);
  }

  /// Delete a single photo file.
  Future<void> deletePhoto(String relativePath) async {
    await ensureInitialized();
    final file = File(resolve(relativePath));
    if (await file.exists()) await file.delete();
  }

  /// Remove all gallery files for a bird (photos + avatar).
  Future<void> deleteAllForBird(int birdId) async {
    await ensureInitialized();
    final dir = Directory(resolve(_birdDir(birdId)));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
