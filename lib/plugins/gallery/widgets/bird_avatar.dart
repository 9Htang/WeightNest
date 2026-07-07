import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/plugin_registry.dart';
import '../../../theme/app_tokens.dart';
import '../gallery_storage_service.dart';

/// Displays a bird's custom avatar if one exists, otherwise falls back to the
/// growth-stage-based emoji avatar.
///
/// Used by the gallery plugin's [buildAvatar] slot and consumed by bird detail
/// header + bird list tile.
class BirdAvatarWidget extends StatefulWidget {
  final int birdId;
  final double size;
  final String? growthStage; // for emoji fallback
  final VoidCallback? onTap;
  final BoxShape shape;

  /// When true, use sharp corners (borderRadius: 0) instead of [AppRadius.lg].
  /// Used by list cards that have a sharp, edge-to-edge left column.
  final bool forceSharp;

  /// Overrides the emoji fallback background color. When null (default), the
  /// growth-stage semantic color is used. Pass [cardColor] in list-circle mode
  /// so the fallback blends with the surrounding card.
  final Color? backgroundColor;

  const BirdAvatarWidget({
    super.key,
    required this.birdId,
    this.size = 56,
    this.growthStage,
    this.onTap,
    this.shape = BoxShape.rectangle,
    this.forceSharp = false,
    this.backgroundColor,
  });

  @override
  State<BirdAvatarWidget> createState() => _BirdAvatarWidgetState();
}

class _BirdAvatarWidgetState extends State<BirdAvatarWidget> {
  String? _avatarPath;
  bool _loaded = false;
  int _version = 0;
  int _generation = 0;

  /// 缓存 [_avatarPath] 对应文件是否存在（异步预检查结果）。
  /// build() 内据此分支，避免每次重建同步调用 [File.existsSync] 阻塞 UI。
  bool _avatarFileExists = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(BirdAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.birdId != widget.birdId || oldWidget.size != widget.size) {
      _avatarPath = null;
      _loaded = false;
      _avatarFileExists = false;
      _loadAvatar();
    }
    // ponytail: don't reload on every rebuild — the avatar picker evicts the
    // image cache directly (PaintingBinding.imageCache.evict) after save, so
    // the new avatar shows on next build without a redundant DB query here.
  }

  Future<void> _loadAvatar() async {
    final gen = ++_generation;
    try {
      await GalleryStorageService().ensureInitialized();
      final path =
          await pluginRegistry.call('gallery', 'getAvatarPath', widget.birdId);
      if (!mounted || gen != _generation) return;
      // 异步预检查文件存在性，结果缓存到 _avatarFileExists 供 build() 查表
      final exists = (path is String && path.isNotEmpty)
          ? await File(GalleryStorageService().resolve(path)).exists()
          : false;
      if (!mounted || gen != _generation) return;
      setState(() {
        _avatarPath = path as String?;
        _avatarFileExists = exists;
        _loaded = true;
        _version++;
      });
    } catch (_) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _avatarPath = null;
        _avatarFileExists = false;
        _loaded = true; // resolve spinner, show fallback
        _version++;
      });
    }
  }

  /// borderRadius for ClipRRect / BoxDecoration.
  BorderRadius get _effectiveRadius {
    if (widget.forceSharp) return BorderRadius.zero;
    if (widget.shape == BoxShape.circle) {
      return BorderRadius.circular(widget.size / 2);
    }
    final r = context.r;
    return r.bLg;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child;
    if (_avatarPath != null && _avatarPath!.isNotEmpty && _avatarFileExists) {
      final storage = GalleryStorageService();
      final file = File(storage.resolve(_avatarPath!));
      // Photo avatar — always constrained to widget.size × widget.size.
      // In fill mode the outer SizedBox(64×64) controls the box; here we keep
      // the intrinsic size so non-fill callers (detail header) stay bounded.
      child = ClipRRect(
        borderRadius: _effectiveRadius,
        child: Image.file(
          file,
          key: ValueKey('avatar_${widget.birdId}_$_version'),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildEmojiFallback(theme),
        ),
      );
    } else if (!_loaded) {
      child = SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else {
      child = _buildEmojiFallback(theme);
    }

    // _buildEmojiFallback and the loading spinner already have their own
    // sized Container with decoration, so only wrap the ClipRRect (photo)
    // case with an outer Container to enforce size + optional tap.
    Widget result = child;

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: result,
      );
    }
    return result;
  }

  Widget _buildEmojiFallback(ThemeData theme) {
    final stage = widget.growthStage ?? '';
    final emoji = stage == '雏鸟'
        ? '🐣'
        : stage == '幼鸟'
            ? '🐤'
            : '🦜';
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? _stageColor(theme),
        borderRadius: _effectiveRadius,
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: widget.size * 0.5),
        ),
      ),
    );
  }

  Color _stageColor(ThemeData theme) {
    final stage = widget.growthStage ?? '';
    switch (stage) {
      case '雏鸟':
        return Colors.orange.shade100;
      case '幼鸟':
        return Colors.green.shade100;
      default:
        return theme.colorScheme.primaryContainer;
    }
  }
}
