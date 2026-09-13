import 'package:flutter_test/flutter_test.dart';
import 'package:miko/src/api/parser.dart';

void main() {
  group('Parser.parseLs4', () {
    const html = '''
<section id="Rekomendasi_Komik">
<div class="ls4w rank-panel" id="rank-harian">
<article class="ls4">
<div class="ls4v">
<a href="/manga/from-goblin-to-goblin-god/">
<img class="lazy" src="/asset/img/lazy.jpg" data-src="https://thumbnail.komiku.to/uploads/manga/from-goblin-to-goblin-god/manga_thumbnail-A2-From-Goblin-to-Goblin-God.jpg?resize=240,280" alt="Baca  From Goblin to Goblin God">
</a>
<span class="rank-num">1</span>
</div>
<div class="ls4j">
<h4><a href="/manga/from-goblin-to-goblin-god/" title="Baca Komik From Goblin to Goblin God">From Goblin to Goblin God</a></h4>
<span class="ls4s">Fantasi &#183; 39,192 views</span><br>
<a href="/from-goblin-to-goblin-god-chapter-123/" class="ls24" title="Komik From Goblin to Goblin God Chapter 123">Chapter 123</a>
</div>
</article>
<article class="ls4">
<div class="ls4v">
<a href="/manhwa/max-level-player/">
<img class="lazy" src="https://komiku.org/asset/img/lazy.jpg?resize=120,75" data-src="https://thumbnail.komiku.to/img/upload/max-level-player/img_x.jpg?resize=240,280" alt="Baca Max Level Player">
</a>
<span class="rank-num">2</span>
</div>
<div class="ls4j">
<h4><a href="/manhwa/max-level-player/">Max Level Player</a></h4>
<span class="ls4s">Romantis &#183; 1,234 views</span><br>
<a href="/max-level-player-chapter-210/">Chapter 210</a>
</div>
</article>
</div>
</section>
''';

    test('memutar slug, rank, cover, judul, meta, chapter terakhir', () {
      final cards = Parser.parseLs4(html);
      expect(cards.length, 2);

      final a = cards[0];
      expect(a.slug, 'manga/from-goblin-to-goblin-god');
      expect(a.kind, 'manga');
      expect(a.shortSlug, 'from-goblin-to-goblin-god');
      expect(a.rank, 1);
      expect(a.title, 'From Goblin to Goblin God');
      expect(a.meta, 'Fantasi \u00b7 39,192 views');
      expect(a.lastChapterLabel, 'Chapter 123');
      expect(a.lastChapterSlug, 'from-goblin-to-goblin-god-chapter-123');

      final b = cards[1];
      expect(b.slug, 'manhwa/max-level-player');
      expect(b.rank, 2);
      expect(b.title, 'Max Level Player');
      expect(b.lastChapterSlug, 'max-level-player-chapter-210');
    });

    test('cover dinormalisasi ke host .org', () {
      final cards = Parser.parseLs4(html);
      expect(cards[0].cover, isNotNull);
      expect(cards[0].cover, contains('thumbnail.komiku.org'));
      expect(cards[0].cover, isNot(contains('thumbnail.komiku.to')));
    });
  });

  group('Parser.coverCandidates', () {
    test('memberikan fallback host .to bila sumber .org', () {
      final c = Parser.coverCandidates(
        'https://thumbnail.komiku.org/uploads/manga/x/c.jpg',
      );
      expect(c, [
        'https://thumbnail.komiku.org/uploads/manga/x/c.jpg',
        'https://thumbnail.komiku.to/uploads/manga/x/c.jpg',
      ]);
    });

    test('kosong untuk null', () {
      expect(Parser.coverCandidates(null), isEmpty);
    });
  });

  group('Parser.isLandscapeCover', () {
    test('mendeteksi resize lanskap dan nama horizontal', () {
      expect(
        Parser.isLandscapeCover(
          'https://thumbnail.komiku.org/cover.jpg?resize=450,235',
        ),
        isTrue,
      );
      expect(
        Parser.isLandscapeCover(
          'https://thumbnail.komiku.org/manga_img_horizontal-X.png',
        ),
        isTrue,
      );
    });

    test('tidak menandai thumbnail portrait', () {
      expect(
        Parser.isLandscapeCover(
          'https://thumbnail.komiku.org/cover.jpg?resize=240,280',
        ),
        isFalse,
      );
      expect(
        Parser.isLandscapeCover('https://thumbnail.komiku.org/cover.jpg?w=500'),
        isFalse,
      );
    });
  });

  group('Parser.chapterImageCandidates', () {
    test('menambahkan fallback img.komiku.org untuk CDN bernomor', () {
      final candidates = Parser.chapterImageCandidates(
        'https://image7.komiku.to/upload5/komik/12/halaman.webp',
      );
      expect(candidates, [
        'https://image7.komiku.to/upload5/komik/12/halaman.webp',
        'https://img.komiku.org/upload5/komik/12/halaman.webp',
      ]);
    });

    test('tidak menduplikasi host img.komiku.org', () {
      const url = 'https://img.komiku.org/upload5/komik/12/halaman.webp';
      expect(Parser.chapterImageCandidates(url), [url]);
    });
  });

  group('Parser.parseBrowse', () {
    const html = '''
<div class="bge">
  <div class="bgei">
    <a href="https://komiku.org/manga/the-villainous-dukes-daughter-hides-her-identity/">
      <img src="https://thumbnail.komiku.org/new/img/images/2026/09/12/abc.jpg?resize=450,235" class="sd rd">
      <div class="tpe1_inf">
        <b>Manhwa</b> Romantis
      </div>
      <span class="up">Up 3</span>
    </a>
  </div>
  <div class="kan">
    <a href="https://komiku.org/manga/the-villainous-dukes-daughter-hides-her-identity/"><h3>
      The Villainous Duke&#8217;s Daughter Hides Her Identity
    </h3></a>
    <span class="judul2"> Romantis | 24 menit lalu  | Berwarna</span>
    <p>
    Ia mencoba menghindari takdir buruk dengan menjalani kehidupan yang sederhana.
    </p>
  <div class="new1">
    <a href="/the-villainous-dukes-daughter-hides-her-identity-chapter-1/" title="t"><span>Awal: </span><span>Chapter 1</span></a>
  </div>
  <div class="new1">
    <a href="/the-villainous-dukes-daughter-hides-her-identity-chapter-6/" title="t"><span>Terbaru: </span><span>Chapter 6</span></a>
  </div>
  </div>
</div>
<p class="hxloading animate-spin" id="hxloading"></p>
<span hx-get="https://api.komiku.org/manga/page/2/?tipe=manhwa" hx-trigger="revealed"></span>
''';

    test('memutar card katalog lengkap', () {
      final page = Parser.parseBrowse(html);
      expect(page.cards.length, 1);
      expect(page.hasNext, isTrue);

      final c = page.cards.first;
      expect(c.slug, 'manga/the-villainous-dukes-daughter-hides-her-identity');
      expect(c.type, 'Manhwa');
      expect(c.genre, 'Romantis');
      expect(c.up, 'Up 3');
      expect(c.title, "The Villainous Duke's Daughter Hides Her Identity");
      expect(c.meta, 'Romantis | 24 menit lalu | Berwarna');
      expect(c.synopsis, contains('menghindari takdir buruk'));
      expect(
        c.firstChapterSlug,
        'the-villainous-dukes-daughter-hides-her-identity-chapter-1',
      );
      expect(
        c.lastChapterSlug,
        'the-villainous-dukes-daughter-hides-her-identity-chapter-6',
      );
    });

    test('halaman terakhir: hasNext false bila tidak ada span page', () {
      final noNext = html.replaceAll('<span hx-get=', '<span hx-ignore=');
      expect(Parser.parseBrowse(noNext).hasNext, isFalse);
    });
  });

  group('Parser.parseBrowse untuk pencarian', () {
    test('menerima href series relatif dari endpoint pencarian', () {
      const html = '''
<div class="bge">
  <div class="bgei">
    <a href="/manga/sakamoto-days/">
      <img src="https://thumbnail.komiku.org/uploads/manga/sakamoto-days/cover.jpg" class="lazy sd rd">
      <div class="tpe1_inf"><b>Manga</b> Komedi</div>
    </a>
  </div>
  <div class="kan">
    <a href="/manga/sakamoto-days/"><h3>Sakamoto Days</h3></a>
    <p>Update 11 jam lalu.</p>
    <div class="new1">
      <a href="/sakamoto-days-chapter-01/">
        <span>Awal: </span><span>Chapter 01</span>
      </a>
    </div>
    <div class="new1">
      <a href="/sakamoto-days-chapter-274/">
        <span>Terbaru: </span><span>Chapter 274</span>
      </a>
    </div>
  </div>
</div>
''';
      final cards = Parser.parseBrowse(html).cards;
      expect(cards, hasLength(1));
      expect(cards.single.slug, 'manga/sakamoto-days');
      expect(cards.single.title, 'Sakamoto Days');
      expect(cards.single.type, 'Manga');
      expect(cards.single.genre, 'Komedi');
      expect(cards.single.firstChapterSlug, 'sakamoto-days-chapter-01');
      expect(cards.single.lastChapterSlug, 'sakamoto-days-chapter-274');
    });
  });

  group('Parser.parseChapter', () {
    const html = '''
<title>From Goblin to Goblin God Chapter 123 - Komiku</title>
<img src="https://image2.komiku.to/komiku-promosi.webp">
<img src="https://image2.komiku.to/upload5/from-goblin-to-goblin-god/123/2026-09-04/1.webp">
<img src="https://image2.komiku.to/upload5/from-goblin-to-goblin-god/123/2026-09-04/2_part1.webp">
<img src="https://image3.komiku.to/upload5/from-goblin-to-goblin-god/123/2026-09-04/2_part2.webp">
<img src="https://image3.komiku.to/upload5/from-goblin-to-goblin-god/123/2026-09-04/2_part1.webp">
<img src="https://img.komiku.org/upload5/from-goblin-to-goblin-god/123/2026-09-04/3.webp">
''';

    test('memfilter promo & duplikat, menjaga urutan', () {
      final p = Parser.parseChapter(
        'from-goblin-to-goblin-god-chapter-123',
        html,
      );
      // Lima URL unik, termasuk host pusat img.komiku.org.
      expect(p.pages.length, 5);
      expect(
        p.pages.first,
        'https://image2.komiku.to/upload5/from-goblin-to-goblin-god/123/2026-09-04/1.webp',
      );
      expect(
        p.pages.last,
        'https://img.komiku.org/upload5/from-goblin-to-goblin-god/123/2026-09-04/3.webp',
      );
      expect(p.pages.where((u) => u.contains('promosi')).isEmpty, isTrue);
      expect(p.title, 'From Goblin to Goblin God Chapter 123 - Komiku');
    });
  });

  group('Parser.parseSearch', () {
    test('memisahkan series & chapter', () {
      final results = Parser.parseSearch(const [
        {
          'title': "Murim's Youngest Miracle Demon Doctor Chapter 1",
          'url':
              r'https://secure.komikid.org/murims-youngest-miracle-demon-doctor-chapter-1/',
        },
        {
          'title': 'Murim: The Beginning',
          'url':
              r'https://secure.komikid.org/murims-youngest-miracle-demon-doctor/',
        },
      ]);
      expect(results.length, 2);
      expect(results[0].isChapter, isTrue);
      expect(results[0].seriesSlug, 'murims-youngest-miracle-demon-doctor');
      expect(results[1].isChapter, isFalse);
      expect(results[1].slug, 'murims-youngest-miracle-demon-doctor');
    });
  });

  group('Parser.parseSeries', () {
    const html = '''
<title>Komik From Goblin to Goblin God - Komiku</title>
<table>
<td>Status:</td><td>Ongoing</td>
<td>Rating:</td><td>13+</td>
</table>
<ul>
<li class="genre"><a href="/genre/action/"><span>Action</span></a></li>
<li class="genre"><a href="/genre/fantasy/"><span>Fantasi</span></a></li>
</ul>
<img src="https://thumbnail.komiku.to/uploads/manga/from-goblin-to-goblin-god/manga_thumbnail-A2-From-Goblin-to-Goblin-God.jpg?w=500">
<section id="Sinopsis">
  <p>Cerita ini mengikuti perjalanan seorang Goblin yang sederhana namun gigih.</p>
</section>
<tbody id="daftarChapter">
<tr><td class="judulseries"><a href="/from-goblin-to-goblin-god-chapter-123/" itemprop="url"><span itemprop="name"><b>Chapter 123</b></span></a></td><td class="tanggalseries">04/09/2026</td></tr>
<tr><td class="judulseries"><a href="/from-goblin-to-goblin-god-chapter-122/" itemprop="url"><span itemprop="name"><b>Chapter 122</b></span></a></td><td class="tanggalseries">21/08/2026</td></tr>
</tbody>
''';

    test('judul, status, rating, genre, cover, sinopsis, chapter', () {
      final s = Parser.parseSeries('manga/from-goblin-to-goblin-god', html);
      expect(s.title, 'From Goblin to Goblin God');
      expect(s.status, 'Ongoing');
      expect(s.rating, '13+');
      expect(s.genres, ['Action', 'Fantasi']);
      expect(s.cover, contains('thumbnail.komiku.org'));
      expect(s.synopsis, contains('Goblin'));
      expect(s.chapters.length, 2);
      expect(s.chapters.first.slug, 'from-goblin-to-goblin-god-chapter-123');
      expect(s.chapters.first.label, 'Chapter 123');
      expect(s.chapters.first.date, '04/09/2026');
      expect(s.chapters.last.label, 'Chapter 122');
    });
  });
}
