import 'package:flutter/material.dart';
import 'plugin.dart';

/// Manages plugin page instances — open, close, focus, uniqueness enforcement.
class PluginPageManager extends ChangeNotifier {
  final List<PluginPage> _pages = [];
  int _activeIndex = 0;

  List<PluginPage> get pages => List.unmodifiable(_pages);
  PluginPage? get activePage => _pages.isEmpty ? null : _pages[_activeIndex];
  int get activeIndex => _activeIndex;
  bool get isEmpty => _pages.isEmpty;

  /// Open a plugin page. Enforces [PageUniqueness] — if a conflicting page
  /// already exists, focuses it instead of creating a new one.
  /// Returns the page (new or existing) that is now focused.
  PluginPage? openPage({
    required String pluginId,
    required PluginPageDescriptor descriptor,
    int? birdId,
  }) {
    // Check uniqueness constraints
    if (descriptor.uniqueness == PageUniqueness.singleton) {
      final i = _pages.indexWhere(
          (p) => p.pluginId == pluginId && p.pageKey == descriptor.key);
      if (i >= 0) { _activeIndex = i; notifyListeners(); return _pages[i]; }
    }
    if (descriptor.uniqueness == PageUniqueness.perBird && birdId != null) {
      final i = _pages.indexWhere((p) =>
          p.pluginId == pluginId &&
          p.pageKey == descriptor.key &&
          p.birdId == birdId);
      if (i >= 0) { _activeIndex = i; notifyListeners(); return _pages[i]; }
    }

    // Create new page
    final ctx = PluginPageContext(birdId: birdId);
    final page = PluginPage(
      pluginId: pluginId,
      pageKey: descriptor.key,
      birdId: birdId,
      uniqueness: descriptor.uniqueness,
      widget: descriptor.builder(ctx),
    );
    _pages.add(page);
    _activeIndex = _pages.length - 1;
    notifyListeners();
    return page;
  }

  void closePage(int index) {
    if (index < 0 || index >= _pages.length) return;
    _pages.removeAt(index);
    if (_pages.isEmpty) {
      _activeIndex = 0;
    } else if (_activeIndex >= _pages.length) {
      _activeIndex = _pages.length - 1;
    }
    notifyListeners();
  }

  void closeByPlugin(String pluginId) {
    _pages.removeWhere((p) => p.pluginId == pluginId);
    if (_activeIndex >= _pages.length) _activeIndex = _pages.length - 1;
    notifyListeners();
  }

  void focusPage(int index) {
    if (index >= 0 && index < _pages.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void focusPageById(String pageId) {
    final i = _pages.indexWhere((p) => p.id == pageId);
    if (i >= 0) focusPage(i);
  }
}
