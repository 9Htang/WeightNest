import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/plugin_registry.dart';
import '../../../repositories/bird_repository.dart';
import '../gallery_storage_service.dart';

/// Displays a bird's custom avatar if one exists, otherwise falls back to the
/// growth-stage-based emoji avatar.
///
/// Used by the gallery plugin's [buildAvatar] slot and consumed by bird detail
/// header + bird list tile.
class BirdAvatarWidget extends StatefulWidget {
  final int birdId;
  final double size;
  final BirdWithDetails? bird; // for emoji fallback
  final VoidCallback? onTap;
  final BoxShape shape;

  const BirdAvatarWidget({
    super.key,
    required this.birdId,
    this.size = 56,
    this.bird,
    this.onTap,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<BirdAvatarWidget> createState() => _BirdAvatarWidgetState();
}

class _BirdAvatarWidgetState extends State<BirdAvatarWidget> {
  String? _avatarPath;
  bool _loaded = false;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(BirdAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload whenever birdId changes OR widget is rebuilt (avatar may have
    // been updated externally via the picker).
    final idChanged = oldWidget.birdId != widget.birdId;
    final onTapChanged = oldWidget.onTap != widget.onTap;
    if (idChanged || onTapChanged || oldWidget.size != widget.size) {
      _avatarPath = null;
      _loaded = false;
      _loadAvatar();
    } else {
      // Same bird, same size — reload to catch external avatar updates.
      _loadAvatar();
    }
  }

  Future<void> _loadAvatar() async {
    // Ensure the storage singleton is initialized before any resolve() call.
    await GalleryStorageService().ensureInitialized();
    final path =
        await pluginRegistry.call('gallery', 'getAvatarPath', widget.birdId);
    if (mounted) {
      setState(() {
        _avatarPath = path as String?;
        _loaded = true;
        _version++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child;
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      final storage = GalleryStorageService();
      final file = File(storage.resolve(_avatarPath!));
      if (file.existsSync()) {
        child = ClipRRect(
          borderRadius: BorderRadius.circular(widget.shape == BoxShape.circle
              ? widget.size / 2
              : widget.size / 7),
          child: Image.file(
            file,
            key: ValueKey('avatar_${widget.birdId}_$_version'),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildEmojiFallback(theme),
          ),
        );
      } else {
        child = _buildEmojiFallback(theme);
      }
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

    final borderRadius = widget.shape == BoxShape.circle
        ? widget.size / 2
        : widget.size / 7;
    final decorated = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: child is! ClipRRect ? _stageColor(theme) : null,
      ),
      child: child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: decorated,
      );
    }
    return decorated;
  }

  Widget _buildEmojiFallback(ThemeData theme) {
    final stage = widget.bird?.growthStage ?? '';
    final emoji = stage == '雏鸟' ? '🐣' : stage == '幼鸟' ? '🐤' : '🦜';
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _stageColor(theme),
        borderRadius: BorderRadius.circular(
          widget.shape == BoxShape.circle
              ? widget.size / 2
              : widget.size / 7,
        ),
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
    final stage = widget.bird?.growthStage ?? '';
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
