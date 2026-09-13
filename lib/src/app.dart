import 'package:flutter/cupertino.dart';

import 'models.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final dark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    return CupertinoApp(
      title: 'Miko',
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: const _RootShell(),
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
