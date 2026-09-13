import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../api/client.dart';
import '../api/parser.dart';
import '../theme/app_theme.dart';

/// Gambar jaringan dengan header CDN dan rantai fallback host.
///
/// `urls` berisi kandidat URL mulai dari yang paling diutamakan. Bila satu
/// kandidat gagal, kandidat berikutnya dicoba secara otomatis.
class CoverImage extends StatefulWidget {
  const CoverImage({
    super.key,
    required this.urls,
    this.placeholderTitle,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  final List<String> urls;
  final String? placeholderTitle;
  final double radius;
  final BoxFit fit;

  @override
  State<CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<CoverImage> {
  int _index = 0;
  bool _failed = false;
  bool _changeScheduled = false;

  @override
  void didUpdateWidget(covariant CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.urls, widget.urls)) {
      _index = 0;
      _failed = false;
      _changeScheduled = false;
    }
  }

  void _handleError() {
    if (_changeScheduled) return;
    _changeScheduled = true;
    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        if (_index + 1 < widget.urls.length) {
          _index++;
        } else {
          _failed = true;
        }
        _changeScheduled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    if (widget.urls.isEmpty || _failed) {
      return _PlaceholderCover(
        ctx: ctx,
        title: widget.placeholderTitle,
        radius: widget.radius,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: ColoredBox(
        color: ctx.separator.withValues(alpha: 0.28),
        child: CachedNetworkImage(
          imageUrl: widget.urls[_index],
          httpHeaders: KomikuClient.httpHeaders,
          width: double.infinity,
          height: double.infinity,
          fit: widget.fit,
          fadeInDuration: const Duration(milliseconds: 180),
          placeholder: (context, url) => _LoadingTile(ctx: ctx),
          errorWidget: (context, url, err) {
            _handleError();
            return _LoadingTile(ctx: ctx);
          },
        ),
      ),
    );
  }
}

/// Cover series yang mengoreksi thumbnail daftar Komiku.
///
/// Endpoint Beranda/Jelajah/Search menyediakan thumbnail lanskap. Memaksanya
/// ke rasio poster dengan BoxFit.cover membuat wajah/gambar sangat zoom. Saat
/// thumbnail lanskap terdeteksi, widget mengambil cover portrait dari detail
/// series (request ikut cache dan digabung bila slug yang sama diminta).
class SeriesCoverImage extends StatefulWidget {
  const SeriesCoverImage({
    super.key,
    required this.slug,
    required this.urls,
    this.placeholderTitle,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  final String slug;
  final List<String> urls;
  final String? placeholderTitle;
  final double radius;
  final BoxFit fit;

  @override
  State<SeriesCoverImage> createState() => _SeriesCoverImageState();
}

class _SeriesCoverImageState extends State<SeriesCoverImage> {
  String? _portraitUrl;
  int _generation = 0;

  String? get _fallback => widget.urls.isEmpty ? null : widget.urls.first;
  bool get _needsPortrait => Parser.isLandscapeCover(_fallback);

  @override
  void initState() {
    super.initState();
    _resolvePortrait();
  }

  @override
  void didUpdateWidget(covariant SeriesCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug ||
        !listEquals(oldWidget.urls, widget.urls)) {
      _portraitUrl = null;
      _resolvePortrait();
    }
  }

  Future<void> _resolvePortrait() async {
    final generation = ++_generation;
    if (!_needsPortrait || widget.slug.isEmpty) return;
    try {
      final info = await KomikuClient.instance.series(widget.slug);
      if (!mounted || generation != _generation || info.cover.isEmpty) return;
      setState(() => _portraitUrl = info.cover);
    } catch (_) {
      // Thumbnail lanskap tetap ditampilkan utuh (contain), bukan di-zoom.
    }
  }

  @override
  Widget build(BuildContext context) {
    final portrait = _portraitUrl;
    final urls = portrait == null
        ? widget.urls
        : Parser.coverCandidates(portrait);
    return CoverImage(
      urls: urls,
      placeholderTitle: widget.placeholderTitle,
      radius: widget.radius,
      // Selama cover portrait belum tersedia, tampilkan thumbnail lanskap
      // secara utuh agar tidak ada crop/zoom yang menyesatkan.
      fit: portrait == null && _needsPortrait ? BoxFit.contain : widget.fit,
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile({required this.ctx});
  final Ctx ctx;

  @override
  Widget build(BuildContext context) => Container(
    color: ctx.separator.withValues(alpha: 0.35),
    alignment: Alignment.center,
    child: const CupertinoActivityIndicator(radius: 12),
  );
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({
    required this.ctx,
    required this.title,
    required this.radius,
  });

  final Ctx ctx;
  final String? title;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmed = (title ?? '').trim();
    final initial = trimmed.isEmpty
        ? null
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: ctx.separator.withValues(alpha: 0.35),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: initial == null
            ? Icon(
                CupertinoIcons.book,
                size: 26,
                color: ctx.muted.withValues(alpha: 0.65),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.book,
                    size: 20,
                    color: ctx.muted.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    initial,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: ctx.muted.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
