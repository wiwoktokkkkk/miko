import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

import '../api/client.dart';
import '../api/parser.dart';
import '../models.dart';
import '../navigation/app_route.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/cover_image.dart';
import 'reader_screen.dart';

/// Halaman detail series: info, sinopsis, daftar chapter.
///
/// Halaman ini sengaja tidak memakai sliver. Pada beberapa perangkat Android,
/// exception di dalam sliver sebelumnya diganti Flutter dengan RenderErrorBox,
/// lalu gagal lagi karena viewport mengharapkan RenderSliver. ListView biasa
/// menghindari jalur error tersebut dan tetap membangun chapter secara lazy.
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key, required this.slug, this.initial});

  final String slug;

  /// Card awal untuk menampilkan judul ketika detail masih dimuat.
  final ComicCard? initial;

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final KomikuClient _client = KomikuClient.instance;
  final AppStore _store = AppStore.instance;
  final TextEditingController _chQuery = TextEditingController();

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
    final info = _info;
    if (info == null || index < 0 || index >= info.chapters.length) return;
    Navigator.of(context).push(
      mikoRoute(
        builder: (_) => ReaderScreen(series: info, index: index),
      ),
    );
  }

  void _toggleFav() {
    final info = _info;
    if (info != null) _store.toggleFav(info);
  }

  int? get _resumeIndex {
    final info = _info;
    if (info == null) return null;
    final history = _store.historyFor(info.slug);
    if (history == null) return null;
    return info.chapters.indexWhere((c) => c.slug == history.chapterSlug);
  }

  List<Chapter> get _visibleChapters {
    final info = _info;
    if (info == null) return const [];
    final query = _chQuery.text.trim().toLowerCase();
    if (query.isEmpty) return info.chapters;
    return info.chapters
        .where((chapter) => chapter.label.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    final info = _info;
    final title = info?.title ?? widget.initial?.title ?? '';

    return CupertinoPageScaffold(
      backgroundColor: ctx.bg,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text(
          title.isEmpty ? 'Detail Komik' : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ctx.text,
          ),
        ),
        trailing: info == null
            ? null
            : ListenableBuilder(
                listenable: _store,
                builder: (context, _) => CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 40),
                  onPressed: _toggleFav,
                  child: Icon(
                    _store.isFav(info.slug)
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    size: 20,
                    color: _store.isFav(info.slug) ? AppColors.red : ctx.text,
                  ),
                ),
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: _loading
            ? _LoadingDetail(ctx: ctx)
            : info == null
            ? _DetailError(error: _error, onRetry: _load)
            : _buildDetail(ctx, info),
      ),
    );
  }

  Widget _buildDetail(Ctx ctx, SeriesInfo info) {
    final chapters = _visibleChapters;
    final hasChapter = info.chapters.isNotEmpty;

    return ListView.builder(
      physics: iosPhysics,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: 1 + (chapters.isEmpty ? 1 : chapters.length),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _DetailOverview(
            info: info,
            queryController: _chQuery,
            fullSynopsis: _fullSyn,
            visibleChapterCount: chapters.length,
            resumeIndex: _resumeIndex,
            onToggleSynopsis: () => setState(() => _fullSyn = !_fullSyn),
            onReadLatest: hasChapter
                ? () {
                    final resume = _resumeIndex;
                    _openReader(resume != null && resume >= 0 ? resume : 0);
                  }
                : null,
            onReadFirst: hasChapter
                ? () => _openReader(info.chapters.length - 1)
                : null,
          );
        }

        if (chapters.isEmpty) {
          return _NoChapterResult(hasQuery: _chQuery.text.trim().isNotEmpty);
        }

        final chapter = chapters[index - 1];
        return _ChapterRow(
          chapter: chapter,
          onTap: () => _openReader(info.chapters.indexOf(chapter)),
        );
      },
    );
  }
}

class _LoadingDetail extends StatelessWidget {
  const _LoadingDetail({required this.ctx});

  final Ctx ctx;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: iosPhysics,
      padding: const EdgeInsets.all(16),
      children: const [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Shimmer(height: 12, width: 180, radius: 4),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: iosPhysics,
      children: [
        const SizedBox(height: 80),
        EmptyState(
          icon: CupertinoIcons.book,
          title: 'Detail tidak ditemukan',
          subtitle:
              'Periksa koneksi internet lalu coba lagi.\n${errorDetail(error)}',
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class _DetailOverview extends StatelessWidget {
  const _DetailOverview({
    required this.info,
    required this.queryController,
    required this.fullSynopsis,
    required this.visibleChapterCount,
    required this.resumeIndex,
    required this.onToggleSynopsis,
    required this.onReadLatest,
    required this.onReadFirst,
  });

  final SeriesInfo info;
  final TextEditingController queryController;
  final bool fullSynopsis;
  final int visibleChapterCount;
  final int? resumeIndex;
  final VoidCallback onToggleSynopsis;
  final VoidCallback? onReadLatest;
  final VoidCallback? onReadFirst;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    final canResume =
        resumeIndex != null &&
        resumeIndex! >= 0 &&
        resumeIndex! < info.chapters.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                        for (final genre in info.genres.take(4))
                          MiniTag(label: genre),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (info.synopsis.isNotEmpty) ...[
          const SizedBox(height: 16),
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
            maxLines: fullSynopsis ? null : 4,
            overflow: fullSynopsis ? null : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: ctx.text.withValues(alpha: ctx.dark ? 0.8 : 0.75),
            ),
          ),
          if (info.synopsis.length > 220)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onToggleSynopsis,
              child: Text(
                fullSynopsis ? 'Sembunyikan' : 'Lihat Selengkapnya',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ctx.accent,
                ),
              ),
            ),
        ],
        if (onReadLatest != null) ...[
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              color: ctx.accent,
              padding: const EdgeInsets.symmetric(vertical: 13),
              onPressed: onReadLatest,
              child: Text(
                canResume
                    ? 'Lanjutkan ${info.chapters[resumeIndex!].label}'
                    : 'Baca Chapter Terbaru',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              color: ctx.surface,
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: onReadFirst,
              child: Text(
                'Mulai dari Awal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ctx.accent,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
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
              '($visibleChapterCount)',
              style: TextStyle(fontSize: 14, color: ctx.muted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CupertinoTextField(
          controller: queryController,
          placeholder: 'Cari chapter…',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(
              CupertinoIcons.search,
              size: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          suffix: queryController.text.isEmpty
              ? null
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 40),
                  onPressed: queryController.clear,
                  child: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 15,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
          decoration: BoxDecoration(
            color: ctx.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ctx.separator.withValues(alpha: 0.8)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _NoChapterResult extends StatelessWidget {
  const _NoChapterResult({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ctx.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ctx.separator.withValues(alpha: 0.8)),
      ),
      child: Text(
        hasQuery
            ? 'Chapter tidak cocok dengan pencarian'
            : 'Chapter tidak ditemukan',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: ctx.muted),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter, required this.onTap});

  final Chapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: ctx.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ctx.separator.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ctx.text,
                    ),
                  ),
                  if (chapter.date.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        chapter.date,
                        style: TextStyle(fontSize: 11, color: ctx.muted),
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
    );
  }
}
