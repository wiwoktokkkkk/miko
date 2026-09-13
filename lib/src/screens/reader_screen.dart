import 'package:flutter/material.dart';

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/common.dart';

import '../api/client.dart';
import '../models.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';

/// Reader: gulir vertikal berkelanjutan, bar auto-hide, navigasi chapter.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.series, required this.index});

  final SeriesInfo series;
  final int index;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final KomikuClient _client = KomikuClient.instance;
  final ScrollController _scroll = ScrollController();

  late int _i;
  ChapterPages? _pages;
  Object? _error;
  bool _barsVisible = true;
  Timer? _hideTimer;
  double _progress = 0;
  bool _historySaved = false;

  @override
  void initState() {
    super.initState();
    _i = widget.index;
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Chapter get _chapter => widget.series.chapters[_i];
  int get _n => widget.series.chapters.length;

  /// Chapter yang lebih baru (indeks di daftar = lebih kecil).
  bool get _hasPrev => _i > 0;

  /// Chapter berikutnya dalam urutan baca (lebih lama).
  bool get _hasNext => _i < _n - 1;

  Future<void> _load() async {
    _hideTimer?.cancel();
    setState(() {
      _pages = null;
      _error = null;
      _historySaved = false;
      _progress = 0;
    });
    try {
      final pages = await _client.chapterPages(_chapter.slug);
      if (!mounted) return;
      if (pages.pages.isEmpty) {
        setState(() => _error = const KomikuException("Halaman kosong"));
        return;
      }
      setState(() {
        _pages = pages;
        _barsVisible = true;
      });
      _scheduleHide();
      if (!_historySaved) {
        _historySaved = true;
        unawaited(
          AppStore.instance.addHistory(
            HistoryItem(
              seriesSlug: widget.series.slug,
              seriesTitle: widget.series.title,
              cover: widget.series.cover,
              chapterSlug: _chapter.slug,
              chapterLabel: _chapter.label,
              ts: DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _barsVisible) {
        setState(() => _barsVisible = false);
      }
    });
  }

  void _toggleBars() {
    setState(() => _barsVisible = !_barsVisible);
    if (_barsVisible) _scheduleHide();
  }

  void _onScroll() {
    if (_scroll.hasClients) {
      final pos = _scroll.position;
      final max = pos.maxScrollExtent;
      final value = max > 0 ? (pos.pixels / max).clamp(0.0, 1.0) : 0.0;
      if ((value - _progress).abs() > 0.002) {
        setState(() => _progress = value);
      }
    }
    _scheduleHide();
  }

  void _openChapter(int i) {
    if (i < 0 || i >= _n || i == _i) return;
    setState(() => _i = i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
    _load();
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: pages == null
                ? _chapterState()
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleBars,
                    child: _buildList(pages),
                  ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _barsVisible ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: _barsVisible ? Offset.zero : const Offset(0, -1.4),
                child: _topBar(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _barsVisible ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: _barsVisible ? Offset.zero : const Offset(0, 1.4),
                child: _bottomBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chapterState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _error == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(radius: 18),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat halaman…',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 30,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Gagal memuat chapter',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Periksa koneksi internet lalu coba lagi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 18),
                  CupertinoButton.filled(
                    onPressed: _load,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildList(ChapterPages pages) {
    final prevOffset = _hasPrev ? 1 : 0;
    final total = pages.pages.length + prevOffset + (_hasNext ? 1 : 0);
    return ListView.builder(
      controller: _scroll,
      physics: iosPhysics,
      padding: const EdgeInsets.symmetric(vertical: 3),
      itemCount: total,
      itemBuilder: (context, i) {
        if (_hasPrev && i == 0) {
          return _chapterTile(
            label: 'Kembali ke ${widget.series.chapters[_i - 1].label}',
            accent: false,
            onTap: () => _openChapter(_i - 1),
          );
        }
        final pi = i - prevOffset;
        if (pi >= pages.pages.length) {
          return _chapterTile(
            label: 'Lanjut ke ${widget.series.chapters[_i + 1].label}',
            accent: true,
            onTap: () => _openChapter(_i + 1),
          );
        }
        return _PageImage(url: pages.pages[pi]);
      },
    );
  }

  Widget _chapterTile({
    required String label,
    required bool accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: accent
                  ? AppColors.accentDark
                  : Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xEE000000)),
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.series.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_chapter.label}  ·  ${_n - _i} dari $_n',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 2.5,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: const AlwaysStoppedAnimation(AppColors.accentDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xEE000000)),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          _navButton(
            'Sebelumnya',
            icon: CupertinoIcons.chevron_left,
            iconFirst: true,
            enabled: _hasPrev,
            onTap: () => _openChapter(_i - 1),
          ),
          const SizedBox(width: 12),
          _navButton(
            'Berikutnya',
            icon: CupertinoIcons.chevron_right,
            enabled: _hasNext,
            onTap: () => _openChapter(_i + 1),
          ),
        ],
      ),
    );
  }

  Widget _navButton(
    String label, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool iconFirst = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.35,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconFirst) ...[
                  Icon(icon, size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (!iconFirst) ...[
                  const SizedBox(width: 6),
                  Icon(icon, size: 13, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gambar satu halaman komik.
class _PageImage extends StatefulWidget {
  const _PageImage({required this.url});

  final String url;

  @override
  State<_PageImage> createState() => _PageImageState();
}

class _PageImageState extends State<_PageImage> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      child: _failed
          ? _ErrorTile(onRetry: () => setState(() => _failed = false))
          : CachedNetworkImage(
              key: ValueKey(widget.url),
              imageUrl: widget.url,
              httpHeaders: KomikuClient.httpHeaders,
              fit: BoxFit.fitWidth,
              width: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.black,
                height: 420,
                alignment: Alignment.center,
                child: const CupertinoActivityIndicator(),
              ),
              errorWidget: (context, url, err) {
                Future.microtask(() {
                  if (mounted && !_failed) setState(() => _failed = true);
                });
                return _ErrorTile(
                  onRetry: () => setState(() => _failed = false),
                );
              },
            ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      color: const Color(0xFF101014),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.wifi_slash,
            size: 26,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            'Gagal memuat halaman',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          CupertinoButton(
            color: Colors.white.withValues(alpha: 0.14),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            onPressed: onRetry,
            child: const Text(
              'Muat Ulang',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
