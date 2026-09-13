import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../api/client.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'series_screen.dart';

/// Tab Cari: hanya mencari judul series, bukan posting chapter.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final KomikuClient _client = KomikuClient.instance;
  final TextEditingController _controller = TextEditingController();

  List<BrowseCard> _results = const [];
  Timer? _debounce;
  bool _loading = false;
  bool _searched = false;
  String _lastQuery = '';
  Object? _error;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) {
      _requestId++;
      setState(() {
        _loading = false;
        _searched = false;
        _results = const [];
        _error = null;
        _lastQuery = '';
      });
      return;
    }

    // Cari otomatis setelah user selesai mengetik. Satu karakter tetap dapat
    // dicari dengan menekan tombol Search pada keyboard.
    if (q.length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
    }
  }

  Future<void> _search(String raw) async {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) return;
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _searched = true;
      _lastQuery = q;
      _error = null;
    });

    try {
      final results = await _client.search(q);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = const [];
        _error = e;
        _loading = false;
      });
    }
  }

  void _openSeries(BrowseCard card) {
    final initial = ComicCard(
      slug: card.slug,
      title: card.title,
      cover: card.cover,
      lastChapterSlug: card.lastChapterSlug,
    );
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => SeriesScreen(slug: card.slug, initial: initial),
      ),
    );
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
                placeholder: 'Cari judul komik…',
                onChanged: _onQueryChanged,
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
              hasScrollBody: false,
              child: EmptyState(
                icon: CupertinoIcons.search,
                title: 'Pencarian gagal',
                subtitle:
                    'Periksa koneksi internet lalu coba lagi.\n${errorDetail(_error)}',
                onRetry: () => _search(_lastQuery),
              ),
            )
          else if (!_searched)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
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
                        'Masukkan nama manga, manhwa, atau manhua. Hasil pencarian tidak lagi bercampur dengan chapter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: ctx.muted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: CupertinoIcons.question_circle,
                title: 'Tidak ada judul ditemukan',
                subtitle:
                    'Tidak ditemukan komik untuk “$_lastQuery”. Coba kata kunci lain.',
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Hasil Komik',
                icon: CupertinoIcons.book,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => BrowseRow(
                    card: _results[i],
                    onTap: () => _openSeries(_results[i]),
                  ),
                  childCount: _results.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
