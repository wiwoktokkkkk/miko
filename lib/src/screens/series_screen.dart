import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

import '../api/client.dart';
import '../api/parser.dart';
import '../models.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/cover_image.dart';
import 'reader_screen.dart';

/// Halaman detail series: info, sinopsis, daftar chapter.
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key, required this.slug, this.initial});

  final String slug;

  /// Card awal (dari grid) untuk menampilkan cover/judul lebih cepat.
  final ComicCard? initial;

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final KomikuClient _client = KomikuClient.instance;
  final AppStore _store = AppStore.instance;
  final _chQuery = TextEditingController();

  SeriesInfo? _info;
  Object? _error;
  bool _loading = true;
  bool _fullSyn = false;

  @override
  void initState() {
    super.initState();
    _chQuery.addListener(_onChapterQueryChanged);
    _load();
  }

  @override
  void dispose() {
    _chQuery.removeListener(_onChapterQueryChanged);
    _chQuery.dispose();
    super.dispose();
  }

  void _onChapterQueryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _client.series(widget.slug);
      if (!mounted) return;
      setState(() {
        _info = info;
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

  void _openReader(int index) {
    final info = _info!;
    if (index < 0 || index >= info.chapters.length) return;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ReaderScreen(series: info, index: index),
      ),
    );
  }

  void _toggleFav() {
    final info = _info;
    if (info == null) return;
    _store.toggleFav(info);
  }

  /// Indeks chapter terakhir yang dibaca (bila ada di riwayat).
  int? get _resumeIndex {
    final info = _info;
    if (info == null) return null;
    final h = _store.historyFor(info.slug);
    if (h == null) return null;
    return info.chapters.indexWhere((c) => c.slug == h.chapterSlug);
  }

  List<Chapter> get _chapters {
    final info = _info;
    if (info == null) return const [];
    final q = _chQuery.text.trim().toLowerCase();
    if (q.isEmpty) return info.chapters;
    return info.chapters
        .where((c) => c.label.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    final info = _info;
    final initial = widget.initial;
    final title = info?.title ?? initial?.title ?? '';

    return CupertinoPageScaffold(
      backgroundColor: ctx.bg,
      child: CustomScrollView(
        physics: iosPhysics,
        slivers: [
          CupertinoSliverNavigationBar(
            middle: SizedBox(
              width: 180,
              child: Text(
                title.isEmpty ? 'Detail' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ctx.text,
                ),
              ),
            ),
            trailing: info == null
                ? null
                : ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) => CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _toggleFav,
                      child: Icon(
                        _store.isFav(info.slug)
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        size: 20,
                        color: _store.isFav(info.slug)
                            ? AppColors.red
                            : ctx.text,
                      ),
                    ),
                  ),
          ),
          if (_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Shimmer(width: 108, height: 144, radius: 14),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer(height: 18, radius: 4),
                          SizedBox(height: 8),
                          Shimmer(height: 18, width: 140, radius: 4),
                          SizedBox(height: 10),
                          Shimmer(height: 12, width: 200, radius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (info == null)
            SliverFillRemaining(
              child: EmptyState(
                icon: CupertinoIcons.book,
                title: 'Detail tidak ditemukan',
                subtitle:
                    'Periksa koneksi internet lalu coba lagi.\n${errorDetail(_error)}',
                onRetry: _load,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 108,
                      height: 144,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: ctx.dark ? 0.4 : 0.15,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CoverImage(
                        urls: Parser.coverCandidates(info.cover),
                        placeholderTitle: info.title,
                        radius: 14,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: ctx.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (info.status.isNotEmpty)
                                MiniTag(label: info.status, color: ctx.muted),
                              if (info.rating.isNotEmpty)
                                MiniTag(label: info.rating, color: ctx.muted),
                              MiniTag(
                                label: '${info.chapters.length} chapter',
                                color: ctx.muted,
                              ),
                            ],
                          ),
                          if (info.genres.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final g in info.genres.take(4))
                                  MiniTag(label: g),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (info.synopsis.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sinopsis',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ctx.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        info.synopsis,
                        maxLines: _fullSyn ? null : 4,
                        overflow: _fullSyn ? null : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: ctx.text.withValues(
                            alpha: ctx.dark ? 0.8 : 0.75,
                          ),
                        ),
                      ),
                      if (info.synopsis.length > 220)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            _fullSyn ? 'Sembunyikan' : 'Lihat Selengkapnya',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ctx.accent,
                            ),
                          ),
                          onPressed: () => setState(() => _fullSyn = !_fullSyn),
                        ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  children: [
                    if (info.chapters.isNotEmpty) ...[
                      CupertinoButton.filled(
                        color: ctx.accent,
                        onPressed: () {
                          final ri = _resumeIndex;
                          _openReader(ri != null && ri >= 0 ? ri : 0);
                        },
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Text(
                          _resumeIndex != null && _resumeIndex! >= 0
                              ? 'Lanjutkan ${info.chapters[_resumeIndex!].label}'
                              : 'Baca Chapter Terbaru',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoButton.filled(
                        color: ctx.surface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Mulai dari Awal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ctx.accent,
                          ),
                        ),
                        onPressed: () => _openReader(info.chapters.length - 1),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (info.chapters.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Row(
                    children: [
                      Text(
                        'Daftar Chapter',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: ctx.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_chapters.length})',
                        style: TextStyle(fontSize: 14, color: ctx.muted),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CupertinoTextField(
                    controller: _chQuery,
                    placeholder: 'Cari chapter…',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 10, top: 10),
                      child: Icon(
                        CupertinoIcons.search,
                        size: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    suffix: _chQuery.text.isEmpty
                        ? null
                        : CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 15,
                              color: CupertinoColors.systemGrey,
                            ),
                            onPressed: () => _chQuery.clear(),
                          ),
                    decoration: BoxDecoration(
                      color: ctx.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ctx.separator.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ctx.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ctx.separator.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_chapters.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Chapter tidak ditemukan',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: ctx.muted),
                            ),
                          )
                        else
                          for (var i = 0; i < _chapters.length; i++) ...[
                            if (i > 0)
                              Container(
                                height: 0.6,
                                margin: const EdgeInsets.only(left: 14),
                                color: ctx.separator,
                              ),
                            GestureDetector(
                              onTap: () => _openReader(
                                info.chapters.indexOf(_chapters[i]),
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _chapters[i].label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: ctx.text,
                                            ),
                                          ),
                                          if (_chapters[i].date.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(
                                                _chapters[i].date,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: ctx.muted,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
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
              ),
            ],
          ],
        ],
      ),
    );
  }
}
