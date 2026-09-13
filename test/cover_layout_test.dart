import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miko/src/models.dart';
import 'package:miko/src/widgets/cards.dart';
import 'package:miko/src/widgets/cover_image.dart';

void main() {
  testWidgets('thumbnail lanskap tidak di-crop atau di-zoom', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: SizedBox(
          width: 120,
          height: 160,
          child: SeriesCoverImage(
            slug: 'manga/test',
            urls: ['https://thumbnail.komiku.org/cover.jpg?resize=240,150'],
          ),
        ),
      ),
    );
    await tester.pump();

    final cover = tester.widget<CoverImage>(find.byType(CoverImage));
    expect(cover.fit, BoxFit.contain);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('card Jelajah memakai slot poster portrait', (tester) async {
    final card = BrowseCard(
      slug: 'manga/test',
      title: 'Komik Test',
      type: 'Manga',
      genre: 'Aksi',
      meta: 'Aksi | baru',
      cover: 'https://thumbnail.komiku.org/cover.jpg?resize=450,235',
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: SizedBox(
          width: 400,
          child: BrowseRow(card: card, onTap: () {}),
        ),
      ),
    );
    await tester.pump();

    final poster = find.byType(SeriesCoverImage);
    expect(poster, findsOneWidget);
    expect(tester.getSize(poster), const Size(82, 110));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
