import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

import '../api/parser.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'cover_image.dart';

/// Card vertikal (grid) untuk beranda & ranking.
class GridComicCard extends StatelessWidget {
  const GridComicCard({
    super.key,
    required this.card,
    required this.onTap,
    this.width,
  });

  final ComicCard card;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: ctx.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: ctx.dark ? 0.35 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CoverImage(
                      urls: Parser.coverCandidates(card.cover),
                      placeholderTitle: card.title,
                      radius: 0,
                    ),
                  ),
                  if (card.rank != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: RankBadge(value: card.rank!),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
              child: SizedBox(
                height: 62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.22,
                          color: ctx.text,
                        ),
                      ),
                    ),
                    if (card.meta.isNotEmpty)
                      Text(
                        card.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: ctx.muted),
                      ),
                    if (card.lastChapterLabel.isNotEmpty)
                      Text(
                        card.lastChapterLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ctx.accent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card horizontal untuk seksi scroll beranda.
class HComicCard extends StatelessWidget {
  const HComicCard({
    super.key,
    required this.card,
    required this.onTap,
    this.width = 132,
  });

  final ComicCard card;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: SeriesCoverImage(
                    slug: card.slug,
                    urls: Parser.coverCandidates(card.cover),
                    placeholderTitle: card.title,
                    radius: 12,
                  ),
                ),
                if (card.rank != null)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: RankBadge(value: card.rank!),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 66,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.22,
                        color: ctx.text,
                      ),
                    ),
                  ),
                  if (card.meta.isNotEmpty)
                    Text(
                      card.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: ctx.muted),
                    ),
                  if (card.lastChapterLabel.isNotEmpty)
                    Text(
                      card.lastChapterLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ctx.accent,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris card horizontal untuk katalog Jelajah (cover lanskap).
class BrowseRow extends StatelessWidget {
  const BrowseRow({super.key, required this.card, required this.onTap});

  final BrowseCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ctx.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ctx.separator.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 82,
              height: 110,
              child: SeriesCoverImage(
                slug: card.slug,
                urls: Parser.coverCandidates(card.cover),
                placeholderTitle: card.title,
                radius: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: ctx.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.meta.isEmpty ? card.genre : card.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: ctx.muted),
                  ),
                  if (card.synopsis.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      card.synopsis,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: ctx.muted.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (card.type.isNotEmpty) ...[
                        MiniTag(label: card.type),
                        if (card.up.isNotEmpty) const SizedBox(width: 6),
                      ],
                      if (card.up.isNotEmpty)
                        MiniTag(
                          label: card.up,
                          color: ctx.dark
                              ? AppColors.green
                              : const Color(0xFF248A3D),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris riwayat baca.
class HistoryRow extends StatelessWidget {
  const HistoryRow({
    super.key,
    required this.item,
    required this.onTap,
    this.onRemove,
  });

  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 58,
            child: CoverImage(
              urls: Parser.coverCandidates(item.cover),
              placeholderTitle: item.seriesTitle,
              radius: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.seriesTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ctx.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.chapterLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ctx.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relativeTime(item.ts),
                  style: TextStyle(fontSize: 11, color: ctx.muted),
                ),
              ],
            ),
          ),
        ),
        if (onRemove != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            color: Colors.transparent,
            onPressed: onRemove,
            child: Icon(
              CupertinoIcons.trash,
              size: 15,
              color: ctx.muted.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }
}

/// Umpak hasil pencarian (tanpa cover — placeholder gradien).
class SearchTile extends StatelessWidget {
  const SearchTile({super.key, required this.result, required this.onTap});

  final SearchResult result;
  final VoidCallback onTap;

  static const List<List<Color>> _palettes = [
    [Color(0xFF3A5B8C), Color(0xFF1F3A63)],
    [Color(0xFF5B4B8C), Color(0xFF3A2E63)],
    [Color(0xFF8C5B3A), Color(0xFF63401F)],
    [Color(0xFF3A8C6A), Color(0xFF1F6349)],
    [Color(0xFF8C3A5E), Color(0xFF631F3C)],
    [Color(0xFF3A8C8C), Color(0xFF1F6363)],
  ];

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    final h =
        result.title.codeUnits.fold<int>(7, (a, b) => a + b * 31) %
        _palettes.length;
    final pal = _palettes[h];
    final initial = initialOf(result.title);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [pal[0], pal[1]],
                ),
              ),
              alignment: Alignment.center,
              child: initial.isEmpty
                  ? const Icon(CupertinoIcons.book, color: Colors.white70)
                  : Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: ctx.text,
            ),
          ),
        ],
      ),
    );
  }
}
