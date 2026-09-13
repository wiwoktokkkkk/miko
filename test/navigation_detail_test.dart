import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miko/src/app.dart';
import 'package:miko/src/models.dart';
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
        CupertinoPageRoute(
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
}
