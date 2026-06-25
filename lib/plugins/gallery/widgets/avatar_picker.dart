import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../../../providers.dart';
import '../gallery_storage_service.dart';
import '../screens/avatar_crop_screen.dart';

/// Shows the avatar picker bottom sheet and handles the full pick-crop-save
/// flow. Returns `true` if the avatar was changed (for caller to rebuild).
Future<bool> showAvatarPickerSheet(
  BuildContext context,
  int birdId,
) async {
  final db = ProviderScope.containerOf(context).read(databaseProvider);
  final storage = GalleryStorageService();
  await storage.ensureInitialized();

  // Check if there is an existing avatar
  final existing =
      await (db.select(db.birdAvatars)
            ..where((t) => t.birdId.equals(birdId)))
          .getSingleOrNull();
  final hasAvatar = existing != null;

  final result = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('鹦鹉头像',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('从相册选择'),
            subtitle: const Text('选择照片并裁剪为头像'),
            onTap: () => Navigator.pop(ctx, 'pick'),
          ),
          if (hasAvatar) ...[
            ListTile(
              leading: const Icon(Icons.zoom_out_map),
              title: const Text('查看原图'),
              onTap: () => Navigator.pop(ctx, 'view'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title:
                  const Text('移除头像', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (result == null) return false;
  if (!context.mounted) return false;

  switch (result) {
    case 'pick':
      return _pickAndCrop(context, birdId, db);
    case 'remove':
      return _removeAvatar(birdId, db);
    case 'view':
      if (existing != null) {
        _viewAvatar(context, storage.resolve(existing.filePath));
      }
      return false;
    default:
      return false;
  }
}

Future<bool> _pickAndCrop(
  BuildContext context,
  int birdId,
  AppDatabase db,
) async {
  // 1. Pick image from gallery
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 90,
  );
  if (picked == null) return false;

  // 2. Crop to 1:1 using built-in crop screen
  if (!context.mounted) return false;
  final croppedPath = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => AvatarCropScreen(pickedFile: picked),
    ),
  );
  if (croppedPath == null) return false;

  // 3. Save to filesystem
  final storage = GalleryStorageService();
  final relPath = await storage.saveAvatar(birdId, croppedPath);

  // Compress avatar to max 512px
  await storage.compressToSize(storage.resolve(relPath), maxSize: 512, quality: 85);

  // 4. Upsert database record — delete existing, then insert
  await (db.delete(db.birdAvatars)
        ..where((t) => t.birdId.equals(birdId)))
      .go();
  await db.into(db.birdAvatars).insert(
        BirdAvatarsCompanion(
          birdId: Value(birdId),
          filePath: Value(relPath),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // 5. 记录操作日志
  await pluginRegistry.operationService.record(
    pluginId: 'gallery',
    actionType: 'avatar_updated',
    birdId: birdId,
    summary: '更新了头像',
  );

  // Evict cached image so the new avatar shows immediately
  try {
    final avatarFile = File(storage.resolve(relPath));
    PaintingBinding.instance.imageCache.evict(FileImage(avatarFile));
  } catch (_) {}

  // Clean up temp crop file
  try {
    await File(croppedPath).delete();
  } catch (_) {}

  return true;
}

Future<bool> _removeAvatar(int birdId, AppDatabase db) async {
  final storage = GalleryStorageService();
  await storage.deleteAvatar(birdId);
  await (db.delete(db.birdAvatars)
        ..where((t) => t.birdId.equals(birdId)))
      .go();

  // 记录操作日志
  await pluginRegistry.operationService.record(
    pluginId: 'gallery',
    actionType: 'avatar_removed',
    birdId: birdId,
    summary: '移除了头像',
  );

  return true;
}

void _viewAvatar(BuildContext context, String absolutePath) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.file(
              File(absolutePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ),
  );
}
