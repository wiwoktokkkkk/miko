import 'package:flutter/cupertino.dart';

import '../api/client.dart';
import '../models.dart';
import '../navigation/app_route.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'reader_screen.dart';
import '../widgets/cover_image.dart';
import '../api/parser.dart';
import 'series_screen.dart';

/// Tab Beranda: peringkat harian/mingguan, terbaru, baru ditambahkan,
/// umpak genre, dan riwayat baca.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenPopuler,
    required this.onOpenBrowse,
  });

  final VoidCallback onOpenPopuler;
  final void Function({GenreInfo? genre, String? status}) onOpenBrowse;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final KomikuClient _client = KomikuClient.instance;
  final AppStore _store = AppStore.instance;

  HomeData? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _client.home();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _openSeries(ComicCard c) {
    Navigator.of(context).push(
      mikoRoute(
        builder: (_) => SeriesScreen(slug: c.slug, initial: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: iosPhysics,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _load),
        const CupertinoSliverNavigationBar(
          transitionBetweenRoutes: false,
          largeTitle: Text('Beranda'),
        ),
        if (_loading)
          ..._loadingSlivers
        else if (_data == null)
          SliverFillRemaining(
            child: EmptyState(
              icon: CupertinoIcons.wifi_slash,
              title: 'Gagal memuat beranda',
              subtitle:
                  'Periksa koneksi internet lalu coba lagi.\n${errorDetail(_error)}',
              onRetry: _load,
            ),
          )
        else
          ..._contentSlivers,
      ],
    );
  }

  List<Widget> get _loadingSlivers {
    return [
      SliverToBoxAdapter(child: SectionHeader(title: 'Peringkat Harian')),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 258,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(height: 176, radius: 12),
                SizedBox(height: 8),
                Shimmer(height: 13, width: 100),
                SizedBox(height: 5),
                Shimmer(height: 11, width: 70),
              ],
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(child: SectionHeader(title: 'Terbaru')),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 258,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(height: 176, radius: 12),
                SizedBox(height: 8),
                Shimmer(height: 13, width: 100),
                SizedBox(height: 5),
                Shimmer(height: 11, width: 70),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> get _contentSlivers {
    final d = _data!;
    final slivers = <Widget>[];

    // Lanjut baca (riwayat)
    slivers.add(
      SliverToBoxAdapter(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final history = _store.history;
            if (history.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Lanjut Baca',
                  icon: CupertinoIcons.clock,
                ),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: history.length > 10 ? 10 : history.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final item = history[i];
                      return GestureDetector(
                        onTap: () => _continueReading(item),
                        child: SizedBox(
                          width: 168,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 46,
                                      height: 61,
                                      child: CoverImage(
                                        urls: Parser.coverCandidates(
                                          item.cover,
                                        ),
                                        placeholderTitle: item.seriesTitle,
                                        radius: 8,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.seriesTitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              height: 1.25,
                                              color: Ctx(context).text,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item.chapterLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Ctx(context).accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    slivers.add(
      _row(
        title: 'Peringkat Harian',
        icon: CupertinoIcons.chart_bar_fill,
        cards: d.rankHarian,
        onSeeAll: widget.onOpenPopuler,
        onTap: _openSeries,
      ),
    );
    slivers.add(
      _row(
        title: 'Peringkat Mingguan',
        icon: CupertinoIcons.calendar,
        cards: d.rankMingguan,
        onSeeAll: widget.onOpenPopuler,
        onTap: _openSeries,
      ),
    );
    slivers.add(
      _row(
        title: 'Terbaru',
        icon: CupertinoIcons.flame,
        cards: d.terbaru,
        onTap: _openSeries,
      ),
    );
    slivers.add(
      _row(
        title: 'Baru Ditambahkan',
        icon: CupertinoIcons.sparkles,
        cards: d.baru,
        onTap: _openSeries,
      ),
    );

    if (d.genreTiles.isNotEmpty) {
      slivers.add(
        const SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Genre',
            icon: CupertinoIcons.square_grid_2x2,
          ),
        ),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: d.genreTiles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 18),
              itemBuilder: (context, i) {
                final tile = d.genreTiles[i];
                return GestureDetector(
                  onTap: () {
                    final g = tile.genreSlug;
                    final s = tile.status;
                    if (g != null) {
                      widget.onOpenBrowse(genre: GenreInfo(g, tile.label, ''));
                    } else if (s != null) {
                      widget.onOpenBrowse(status: s);
                    }
                  },
                  child: Column(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 58,
                          height: 58,
                          child: tile.image.isEmpty
                              ? const Icon(
                                  CupertinoIcons.tag,
                                  size: 22,
                                  color: CupertinoColors.systemGrey,
                                )
                              : _TileImage(url: tile.image),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        tile.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Ctx(context).text,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    }

    return slivers;
  }

  Widget _row({
    required String title,
    required IconData icon,
    required List<ComicCard> cards,
    VoidCallback? onSeeAll,
    required void Function(ComicCard) onTap,
  }) {
    if (cards.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 266,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  HComicCard(card: cards[i], onTap: () => onTap(cards[i])),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _continueReading(HistoryItem item) async {
    try {
      final series = await _client.series(item.seriesSlug);
      if (!mounted) return;
      var idx = series.chapters.indexWhere((c) => c.slug == item.chapterSlug);
      if (idx < 0) idx = 0;
      Navigator.of(context).push(
        mikoRoute(
          builder: (_) => ReaderScreen(series: series, index: idx),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showError('Gagal membuka riwayat');
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(message),
        content: const Text('Periksa koneksi internet lalu coba lagi.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// Umpak gambar kecil (genre).
class _TileImage extends StatelessWidget {
  const _TileImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return Image.network(
      url,
      fit: BoxFit.cover,
      headers: KomikuClient.httpHeaders,
      errorBuilder: (_, _, _) => Container(
        color: ctx.separator.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child: const Icon(
          CupertinoIcons.tag,
          size: 20,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }
}
