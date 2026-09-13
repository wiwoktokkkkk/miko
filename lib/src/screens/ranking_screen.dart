import 'package:flutter/cupertino.dart';

import '../api/client.dart';
import '../models.dart';
import '../navigation/app_route.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'series_screen.dart';

/// Tab Populer: peringkat lengkap dari komiku.org.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final KomikuClient _client = KomikuClient.instance;

  List<ComicCard>? _cards;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await _client.ranking();
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _openSeries(ComicCard c) {
    Navigator.of(context).push(
      mikoRoute(
        builder: (_) => SeriesScreen(slug: c.slug, initial: c),
      ),
    );
  }

  /// Rasio aspek sel grid agar card muat pas (cover 3:4 + blok teks 82px).
  double _aspect(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 32 - 20) / 3;
    final h = w * 4 / 3 + 82;
    return w / h;
  }

  @override
  Widget build(BuildContext context) {
    final ctx = Ctx(context);
    return CustomScrollView(
      physics: iosPhysics,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _load),
        const CupertinoSliverNavigationBar(
          transitionBetweenRoutes: false,
          largeTitle: Text('Populer'),
        ),
        if (_loading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
                childAspectRatio: _aspect(context),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(9, (_) => const Shimmer(radius: 14)),
              ),
            ),
          )
        else if (_cards == null || _cards!.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              icon: CupertinoIcons.chart_bar_fill,
              title: 'Peringkat tidak tersedia',
              subtitle: _error == null
                  ? 'Coba muat ulang.'
                  : 'Periksa koneksi internet lalu coba lagi.\n${errorDetail(_error)}',
              onRetry: _load,
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                '${_cards!.length} judul teratas',
                style: TextStyle(fontSize: 12, color: ctx.muted),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
                childAspectRatio: _aspect(context),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => GridComicCard(
                  card: _cards![i],
                  onTap: () => _openSeries(_cards![i]),
                ),
                childCount: _cards!.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
