import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

import '../api/client.dart';
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
      child: CachedNetworkImage(
        imageUrl: widget.urls[_index],
        httpHeaders: KomikuClient.httpHeaders,
        fit: widget.fit,
        placeholder: (context, url) => _LoadingTile(ctx: ctx),
        errorWidget: (context, url, err) {
          if (_index + 1 < widget.urls.length) {
            final next = _index + 1;
            Future.microtask(() {
              if (mounted) setState(() => _index = next);
            });
            return _LoadingTile(ctx: ctx);
          }
          if (!_failed) {
            _failed = true;
            Future.microtask(() {
              if (mounted) setState(() {});
            });
            return _LoadingTile(ctx: ctx);
          }
          return _PlaceholderCover(
            ctx: ctx,
            title: widget.placeholderTitle,
            radius: widget.radius,
          );
        },
      ),
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
    child: CupertinoActivityIndicator(radius: 12),
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
