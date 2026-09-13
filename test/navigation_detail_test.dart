import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miko/src/api/client.dart';
import 'package:miko/src/app.dart';
import 'package:miko/src/models.dart';
import 'package:miko/src/navigation/app_route.dart';
import 'package:miko/src/screens/series_screen.dart';

void main() {
  testWidgets(
    'detail dapat dibuka dari shell tanpa konflik Hero navigation bar',
    (tester) async {
      await tester.pumpWidget(const MikoApp());
      await tester.pump();

      final rootBars = tester
          .widgetList<CupertinoSliverNavigationBar>(
            find.byType(CupertinoSliverNavigationBar, skipOffstage: false),
          )
          .toList();
      expect(rootBars, hasLength(5));
      expect(rootBars.every((bar) => !bar.transitionBetweenRoutes), isTrue);

      final shellContext = tester.element(find.byType(IndexedStack));
      Navigator.of(shellContext).push<void>(
        mikoRoute(
          builder: (_) => SeriesScreen(
            slug: 'manga/detail-test',
            initial: ComicCard(slug: 'manga/detail-test', title: 'Detail Test'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('Detail Test'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('tap card membuka detail lengkap dengan banyak chapter', (
    tester,
  ) async {
    final client = KomikuClient.instance;
    final card = ComicCard(
      slug: 'manga/detail-tap-test',
      title: 'Komik Tap Test',
      cover: 'https://thumbnail.komiku.org/poster.jpg?w=500',
    );
    final chapters = List.generate(
      300,
      (i) => Chapter(
        'detail-tap-test-chapter-${300 - i}',
        'Chapter ${300 - i}',
        '13 September 2026',
      ),
    );
    final info = SeriesInfo(
      slug: card.slug,
      title: card.title,
      cover: card.cover!,
      status: 'Ongoing',
      rating: '8.9',
      synopsis: List.filled(30, 'Sinopsis panjang untuk pengujian.').join(' '),
      genres: const ['Action', 'Comedy', 'Drama', 'School'],
      chapters: chapters,
    );

    await client.cached<HomeData>(
      'home',
      () async => HomeData(rankHarian: [card]),
      ttl: Duration.zero,
    );
    await client.cached<SeriesInfo>(
      'series:${card.slug}',
      () async => info,
      ttl: Duration.zero,
    );

    await tester.pumpWidget(const MikoApp());
    await tester.pump();
    await tester.pump();

    expect(find.text(card.title), findsOneWidget);
    await tester.tap(find.text(card.title));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SeriesScreen), findsOneWidget);
    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    expect(find.byType(CupertinoSliverNavigationBar), findsNothing);
    final route =
        ModalRoute.of(tester.element(find.byType(SeriesScreen)))!
            as PageRoute<dynamic>;
    expect(route.allowSnapshotting, isFalse);
    expect(route, isNot(isA<CupertinoPageRoute<dynamic>>()));
    expect(route.transitionDuration, Duration.zero);
    expect(find.text('Daftar Chapter'), findsOneWidget);
    expect(find.text('(300)'), findsOneWidget);
    expect(find.text('Chapter 300'), findsOneWidget);
    expect(find.text('Chapter 1'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tap komik dari Jelajah membuka detail, bukan layar kosong', (
    tester,
  ) async {
    final client = KomikuClient.instance;
    final browseCard = BrowseCard(
      slug: 'manga/jelajah-tap-test',
      title: 'Komik Jelajah Test',
      type: 'Manga',
      genre: 'Action',
      meta: 'Update baru saja',
      cover: 'https://thumbnail.komiku.org/poster-jelajah.jpg?w=500',
    );
    final info = SeriesInfo(
      slug: browseCard.slug,
      title: browseCard.title,
      cover: browseCard.cover!,
      status: 'Ongoing',
      chapters: [
        Chapter('jelajah-tap-test-chapter-1', 'Chapter 1', 'Hari ini'),
      ],
    );

    await client.cached<BrowsePage>(
      'browse::::modified:1',
      () async => BrowsePage(cards: [browseCard], hasNext: false),
      ttl: Duration.zero,
    );
    await client.cached<SeriesInfo>(
      'series:${browseCard.slug}',
      () async => info,
      ttl: Duration.zero,
    );

    await tester.pumpWidget(const MikoApp());
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Jelajah'));
    await tester.pump();

    expect(find.text(browseCard.title), findsOneWidget);
    await tester.tap(find.text(browseCard.title));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SeriesScreen), findsOneWidget);
    expect(find.text('Baca Chapter Terbaru'), findsOneWidget);
    expect(find.text('Chapter 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
