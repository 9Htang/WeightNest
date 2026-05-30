import 'dart:async';
import 'dart:convert';
import 'dart:io' show NetworkInterface, InternetAddressType;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr/qr.dart';
import '../services/auth_manager.dart';
import '../services/audit_log_service.dart';
import '../services/bird_archive_service.dart';
import '../services/discovery_server.dart';
import '../services/staff_service.dart';
import 'audit_log_screen.dart';
import 'bird_archive_screen.dart';
import 'dashboard_screen.dart';
import 'rooms_screen.dart';
import 'species_config_screen.dart';
import 'staff_screen.dart';
import 'sidebar.dart';
import '../theme/theme.dart';
import '../utils/app_version.dart';

class _QrCodePainter extends CustomPainter {
  final QrImage _qr;
  _QrCodePainter(String data)
      : _qr = QrImage(
            QrCode.fromData(
                data: data, errorCorrectLevel: QrErrorCorrectLevel.M));

  @override
  void paint(Canvas canvas, Size size) {
    final count = _qr.moduleCount;
    if (count == 0) return;
    final moduleSize = size.width / count;
    final white = Paint()..color = Colors.white;
    final black = Paint()..color = const Color(0xFF1A1A2E);

    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        final paint = _qr.isDark(row, col) ? black : white;
        canvas.drawRect(
          Rect.fromLTWH(
              col * moduleSize, row * moduleSize, moduleSize, moduleSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) => false;
}

const _defaultHost = 'localhost';
const _defaultPort = 8080;
const _defaultPin = '1234';

class DesktopLayout extends StatefulWidget {
  const DesktopLayout({super.key});
  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _TabData {
  final int index;
  final Widget widget;
  final String? customLabel;
  _TabData(this.index, this.widget, {this.customLabel});
}

class _DesktopLayoutState extends State<DesktopLayout>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;
  bool _isDark = false;

  AuditLogService? _logService;
  BirdArchiveService? _birdService;
  StaffService? _staffService;
  SpeciesService? _speciesService;
  RoomService? _roomService;
  bool _connecting = true;
  String? _connectError;
  final _refreshKey = ValueNotifier(0);
  Timer? _pollTimer;
  int _pollInterval = 3;
  int _idleCount = 0;
  static const int _pollFast = 3;
  static const int _pollSlow = 15;
  static const int _pollIdle = 5; // idle intervals before backing off
  int _lastVersion = 0;
  String? _token;
  DiscoveryServer? _discovery;

  // Multi-tab — left/right panes for split view
  final List<_TabData> _leftTabs = [];
  final List<_TabData> _rightTabs = [];
  TabController? _leftTabCtrl;
  TabController? _rightTabCtrl;
  double _splitRatio = 0.5;
  final _rightPaneActive = ValueNotifier<bool>(false);
  bool _isDragging = false;
  bool _dragFromLeft = false;

  static const _maxTabs = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _leftTabCtrl = TabController(length: 0, vsync: this);
    _autoConnect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollInterval = _pollFast;
      _idleCount = 0;
      _checkVersion();
    }
  }

  // ── Open tab — routes to active pane in split view ──
  void _openTab(int index) {
    if (_leftTabCtrl == null) return;

    // In split view, route to active pane
    if (_rightTabs.isNotEmpty) {
      if (_rightPaneActive.value) {
        _openTabInPane(index, rightPane: true);
      } else {
        _openTabInPane(index, rightPane: false);
      }
      return;
    }

    _openTabInPane(index, rightPane: false);
  }

  void _openTabInPane(int index, {required bool rightPane}) {
    // Global dedup: all pages except BirdArchive (index 2) must be unique
    // across both panes. BirdArchive can appear in both panes simultaneously.
    if (index != 2) {
      final leftIdx = _leftTabs.indexWhere((t) => t.index == index);
      if (leftIdx >= 0) {
        _leftTabCtrl?.animateTo(leftIdx);
        setState(() { _selectedIndex = index; _rightPaneActive.value = false; });
        return;
      }
      final rightIdx = _rightTabs.indexWhere((t) => t.index == index);
      if (rightIdx >= 0) {
        _rightTabCtrl?.animateTo(rightIdx);
        setState(() { _selectedIndex = index; _rightPaneActive.value = true; });
        return;
      }
    }

    // Target-pane dedup
    final tabs = rightPane ? _rightTabs : _leftTabs;
    final existing = tabs.indexWhere((t) => t.index == index);
    if (existing >= 0) {
      if (rightPane) {
        _rightTabCtrl?.animateTo(existing);
      } else {
        _leftTabCtrl?.animateTo(existing);
      }
      setState(() => _selectedIndex = index);
      return;
    }

    final widget = _buildScreen(index,
        hideBirdList: rightPane && index == 2);

    if (tabs.length >= _maxTabs) tabs.removeAt(0);

    setState(() {
      tabs.add(_TabData(index, widget));
      _selectedIndex = index;
    });

    if (rightPane) {
      _rebuildRightCtrl(tabs.length - 1);
    } else {
      _rebuildLeftCtrl(tabs.length - 1);
    }
  }

  // ── Open bird in right pane — replaces existing bird archive tab ──
  void _openBirdInRightPane(BirdInfo bird) {
    final ringNumber = bird.ringNumber;
    final label = ringNumber != null && ringNumber.isNotEmpty
        ? ringNumber
        : bird.name;

    final widget = KeyedSubtree(
      key: ValueKey('bird_${bird.id}'),
      child: _buildScreen(2, focusBirdId: bird.id, hideBirdList: true),
    );

    // If right pane already has a bird archive tab, replace it
    final existingIdx = _rightTabs.indexWhere((t) => t.index == 2);
    if (existingIdx >= 0) {
      setState(() {
        _rightTabs[existingIdx] = _TabData(2, widget, customLabel: label);
        _rightPaneActive.value = true;
      });
      if (_rightTabCtrl != null && existingIdx < _rightTabCtrl!.length) {
        _rightTabCtrl!.animateTo(existingIdx);
      }
      return;
    }

    setState(() {
      _rightTabs.add(_TabData(2, widget, customLabel: label));
      _rightPaneActive.value = true;
    });
    _rebuildRightCtrl(_rightTabs.length - 1);
  }

  // ── Close tab ──
  void _closeTab(int tabIdx, {bool rightPane = false}) {
    if (rightPane) {
      _closeRightTab(tabIdx);
    } else {
      _closeLeftTab(tabIdx);
    }
  }

  void _closeLeftTab(int tabIdx) {
    if (_leftTabs.length <= 1) {
      if (_rightTabs.isNotEmpty) {
        // Left empty → right takes over
        setState(() {
          _leftTabs.clear();
          _leftTabCtrl?.dispose();
          _leftTabCtrl = null;
          _leftTabs.addAll(_rightTabs);
          _rightTabs.clear();
          _rightTabCtrl?.dispose();
          _rightTabCtrl = null;
          _selectedIndex = _leftTabs.first.index;
        });
        _rebuildLeftCtrl(0);
      }
      return;
    }
    final removedTab = _leftTabs[tabIdx];
    setState(() => _leftTabs.removeAt(tabIdx));

    if (_leftTabs.isEmpty) {
      _leftTabs.addAll(_rightTabs);
      _rightTabs.clear();
      _rightTabCtrl?.dispose();
      _rightTabCtrl = null;
      _selectedIndex = _leftTabs.first.index;
      _rebuildLeftCtrl(0);
      return;
    }

    int newIndex = tabIdx < _leftTabs.length ? tabIdx : _leftTabs.length - 1;
    _rebuildLeftCtrl(newIndex);
    if (removedTab.index == _selectedIndex && _leftTabs.isNotEmpty) {
      _selectedIndex = _leftTabs[newIndex].index;
    }
  }

  // ── Drag any tab to right pane for split (move, not copy) ──
  void _openTabInRightPane(int index) {
    // Guard: don't add duplicate
    if (_rightTabs.any((t) => t.index == index)) return;

    final leftIdx = _leftTabs.indexWhere((t) => t.index == index);
    if (leftIdx < 0) return;
    // Don't move the last left tab
    if (_leftTabs.length <= 1) return;

    final label = _tabLabels[index];
    final hideBird = index == 2;
    final widget = _buildScreen(index, hideBirdList: hideBird);

    setState(() {
      _leftTabs.removeAt(leftIdx);
      _rightTabs.add(_TabData(index, widget, customLabel: hideBird ? null : label));
      _rightPaneActive.value = true;
    });
    _rebuildLeftCtrl(_leftTabCtrl!.index.clamp(0, _leftTabs.length - 1));
    _rebuildRightCtrl(_rightTabs.length - 1);
  }

  // ── Drag right-pane tab back to left pane ──
  void _openTabInLeftPane(int index) {
    final rightIdx = _rightTabs.indexWhere((t) => t.index == index);
    final leftHas = _leftTabs.any((t) => t.index == index);
    debugPrint('[SPLIT] openInLeft index=$index rightIdx=$rightIdx leftHas=$leftHas');
    if (rightIdx < 0) return;

    setState(() {
      _rightTabs.removeAt(rightIdx);

      if (!_leftTabs.any((t) => t.index == index)) {
        _leftTabs.add(_TabData(index, _buildScreen(index)));
      }
    });

    if (_leftTabs.length > _leftTabCtrl!.length) {
      _rebuildLeftCtrl(_leftTabs.length - 1);
    }

    if (_rightTabs.isEmpty) {
      _rightTabCtrl?.dispose();
      _rightTabCtrl = null;
    } else {
      _rebuildRightCtrl(_rightTabCtrl!.index.clamp(0, _rightTabs.length - 1));
    }
    debugPrint('[SPLIT] done leftLen=${_leftTabs.length} rightLen=${_rightTabs.length}');
  }

  void _closeRightTab(int tabIdx) {
    setState(() => _rightTabs.removeAt(tabIdx));

    if (_rightTabs.isEmpty) {
      _rightTabCtrl?.dispose();
      _rightTabCtrl = null;
      return;
    }

    int newIndex = tabIdx < _rightTabs.length ? tabIdx : _rightTabs.length - 1;
    _rebuildRightCtrl(newIndex);
  }

  void _rebuildLeftCtrl(int selectIdx) {
    _leftTabCtrl?.dispose();
    _leftTabCtrl = TabController(
      length: _leftTabs.length,
      vsync: this,
      initialIndex: selectIdx.clamp(0, _leftTabs.length - 1),
    );
    _leftTabCtrl!.addListener(() {
      if (!_leftTabCtrl!.indexIsChanging) {
        final ti = _leftTabCtrl!.index;
        if (ti >= 0 && ti < _leftTabs.length) {
          setState(() => _selectedIndex = _leftTabs[ti].index);
        }
      }
    });
  }

  void _rebuildRightCtrl(int selectIdx) {
    _rightTabCtrl?.dispose();
    _rightTabCtrl = TabController(
      length: _rightTabs.length,
      vsync: this,
      initialIndex: selectIdx.clamp(0, _rightTabs.length - 1),
    );
    _rightTabCtrl!.addListener(() {
      if (!_rightTabCtrl!.indexIsChanging) {
        final ti = _rightTabCtrl!.index;
        if (ti >= 0 && ti < _rightTabs.length) {
          _selectedIndex = _rightTabs[ti].index;
        }
        setState(() {});
      }
    });
  }

  Widget _buildScreen(int index, {int? focusBirdId, bool hideBirdList = false}) {
    final bird = _birdService!;
    final log = _logService!;
    final staff = _staffService!;
    final sp = _speciesService!;
    final room = _roomService!;

    return switch (index) {
      0 => DashboardScreen(
          birdService: bird,
          staffService: staff,
          logService: log,
          refreshKey: _refreshKey),
      1 => AuditLogScreen(service: log, refreshKey: _refreshKey),
      2 => BirdArchiveScreen(
          service: bird,
          roomService: room,
          speciesService: sp,
          refreshKey: _refreshKey,
          focusBirdId: focusBirdId,
          hideBirdList: hideBirdList,
          onBirdDragToSplit: _openBirdInRightPane,
          routeToRightPane: hideBirdList ? null : _rightPaneActive,
        ),
      3 => StaffScreen(service: staff, refreshKey: _refreshKey),
      4 => DesktopRoomsScreen(
          roomService: room,
          staffService: staff,
          birdService: bird,
          refreshKey: _refreshKey),
      5 => SpeciesConfigScreen(service: sp, refreshKey: _refreshKey),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _autoConnect() async {
    setState(() { _connecting = true; _connectError = null; });
    final token = await AuthManager.authenticate(
        host: _defaultHost, port: _defaultPort, pin: _defaultPin);
    if (token != null) {
      _token = token;
      final auth = AuthManager(
          host: _defaultHost, port: _defaultPort, pin: _defaultPin, token: token);
      setState(() {
        _logService = AuditLogService(serverHost: _defaultHost, serverPort: _defaultPort, auth: auth);
        _birdService = BirdArchiveService(serverHost: _defaultHost, serverPort: _defaultPort, auth: auth);
        _staffService = StaffService(serverHost: _defaultHost, serverPort: _defaultPort, auth: auth);
        _speciesService = SpeciesService(serverHost: _defaultHost, serverPort: _defaultPort, auth: auth);
        _roomService = RoomService(serverHost: _defaultHost, serverPort: _defaultPort, auth: auth);
        _connecting = false;
      });
      _startPolling();
      _startDiscovery();
      _openTab(0);
    } else {
      setState(() { _connectError = '无法连接到服务器 $_defaultHost:$_defaultPort'; _connecting = false; });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollInterval = _pollFast;
    _idleCount = 0;
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(Duration(seconds: _pollInterval), () {
      _checkVersion();
      _scheduleNextPoll();
    });
  }

  void _startDiscovery() async {
    final ip = await _lanIp();
    _discovery = DiscoveryServer(host: ip, port: _defaultPort);
    await _discovery!.start();
  }

  Future<void> _checkVersion() async {
    if (_token == null) return;
    try {
      final res = await http
          .get(Uri.parse('http://$_defaultHost:$_defaultPort/data-version'),
              headers: {'X-Token': _token!})
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final v = int.tryParse(res.body) ?? 0;
        if (v > _lastVersion) {
          _lastVersion = v;
          _doRefresh();
          _pollInterval = _pollFast;
          _idleCount = 0;
        } else {
          _idleCount++;
          if (_idleCount >= _pollIdle * 2) {
            _pollInterval = _pollSlow * 2;
          } else if (_idleCount >= _pollIdle) {
            _pollInterval = _pollSlow;
          }
        }
      }
    } catch (_) {}
  }

  void _doRefresh() => _refreshKey.value++;

  Future<String> _lanIp() async {
    try {
      String? best;
      for (final iface in await NetworkInterface.list()) {
        final name = iface.name.toLowerCase();
        if (name.contains('vmware') || name.contains('virtualbox') ||
            name.contains('hyper-v') || name.contains('vethernet') ||
            name.contains('tun') || name.contains('tap') ||
            name.contains('utun') || name.contains('clash') ||
            name.contains('mihomo') || name.contains('vpn') ||
            name.contains('ppp') || name.contains('pppoe') ||
            name.contains('wintun')) { continue; }
        final isWireless = name.contains('wlan') ||
            name.contains('wi-fi') || name.contains('wireless');
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final a = addr.address;
            if (a.startsWith('127.')) continue;
            if (a.startsWith('172.17.')) continue;
            if (isWireless && a.startsWith('192.168.')) return a;
            if (isWireless && a.startsWith('10.')) return a;
            if (a.startsWith('192.168.')) { best ??= a; }
            if (best == null && a.startsWith('10.')) best = a;
            best ??= a;
          }
        }
      }
      if (best != null) return best;
    } catch (_) {}
    return _defaultHost;
  }

  Future<void> _showQrLogin() async {
    if (_token == null) return;
    try {
      final res = await http
          .post(Uri.parse('http://$_defaultHost:$_defaultPort/auth/qr-session?host=${await _lanIp()}'),
              headers: {'X-Token': _token!})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('生成登录码失败')));
        return;
      }
      final data = jsonDecode(res.body);
      final session = data['session'] as String;
      final host = data['host'] as String;
      final port = data['port'] as int;

      if (!mounted) return;
      final qrData = jsonEncode({'host': host, 'port': port, 'session': session});
      showDialog(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Row(children: [
            Icon(Icons.qr_code, color: Colors.blue), SizedBox(width: 8), Text('扫码登录'),
          ]),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          children: [
            const Text('请用手机扫描二维码登录（免密码）', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Center(child: SizedBox(width: 200, height: 200, child: CustomPaint(painter: _QrCodePainter(qrData)))),
            const SizedBox(height: 12),
            Text('$host:$port', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
            Text('会话码: $session（2 分钟有效）', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
              FilledButton.tonalIcon(
                onPressed: () { Navigator.pop(ctx); _showQrLogin(); },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('刷新'),
              ),
            ]),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成登录码失败: $e')));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _discovery?.stop();
    _pollTimer?.cancel();
    _refreshKey.dispose();
    _leftTabCtrl?.dispose();
    _rightTabCtrl?.dispose();
    _rightPaneActive.dispose();
    super.dispose();
  }

  bool get _ready => !_connecting &&
      _birdService != null &&
      _logService != null &&
      _staffService != null &&
      _speciesService != null &&
      _roomService != null &&
      _leftTabCtrl != null &&
      _leftTabs.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_ready) return _buildLoading();
    if (_connectError != null) return _buildError();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final split = _rightTabs.isNotEmpty;

    final body = Column(children: [
      _TopBar(isDark: _isDark, onToggleTheme: () => setState(() => _isDark = !_isDark)),
      Expanded(
        child: Row(children: [
          CollapsibleSidebar(
            collapsed: _sidebarCollapsed,
            selectedIndex: _selectedIndex,
            onSelect: _openTab,
            onToggle: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            onQrLogin: _showQrLogin,
            onRefresh: _doRefresh,
          ),
          Expanded(
            child: split ? _buildSplitView(scheme, theme) : _buildSingleView(scheme),
          ),
        ]),
      ),
      _BottomStatusBar(scheme: scheme),
    ]);

    return Theme(
      data: _isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      child: Scaffold(body: body),
    );
  }

  // ── Single pane ──
  Widget _buildSingleView(ColorScheme scheme) {
    return Column(
      children: [
        if (_leftTabs.isNotEmpty)
          _TabHeader(
            tabs: _leftTabs,
            tabController: _leftTabCtrl!,
            onClose: (i) => _closeTab(i),
            scheme: scheme,
            onTabDragToSplit: _openTabInRightPane,
          ),
        Expanded(
          child: _leftTabs.isNotEmpty
              ? TabBarView(controller: _leftTabCtrl!, children: _leftTabs.map((t) => t.widget).toList())
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Split pane ──
  Widget _buildSplitView(ColorScheme scheme, ThemeData theme) {
    Widget buildPane({
      required List<_TabData> tabs,
      required TabController ctrl,
      required bool isLeft,
    }) {
      final active = _rightPaneActive.value == !isLeft;
      final isDropTarget = _isDragging && (_dragFromLeft != isLeft);
      final header = tabs.isNotEmpty
          ? _TabHeader(
              tabs: tabs,
              tabController: ctrl,
              onClose: (i) => _closeTab(i, rightPane: !isLeft),
              scheme: scheme,
              isRightPane: !isLeft,
              onTabDragToSplit: isLeft ? _openTabInRightPane : _openTabInLeftPane,
              dragToLeft: !isLeft,
              onDragStarted: () => setState(() { _isDragging = true; _dragFromLeft = isLeft; }),
              onDragEnded: () => setState(() { _isDragging = false; }),
            )
          : const SizedBox.shrink();

      return Expanded(
        flex: isLeft
            ? (_splitRatio * 1000).round()
            : ((1 - _splitRatio) * 1000).round(),
        child: GestureDetector(
          onTap: () {
            _rightPaneActive.value = !isLeft;
            // Sync sidebar to the newly active pane's selected tab
            if (ctrl.index >= 0 && ctrl.index < tabs.length) {
              _selectedIndex = tabs[ctrl.index].index;
            }
            setState(() {});
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: active ? scheme.primary : Colors.transparent,
                  width: 2.5,
                ),
                left: isDropTarget && !isLeft
                    ? BorderSide(color: scheme.primary, width: 2.5)
                    : BorderSide.none,
                right: isDropTarget && isLeft
                    ? BorderSide(color: scheme.primary, width: 2.5)
                    : BorderSide.none,
              ),
              color: isDropTarget
                  ? scheme.primary.withAlpha(12)
                  : Colors.transparent,
            ),
            child: Column(children: [
              header,
              Expanded(
                child: tabs.isNotEmpty
                    ? TabBarView(controller: ctrl, children: tabs.map((t) => t.widget).toList())
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildPane(tabs: _leftTabs, ctrl: _leftTabCtrl!, isLeft: true),
        _Splitter(
          onDrag: (dx, totalWidth) {
            setState(() {
              _splitRatio = (_splitRatio + dx / totalWidth).clamp(0.25, 0.75);
            });
          },
        ),
        buildPane(tabs: _rightTabs, ctrl: _rightTabCtrl!, isLeft: false),
      ],
    );
  }

  Widget _buildLoading() => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.pets, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('WeightNest 管理端',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('正在连接服务器...',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
          ]),
        ),
      );

  Widget _buildError() => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_connectError!, style: TextStyle(color: Colors.red.shade400)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _autoConnect, icon: const Icon(Icons.refresh), label: const Text('重试连接')),
          ]),
        ),
      );
}

// ── Draggable vertical splitter ──
class _Splitter extends StatelessWidget {
  final void Function(double dx, double totalWidth) onDrag;

  const _Splitter({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) {
        final totalWidth = MediaQuery.of(context).size.width;
        onDrag(d.delta.dx, totalWidth);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 6,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 2,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withAlpha(60),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar ──
class _TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  const _TopBar({required this.isDark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withAlpha(50))),
      ),
      child: Row(children: [
        Icon(Icons.pets, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text('WeightNest 管理端', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.primary)),
        const SizedBox(width: 16),
        _BreathingDot(scheme: scheme),
        const SizedBox(width: 6),
        const Text('已连接 $_defaultHost:$_defaultPort', style: TextStyle(fontSize: 11, color: Color(0xFF6B8F71))),
        const Spacer(),
        IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
          onPressed: onToggleTheme,
          tooltip: isDark ? '切换亮色' : '切换暗色',
          splashRadius: 16,
          color: scheme.onSurface.withAlpha(160),
        ),
        Text('v$appVersion', style: TextStyle(fontSize: 11, color: scheme.onSurface.withAlpha(120))),
      ]),
    );
  }
}

class _BreathingDot extends StatefulWidget {
  final ColorScheme scheme;
  const _BreathingDot({required this.scheme});
  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(const Color(0xFF6B8F71), const Color(0xFF4A6B50), _ctrl.value)!,
        ),
      ),
    );
  }
}

const _tabLabels = ['概览', '操作日志', '鹦鹉档案', '人员管理', '房间管理', '品种配置'];

// ── Tab header (supports left and right pane, right pane uses customLabel) ──
class _TabHeader extends StatelessWidget {
  final List<_TabData> tabs;
  final TabController tabController;
  final void Function(int) onClose;
  final ColorScheme scheme;
  final bool isRightPane;
  final void Function(int tabIndex)? onTabDragToSplit;
  final bool dragToLeft;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const _TabHeader({
    required this.tabs,
    required this.tabController,
    required this.onClose,
    required this.scheme,
    this.isRightPane = false,
    this.onTabDragToSplit,
    this.dragToLeft = false,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withAlpha(40))),
      ),
      child: Row(children: [
        if (isRightPane) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(Icons.compare_arrows, size: 14, color: scheme.onSurface.withAlpha(120)),
          ),
        ],
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            itemBuilder: (_, i) {
              final isSelected = tabController.index == i;
              final label = isRightPane
                  ? (tabs[i].customLabel ?? _tabLabels[tabs[i].index])
                  : _tabLabels[tabs[i].index];
              final tabContent = Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? scheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? scheme.primary : scheme.onSurface.withAlpha(160),
                        )),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onClose(i),
                      child: Icon(Icons.close, size: 14, color: scheme.onSurface.withAlpha(100)),
                    ),
                  ]),
                );

              if (onTabDragToSplit == null) {
                return GestureDetector(
                  onTap: () => tabController.animateTo(i),
                  child: tabContent,
                );
              }

              // Use _DraggableTab — supports both mouse drag (immediate) and
              // touch long-press via a dual-mode gesture detector.
              return _DraggableTab(
                key: ValueKey('drag_${tabs[i].index}'),
                tabIndex: tabs[i].index,
                label: label,
                isSelected: isSelected,
                scheme: scheme,
                tabController: tabController,
                tabIndexInList: i,
                tabContent: tabContent,
                onDragToSplit: onTabDragToSplit!,
                dragToLeft: dragToLeft,
                onDragStarted: onDragStarted,
                onDragEnded: onDragEnded,
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Draggable tab — supports both mouse and touch drag-to-split ──
// Uses a fixed pixel-offset threshold (120 px) independent of screen
// size or tab position.  Fires onDragStarted/onDragEnded so the parent
// can show a drop-zone highlight on the target pane.
class _DraggableTab extends StatefulWidget {
  final int tabIndex;
  final String label;
  final bool isSelected;
  final ColorScheme scheme;
  final TabController tabController;
  final int tabIndexInList;
  final Widget tabContent;
  final void Function(int tabIndex) onDragToSplit;
  final bool dragToLeft;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const _DraggableTab({
    super.key,
    required this.tabIndex,
    required this.label,
    required this.isSelected,
    required this.scheme,
    required this.tabController,
    required this.tabIndexInList,
    required this.tabContent,
    required this.onDragToSplit,
    this.dragToLeft = false,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  State<_DraggableTab> createState() => _DraggableTabState();
}

class _DraggableTabState extends State<_DraggableTab> {
  bool _pointerIsDown = false;
  bool _dragFired = false;

  void _onDragStarted() {
    _dragFired = true;
    debugPrint('[DRAG] started label="${widget.label}"');
    widget.onDragStarted?.call();
  }

  void _onPointerDown(PointerDownEvent _) {
    _pointerIsDown = true;
    _dragFired = false;
  }

  void _onPointerUp(PointerUpEvent _) {
    if (_pointerIsDown && !_dragFired) {
      widget.tabController.animateTo(widget.tabIndexInList);
    }
    _pointerIsDown = false;
  }

  void _onPointerMove(PointerMoveEvent _) {
    _pointerIsDown = false;
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<int>(
      data: widget.tabIndex,
      delay: const Duration(milliseconds: 150),
      onDragStarted: _onDragStarted,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(4),
        color: widget.scheme.surfaceContainerHighest,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.compare_arrows, size: 14, color: widget.scheme.primary),
            const SizedBox(width: 6),
            Text(widget.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.scheme.primary)),
          ]),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: widget.tabContent),
      onDragEnd: (details) {
        final dx = details.offset.dx;
        final hit = dx.abs() > 120;
        debugPrint('[DRAG] end dx=$dx hit=$hit tabIndex=${widget.tabIndex}');
        if (hit) {
          widget.onDragToSplit(widget.tabIndex);
        }
        _dragFired = false;
        widget.onDragEnded?.call();
      },
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerMove: _onPointerMove,
        child: widget.tabContent,
      ),
    );
  }
}

// ── Bottom status bar ──
class _BottomStatusBar extends StatelessWidget {
  final ColorScheme scheme;
  const _BottomStatusBar({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withAlpha(40))),
      ),
      child: Row(children: [
        Icon(Icons.sync, size: 12, color: scheme.onSurface.withAlpha(120)),
        const SizedBox(width: 4),
        Text('数据实时同步', style: TextStyle(fontSize: 10, color: scheme.onSurface.withAlpha(120))),
        const Spacer(),
        Text('v$appVersion', style: TextStyle(fontSize: 10, color: scheme.onSurface.withAlpha(100))),
      ]),
    );
  }
}
