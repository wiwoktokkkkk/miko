import 'package:flutter/cupertino.dart';

import '../api/client.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'genre_filter_screen.dart';
import 'series_screen.dart';

/// Tab Jelajah: katalog dengan filter tipe, genre, status, urutan
/// dan infinite scroll.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => BrowseScreenState();
}

class BrowseScreenState extends State<BrowseScreen> {
  final KomikuClient _client = KomikuClient.instance;
  final ScrollController _scroll = ScrollController();

  String _tipe = '';
  GenreInfo? _genre;
  String _status = '';
  String _orderby = 'modified';

  final List<BrowseCard> _cards = <BrowseCard>[];
  final Set<String> _seen = <String>{};
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(1);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Dipanggil dari shell saat user memilih genre/status di beranda.
  void setFilter({GenreInfo? genre, String? status}) {
    setState(() {
      if (genre != null) _genre = genre;
      if (status != null) _status = status;
    });
    _reload();
  }

  void _reload() {
    _cards.clear();
    _seen.clear();
    _page = 1;
    _hasMore = true;
    _load(1);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _load(int page) async {
    setState(() {
      if (page == 1) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final p = await _client.browse(
        tipe: _tipe,
        genre: _genre?.slug ?? '',
        status: _status,
        orderby: _orderby,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        for (final c in p.cards) {
          if (_seen.add(c.slug)) _cards.add(c);
        }
        _hasMore = p.hasNext;
        _page = page;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (page == 1) _error = e;
      });
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 700 &&
        _hasMore &&
        !_loading &&
        !_loadingMore) {
      _load(_page + 1);
    }
  }

  void _openSeries(BrowseCard c) {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => SeriesScreen(slug: c.slug)));
  }

  Future<void> _pickGenre() async {
    final result = await Navigator.of(context).push<Object>(
      CupertinoPageRoute(builder: (_) => GenreFilterScreen(current: _genre)),
    );
    if (!mounted || result == null) return;
    if (result is GenreNone) {
      setState(() => _genre = null);
    } else if (result is GenreInfo) {
      setState(() => _genre = result);
    }
    _reload();
  }

  void _pickStatus() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Status'),
        message: const Text('Filter berdasarkan status series'),
        actions: [
          _sheetRow('Semua', _status == '', () {
            setState(() => _status = '');
            _reload();
          }),
          _sheetRow('Ongoing', _status == 'ongoing', () {
            setState(() => _status = 'ongoing');
            _reload();
          }),
          _sheetRow('Tamat', _status == 'end', () {
            setState(() => _status = 'end');
            _reload();
          }),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Batal'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _pickOrderby() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Urutkan'),
        message: const Text('Cara mengurutkan katalog'),
        actions: [
          _sheetRow('Update Terbaru', _orderby == 'modified', () {
            setState(() => _orderby = 'modified');
            _reload();
          }),
          _sheetRow('Judul Baru', _orderby == 'post_date', () {
            setState(() => _orderby = 'post_date');
            _reload();
          }),
          _sheetRow('Acak', _orderby == 'rand', () {
            setState(() => _orderby = 'rand');
            _reload();
          }),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Batal'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _sheetRow(String label, bool selected, VoidCallback onTap) {
    final ctx = Ctx(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? ctx.accent : ctx.text,
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(CupertinoIcons.checkmark, size: 14, color: ctx.accent),
          ],
        ),
      ),
    );
  }

  List<String> get _tipeOptions => const ['', 'manga', 'manhwa', 'manhua'];
  List<String> get _tipeLabels => const ['Semua', 'Manga', 'Manhwa', 'Manhua'];

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return CustomScrollView(
      controller: _scroll,
      physics: iosPhysics,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: () async => _reload()),
        const CupertinoSliverNavigationBar(
          transitionBetweenRoutes: false,
          largeTitle: Text('Jelajah'),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var i = 0; i < _tipeOptions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: _tipeLabels[i],
                      selected: _tipe == _tipeOptions[i],
                      onTap: () {
                        setState(() => _tipe = _tipeOptions[i]);
                        _reload();
                      },
                    ),
                  ),
                const SizedBox(width: 4),
                FilterChip(
                  label: _genre == null ? 'Genre' : 'Genre: ${_genre!.name}',
                  icon: CupertinoIcons.tag,
                  selected: _genre != null,
                  onTap: _pickGenre,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: _status.isEmpty
                      ? 'Status'
                      : (_status == 'end' ? 'Tamat' : 'Ongoing'),
                  icon: CupertinoIcons.checkmark_circle,
                  selected: _status.isNotEmpty,
                  onTap: _pickStatus,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: 'Urutkan',
                  icon: CupertinoIcons.arrow_up_arrow_down,
                  onTap: _pickOrderby,
                ),
              ],
            ),
          ),
        ),
        if (_loading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                children: List.generate(
                  5,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: ctx.separator.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (_error != null && _cards.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              icon: CupertinoIcons.square_grid_2x2,
              title: 'Gagal memuat katalog',
              subtitle:
                  'Periksa koneksi internet lalu coba lagi.\n${errorDetail(_error)}',
              onRetry: _reload,
            ),
          )
        else if (_cards.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              icon: CupertinoIcons.search,
              title: 'Tidak ada hasil',
              subtitle: 'Coba ubah kombinasi filter tipe, genre, atau status.',
              onRetry: () {
                setState(() {
                  _tipe = '';
                  _genre = null;
                  _status = '';
                  _orderby = 'modified';
                });
                _reload();
              },
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => BrowseRow(
                  card: _cards[i],
                  onTap: () => _openSeries(_cards[i]),
                ),
                childCount: _cards.length,
              ),
            ),
          ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            )
          else if (!_hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Semua judul sudah dimuat',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: ctx.muted),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ],
    );
  }
}
