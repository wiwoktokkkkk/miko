import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miko/src/models.dart';
import 'package:miko/src/screens/reader_screen.dart';

void main() {
  testWidgets('kontrol reader tetap di bawah dan tidak menutupi layar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final series = SeriesInfo(
      slug: 'manga/test',
      title: 'Komik Test',
      chapters: [Chapter('test-chapter-1', 'Chapter 1', '')],
    );

    await tester.pumpWidget(
      CupertinoApp(home: ReaderScreen(series: series, index: 0)),
    );
    await tester.pump();

    final previous = find.text('Sebelumnya');
    final next = find.text('Berikutnya');
    expect(previous, findsOneWidget);
    expect(next, findsOneWidget);

    // Regresi: sebelumnya tombol Expanded + Container(alignment) membesar
    // setinggi viewport sehingga label berada di tengah layar dan menutupi
    // gambar. Sekarang kedua label harus berada di bar bawah yang ringkas.
    expect(tester.getCenter(previous).dy, greaterThan(700));
    expect(tester.getCenter(next).dy, greaterThan(700));
    expect(
      (tester.getCenter(previous).dy - tester.getCenter(next).dy).abs(),
      lessThan(1),
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
