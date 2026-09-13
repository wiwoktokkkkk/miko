import 'package:flutter/cupertino.dart';

import '../api/client.dart';
import '../api/parser.dart';
import '../models.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/cover_image.dart';
import 'reader_screen.dart';
import 'series_screen.dart';

/// Tab Favorit: riwayat baca (lanjut baca) + komik tersimpan.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final ctx = Ctx(context);
    return CupertinoPageScaffold(
      backgroundColor: ctx.bg,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final history = store.history;
          final favs = store.favorites;
          return CustomScrollView(
            physics: iosPhysics,
            slivers: [
              const CupertinoSliverNavigationBar(largeTitle: Text('Favorit')),
              if (history.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Lanjut Baca',
                    icon: CupertinoIcons.clock,
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
                        for (var i = 0; i < history.length; i++) ...[
                          if (i > 0)
                            Container(
                              height: 0.6,
                              margin: const EdgeInsets.only(left: 16),
                              color: ctx.separator,
                            ),
                          HistoryRow(
                            item: history[i],
                            onTap: () => _continueReading(context, history[i]),
                            onRemove: () =>
                                store.removeHistory(history[i].seriesSlug),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Komik Tersimpan',
                  icon: CupertinoIcons.heart,
                ),
              ),
              if (favs.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: CupertinoIcons.heart,
                    title: 'Belum ada komik tersimpan',
                    subtitle:
                        'Buka detail komik lalu tekan ikon hati untuk menyimpannya ke sini.',
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                      childAspectRatio: _favAspect(context),
                    ),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final entry = favs[i];
                      return _FavTile(
                        entry: entry,
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => SeriesScreen(slug: entry.slug),
                          ),
                        ),
                      );
                    }, childCount: favs.length),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  double _favAspect(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 32 - 20) / 3;
    final h = w * 4 / 3 + 24;
    return w / h;
  }

  Future<void> _continueReading(BuildContext context, HistoryItem item) async {
    try {
      final series = await KomikuClient.instance.series(item.seriesSlug);
      if (!context.mounted) return;
      var idx = series.chapters.indexWhere((c) => c.slug == item.chapterSlug);
      if (idx < 0) idx = 0;
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => ReaderScreen(series: series, index: idx),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Gagal membuka'),
          content: Text('Periksa koneksi internet lalu coba lagi.\n$e'),
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
}

class _FavTile extends StatelessWidget {
  const _FavTile({required this.entry, required this.onTap});

  final FavEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: CoverImage(
                urls: Parser.coverCandidates(entry.cover),
                placeholderTitle: entry.title,
                radius: 12,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ctx.text,
            ),
          ),
        ],
      ),
    );
  }
}
