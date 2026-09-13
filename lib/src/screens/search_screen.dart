import 'package:flutter/cupertino.dart';

import '../api/client.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'reader_screen.dart';
import 'series_screen.dart';

/// Tab Cari: pencarian judul & chapter via wp-json komiku.org.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final KomikuClient _client = KomikuClient.instance;
  final _controller = TextEditingController();

  List<SearchResult> _results = const [];
  bool _loading = false;
  bool _searched = false;
  String _lastQuery = '';
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.addListener(_onQueryChanged);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    // reset tampilan saat teks dikosongkan
    if (_controller.text.trim().isEmpty && _searched) {
      setState(() {
        _searched = false;
        _results = const [];
      });
    }
  }

  Future<void> _search(String raw) async {
    final q = raw.trim();
    if (q.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _searched = true;
      _lastQuery = q;
      _error = null;
    });
    try {
      final results = await _client.search(q);
      if (!mounted) return;
      setState(() {
        _results = results;
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

  List<SearchResult> get _series =>
      _results.where((r) => !r.isChapter).toList();
  List<SearchResult> get _chapters =>
      _results.where((r) => r.isChapter).toList();

  void _openSeries(SearchResult r) {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => SeriesScreen(slug: r.slug)));
  }

  Future<void> _openChapter(SearchResult r) async {
    try {
      final series = await _client.series(r.seriesSlug);
      if (!mounted) return;
      final idx = series.chapters.indexWhere((c) => c.slug == r.slug);
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) =>
              ReaderScreen(series: series, index: idx >= 0 ? idx : 0),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final info = SeriesInfo(
        slug: r.seriesSlug,
        title: r.title,
        chapters: [Chapter(r.slug, r.title, '')],
      );
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => ReaderScreen(series: info, index: 0),
        ),
      );
    }
  }

  /// Rasio aspek sel grid hasil pencarian.
  double _aspect(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 32 - 20) / 3;
    final h = w * 4 / 3 + 35;
    return w / h;
  }

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return CupertinoPageScaffold(
      backgroundColor: ctx.bg,
      child: CustomScrollView(
        physics: iosPhysics,
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Cari')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: CupertinoSearchTextField(
                controller: _controller,
                placeholder: 'Judul komik, manhwa, manhua…',
                onSubmitted: _search,
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: EmptyState(
                icon: CupertinoIcons.search,
                title: 'Pencarian gagal',
                subtitle: 'Periksa koneksi internet lalu coba lagi.',
                onRetry: () => _search(_lastQuery),
              ),
            )
          else if (!_searched)
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 40,
                      color: ctx.muted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Cari judul komik',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ctx.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ketik di atas lalu tekan Cari. Hasil chapter juga dapat dibuka langsung.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: ctx.muted),
                    ),
                  ],
                ),
              ),
            )
          else if (_results.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: CupertinoIcons.question_circle,
                title: 'Tidak ada hasil',
                subtitle:
                    'Tidak ditemukan untuk "$_lastQuery". Coba kata kunci lain.',
              ),
            )
          else ...[
            if (_series.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Series',
                  icon: CupertinoIcons.book,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 14,
                    childAspectRatio: _aspect(context),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => SearchTile(
                      result: _series[i],
                      onTap: () => _openSeries(_series[i]),
                    ),
                    childCount: _series.length,
                  ),
                ),
              ),
            ],
            if (_chapters.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Chapter',
                  icon: CupertinoIcons.doc_text,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: ctx.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ctx.separator.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _chapters.length; i++) ...[
                        if (i > 0)
                          Container(
                            height: 0.6,
                            margin: const EdgeInsets.only(left: 42),
                            color: ctx.separator,
                          ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openChapter(_chapters[i]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 14,
                                  color: ctx.muted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _chapters[i].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ctx.text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  CupertinoIcons.chevron_compact_right,
                                  size: 11,
                                  color: ctx.muted.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ],
      ),
    );
  }
}
