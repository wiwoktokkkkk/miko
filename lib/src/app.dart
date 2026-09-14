import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'models.dart';
import 'security/security_service.dart';
import 'screens/browse_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/search_screen.dart';
import 'theme/app_theme.dart';

/// Root aplikasi Miko — mengikuti mode terang/gelap sistem.
class MikoApp extends StatefulWidget {
  const MikoApp({super.key});

  @override
  State<MikoApp> createState() => _MikoAppState();
}

class _MikoAppState extends State<MikoApp> with WidgetsBindingObserver {
  Timer? _securityTimer;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _securityTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_active) SecurityService.instance.refresh();
    });
  }

  @override
  void dispose() {
    _securityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) SecurityService.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    return CupertinoApp(
      title: 'Miko',
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: const _SecurityGate(),
    );
  }
}

class _SecurityGate extends StatelessWidget {
  const _SecurityGate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SecurityService.instance,
      builder: (context, _) {
        final status = SecurityService.instance.status;
        return status.isSecure
            ? const _RootShell()
            : _SecurityBlockedScreen(status: status);
      },
    );
  }
}

class _SecurityBlockedScreen extends StatelessWidget {
  const _SecurityBlockedScreen({required this.status});

  final SecurityStatus status;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return CupertinoPageScaffold(
      backgroundColor: ctx.bg,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.systemRed.withValues(alpha: 0.12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.lock_fill,
                    size: 34,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Akses Miko diblokir',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ctx.text,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  status.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemRed.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  status.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: ctx.muted,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: () => SecurityService.instance.refresh(),
                    child: const Text('Periksa Lagi'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mode keamanan ketat aktif',
                  style: TextStyle(fontSize: 12, color: ctx.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _tab = 0;
  final GlobalKey<BrowseScreenState> _browseKey =
      GlobalKey<BrowseScreenState>();
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeScreen(onOpenPopuler: () => _go(1), onOpenBrowse: _openBrowse),
      const RankingScreen(),
      BrowseScreen(key: _browseKey),
      const SearchScreen(),
      const FavoritesScreen(),
    ];
  }

  void _go(int index) => setState(() => _tab = index);

  void _openBrowse({GenreInfo? genre, String? status}) {
    if (genre != null || status != null) {
      _browseKey.currentState?.setFilter(genre: genre, status: status);
    }
    _go(2);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _tab, children: _tabs),
          ),
          CupertinoTabBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.house),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chart_bar_fill),
                label: 'Populer',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.square_grid_2x2),
                label: 'Jelajah',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.search),
                label: 'Cari',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.heart),
                label: 'Favorit',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
