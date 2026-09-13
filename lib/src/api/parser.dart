/// Mesin parser HTML/JSON untuk endpoint publik komiku.org.
///
/// Semua pola diuji terhadap struktur halaman produksi (2026).
library;

import '../models.dart';

class Parser {
  Parser._();

  static const String _lazyAsset = '/asset/img/lazy';

  static final RegExp _slug = RegExp(
    r'href="/((?:manga|manhua|manhwa)/[a-z0-9\-]+)/"',
  );
  // Katalog utama memakai URL absolut, sedangkan endpoint pencarian memakai
  // URL relatif. Terima keduanya agar card series tidak hilang dari hasil.
  static final RegExp _slugApi = RegExp(
    r'href="(?:https?://(?:www\.)?komiku\.org)?/((?:manga|manhua|manhwa)/[a-z0-9\-]+)/"',
  );
  static final RegExp _chHref = RegExp(
    r'href="/([a-z0-9\-]+-chapter-[\d\.]+)/"',
  );
  static final RegExp _dataSrc = RegExp(r'data-src="(https?://[^"]+)"');
  static final RegExp _src = RegExp(r'src="(https?://[^"]+)"');
  static final RegExp _artLs4 = RegExp(
    r'<article class="ls4">(.*?)(?=<article|</div class="ls4w|</section|$)',
    dotAll: true,
  );
  static final RegExp _artLs2 = RegExp(
    r'<article class="ls2"[^>]*>(.*?)(?=<article|</div class="ls2-wrap|</section|$)',
    dotAll: true,
  );
  static final RegExp _bge = RegExp(
    r'<div class="bge">(.*?)(?=<div class="bge">|$)',
    dotAll: true,
  );

  /// Bersihkan entitas HTML yang umum & trim.
  static String clean(String s) => s
      .replaceAll('&#8217;', "'")
      .replaceAll('&#8216;', "'")
      .replaceAll('&#8220;', '"')
      .replaceAll('&#8221;', '"')
      .replaceAll('&#8211;', '-')
      .replaceAll('&#038;', '&')
      .replaceAll('&amp;', '&')
      .replaceAll('&#183;', '·')
      .replaceAll('&middot;', '·')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .trim();

  static String collapse(String s) => clean(s).replaceAll(RegExp(r'\s+'), ' ');

  /// Normalisasi host CDN gambar: `thumbnail.komiku.to` sering terblokir,
  /// varian `.org` tetap aktif.
  static String normalizeCover(String? url) {
    if (url == null || url.isEmpty) return '';
    return url
        .replaceAll('&#038;', '&')
        .replaceAll('thumbnail.komiku.to', 'thumbnail.komiku.org')
        .replaceAll('&#038;', '&');
  }

  /// Apakah thumbnail berasal dari varian lanskap milik daftar Komiku.
  /// Thumbnail seperti ini tidak boleh langsung di-crop ke kotak poster karena
  /// hasilnya terlihat sangat zoom. UI dapat mengambil cover portrait detail.
  static bool isLandscapeCover(String? url) {
    final raw = (url ?? '').replaceAll('&#038;', '&');
    if (raw.isEmpty) return false;
    final lower = raw.toLowerCase();
    if (lower.contains('horizontal')) return true;

    final uri = Uri.tryParse(raw);
    final resize = uri?.queryParameters['resize'];
    if (resize == null) return false;
    final size = resize.split(',');
    if (size.length != 2) return false;
    final width = double.tryParse(size[0]);
    final height = double.tryParse(size[1]);
    return width != null && height != null && width > height;
  }

  /// Kandidat URL cover: prefer URL hasil parser, lalu host alternatif.
  static List<String> coverCandidates(String? url) {
    final raw = (url ?? '').replaceAll('&#038;', '&');
    if (raw.isEmpty) return const [];
    final out = <String>[raw];
    if (raw.contains('thumbnail.komiku.to')) {
      out.add(raw.replaceFirst('thumbnail.komiku.to', 'thumbnail.komiku.org'));
    } else if (raw.contains('thumbnail.komiku.org')) {
      out.add(raw.replaceFirst('thumbnail.komiku.org', 'thumbnail.komiku.to'));
    }
    return out;
  }

  /// Kandidat host untuk satu halaman reader.
  ///
  /// Situs Komiku sendiri mengganti `imageN.komiku.to` ke `img.komiku.org`
  /// saat CDN bernomor gagal. Reader meniru fallback tersebut agar halaman
  /// tidak berubah menjadi layar kosong pada jaringan/perangkat tertentu.
  static List<String> chapterImageCandidates(String url) {
    final raw = clean(url).replaceAll('&amp;', '&');
    if (raw.isEmpty) return const [];
    final out = <String>[raw];
    final uri = Uri.tryParse(raw);
    final host = uri?.host ?? '';
    if (RegExp(r'^image\d+\.komiku\.(?:to|org|com)$').hasMatch(host)) {
      final fallback = uri!.replace(host: 'img.komiku.org').toString();
      if (fallback != raw) out.add(fallback);
    }
    return out;
  }

  static String? _coverOf(String block) {
    final d = _dataSrc.firstMatch(block);
    if (d != null) return d.group(1);
    final s = _src.firstMatch(block);
    if (s != null && !s.group(1)!.contains(_lazyAsset)) return s.group(1);
    return null;
  }

  // ------------------------------------------------------------------
  // Kartu ls4 (beranda, ranking)
  // ------------------------------------------------------------------
  static List<ComicCard> parseLs4(String html) {
    final out = <ComicCard>[];
    for (final m in _artLs4.allMatches(html)) {
      final b = m.group(1)!;
      final sl = _slug.firstMatch(b);
      if (sl == null) continue;
      final rankM = RegExp(r'rank-num">(\d+)<').firstMatch(b);
      final titleM = RegExp(r'<h4><a[^>]*>([^<]+)</a>').firstMatch(b);
      final metaM = RegExp(r'class="ls4s">([^<]+)</span>').firstMatch(b);
      final chM = RegExp(
        r'href="/([a-z0-9\-]+-chapter-[\d\.]+)/"[^>]*>([^<]+)</a>',
      ).firstMatch(b);
      final slug = sl.group(1)!;
      out.add(
        ComicCard(
          slug: slug,
          title: clean(titleM?.group(1) ?? slug.split('/').last),
          cover: normalizeCover(_coverOf(b)),
          rank: rankM == null ? null : int.tryParse(rankM.group(1)!),
          meta: metaM == null ? '' : clean(metaM.group(1)!),
          lastChapterLabel: chM == null ? '' : clean(chM.group(2)!),
          lastChapterSlug: chM?.group(1),
        ),
      );
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Kartu ls2 (Terbaru / Baru Ditambahkan)
  // ------------------------------------------------------------------
  static List<ComicCard> parseLs2(String html) {
    final out = <ComicCard>[];
    final seen = <String>{};
    for (final m in _artLs2.allMatches(html)) {
      final b = m.group(1)!;
      final sl = _slug.firstMatch(b);
      if (sl == null) continue;
      final slug = sl.group(1)!;
      if (!seen.add(slug)) continue;
      final flagM = RegExp(
        r'flag" src="/asset/img/([a-z]{2})\.png"',
      ).firstMatch(b);
      final origin =
          {'jp': 'Manga', 'kr': 'Manhwa', 'cn': 'Manhua'}[flagM?.group(1)] ??
          '';
      final titleM = RegExp(r'<h3><a[^>]*>([^<]+)</a>').firstMatch(b);
      final metaM = RegExp(r'class="ls2t">([^<]+)</span>').firstMatch(b);
      final chM = RegExp(
        r'href="/([a-z0-9\-]+-chapter-[\d\.]+)/"[^>]*>([^<]+)</a>',
      ).firstMatch(b);
      final meta = metaM == null ? '' : clean(metaM.group(1)!);
      out.add(
        ComicCard(
          slug: slug,
          title: clean(titleM?.group(1) ?? slug.split('/').last),
          cover: normalizeCover(_coverOf(b)),
          meta: origin.isEmpty ? meta : '$origin · $meta',
          lastChapterLabel: chM == null ? '' : clean(chM.group(2)!),
          lastChapterSlug: chM?.group(1),
          origin: origin,
        ),
      );
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Beranda
  // ------------------------------------------------------------------
  static String _section(String html, String id) {
    final m = RegExp(
      '<section id="$id".*?</section>',
      dotAll: true,
    ).firstMatch(html);
    return m?.group(0) ?? '';
  }

  static HomeData parseHome(String html) {
    String panel(String startId, String endMarker) {
      final i = html.indexOf('id="$startId"');
      if (i < 0) return '';
      final j = html.indexOf(endMarker, i + startId.length);
      return html.substring(i + startId.length, j > 0 ? j : html.length);
    }

    final harian = parseLs4(panel('rank-harian', 'id="rank-mingguan"'));
    final mingguan = parseLs4(panel('rank-mingguan', '<section'));

    final terbaruHtml = _section(html, 'Terbaru');
    var terbaru = parseLs2(terbaruHtml);
    if (terbaru.isEmpty) terbaru = parseLs4(terbaruHtml);

    final baruHtml = _section(html, 'Baru_Ditambahkan');
    var baru = parseLs2(baruHtml);
    if (baru.isEmpty) baru = parseLs4(baruHtml);

    return HomeData(
      rankHarian: harian,
      rankMingguan: mingguan,
      terbaru: terbaru,
      baru: baru,
      genreTiles: parseTiles(_section(html, 'Genre')),
    );
  }

  // ------------------------------------------------------------------
  // Umpak genre (div.ls3)
  // ------------------------------------------------------------------
  static List<GenreTile> parseTiles(String html) {
    final out = <GenreTile>[];
    final re = RegExp(
      r'<div class="ls3">(.*?)(?=<div class="ls3">|$)',
      dotAll: true,
    );
    for (final m in re.allMatches(html)) {
      final b = m.group(1)!;
      final labelM = RegExp(r'<h4>([^<]+)</h4>').firstMatch(b);
      final hrefM = RegExp(r'href="(/[a-z]+/[a-z0-9\-]+)/"').firstMatch(b);
      final imgM = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(b);
      if (labelM == null || hrefM == null) continue;
      out.add(
        GenreTile(
          clean(labelM.group(1)!),
          imgM?.group(1) ?? '',
          hrefM.group(1)!,
        ),
      );
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Katalog (api.komiku.org/manga/) — markup div.bge
  // ------------------------------------------------------------------
  static BrowsePage parseBrowse(String html) {
    final out = <BrowseCard>[];
    final seen = <String>{};
    for (final m in _bge.allMatches(html)) {
      final b = m.group(1)!;
      final sl = _slugApi.firstMatch(b);
      if (sl == null) continue;
      final slug = sl.group(1)!;
      if (!seen.add(slug)) continue;
      final coverM = RegExp(r'<img[^>]+src="(https?://[^"]+)"').firstMatch(b);
      final typeM = RegExp(r'tpe1_inf">\s*<b>\s*([^<]+?)\s*</b>').firstMatch(b);
      final genreFromBadge = RegExp(
        r'tpe1_inf">\s*<b>[^<]*</b>\s*([^<]+?)\s*</div>',
      ).firstMatch(b);
      final upM = RegExp(r'class="up">\s*([^<]+?)\s*<').firstMatch(b);
      final titleM = RegExp(
        r'<h3>\s*([^<]+?)\s*</h3>',
        dotAll: true,
      ).firstMatch(b);
      final metaM = RegExp(
        r'class="judul2">(.*?)</span>',
        dotAll: true,
      ).firstMatch(b);
      final synM = RegExp(r'<p>\s*(.*?)\s*</p>', dotAll: true).firstMatch(b);
      final firstM = RegExp(
        r'href="/([a-z0-9\-]+-chapter-[\d\.]+)/"[^>]*>\s*<span>\s*Awal:',
      ).firstMatch(b);
      final lastM = RegExp(
        r'href="/([a-z0-9\-]+-chapter-[\d\.]+)/"[^>]*>\s*<span>\s*Terbaru:',
      ).firstMatch(b);

      final type = typeM == null ? '' : clean(typeM.group(1)!);
      final genre = genreFromBadge == null
          ? ''
          : clean(genreFromBadge.group(1)!);
      out.add(
        BrowseCard(
          slug: slug,
          title: clean(titleM?.group(1) ?? slug.split('/').last),
          type: type,
          genre: genre,
          meta: metaM == null ? '' : collapse(metaM.group(1)!),
          cover: normalizeCover(coverM?.group(1)),
          up: upM == null ? '' : clean(upM.group(1)!),
          synopsis: synM == null ? '' : collapse(synM.group(1)!),
          firstChapterSlug: firstM?.group(1),
          lastChapterSlug: lastM?.group(1),
        ),
      );
    }
    final hasNext = RegExp(
      r'hx-get="https?://api\.komiku\.org/manga/page/\d+/',
    ).hasMatch(html);
    return BrowsePage(cards: out, hasNext: hasNext && out.isNotEmpty);
  }

  // ------------------------------------------------------------------
  // Daftar genre
  // ------------------------------------------------------------------
  static List<GenreInfo> parseGenres(String html) {
    final out = <GenreInfo>[];
    final re = RegExp(
      r'href="/genre/([a-z0-9\-]+)/"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    for (final m in re.allMatches(html)) {
      final inner = m.group(2)!;
      final nameM = RegExp(r'<b>([^<]+)</b>').firstMatch(inner);
      final countM = RegExp(r'<i>([^<]+)</i>').firstMatch(inner);
      final name = clean(nameM?.group(1) ?? m.group(1)!);
      out.add(
        GenreInfo(
          m.group(1)!,
          name,
          countM == null ? '' : clean(countM.group(1)!),
        ),
      );
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Pencarian (wp-json)
  // ------------------------------------------------------------------
  static List<SearchResult> parseSearch(List<dynamic> json) {
    final out = <SearchResult>[];
    for (final it in json) {
      final map = it as Map<String, dynamic>;
      final url = (map['url'] as String? ?? '').replaceAll(
        'secure.komikid.org',
        'komiku.org',
      );
      final m = RegExp(r'komiku\.org/(.+?)/?$').firstMatch(url);
      final slug = m?.group(1) ?? '';
      if (slug.isEmpty) continue;
      out.add(
        SearchResult(
          clean(map['title'] as String? ?? ''),
          slug,
          slug.contains('-chapter-'),
        ),
      );
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Detail series
  // ------------------------------------------------------------------
  static SeriesInfo parseSeries(String slug, String html) {
    final parts = slug.split('/');
    String title = parts.length > 1 ? parts.last : slug;
    final tM = RegExp(r'<title>([^<]+)</title>').firstMatch(html);
    if (tM != null) {
      var t = tM.group(1)!;
      t = t.replaceFirst(RegExp(r'\s*-\s*Komiku\s*$'), '');
      t = t.replaceFirst(RegExp(r'^Komik\s+'), '');
      title = clean(t);
    }

    String td(String label) {
      final m = RegExp('<td>$label:</td><td>([^<]+)</td>').firstMatch(html);
      return m == null ? '' : clean(m.group(1)!);
    }

    final genres = RegExp(
      r'<li class="genre"><a[^>]*><span>([^<]+)</span>',
    ).allMatches(html).map((m) => clean(m.group(1)!)).toList();

    String cover = '';
    for (final u in RegExp(
      r'<img[^>]+(?:data-src|src)="([^"]+)"',
    ).allMatches(html).map((m) => m.group(1)!)) {
      if (u.contains('thumbnail.komiku') ||
          u.contains('/uploads/') ||
          u.contains('komiku.to')) {
        if (!u.contains(_lazyAsset)) {
          cover = normalizeCover(u);
          break;
        }
      }
    }

    var synopsis = '';
    final sM = RegExp(
      r'<section[^>]*id="Sinopsis"[^>]*>(.*?)</section>',
      dotAll: true,
    ).firstMatch(html);
    if (sM != null) {
      synopsis = collapse(
        sM.group(1)!.replaceAll(RegExp(r'<[^>]+>'), ' '),
      ).trim();
    }

    final chapters = <Chapter>[];
    final chRe = RegExp(
      r'<td class="judulseries">.*?<a href="/([a-z0-9\-]+-chapter-[\d\.]+)/".*?<b>([^<]+)</b>.*?class="tanggalseries">([^<]*)</td>',
      dotAll: true,
    );
    for (final m in chRe.allMatches(html)) {
      chapters.add(
        Chapter(m.group(1)!, clean(m.group(2)!), clean(m.group(3)!)),
      );
    }
    if (chapters.isEmpty) {
      final list =
          _chHref.allMatches(html).map((m) => m.group(1)!).toSet().toList()
            ..sort((a, b) => b.compareTo(a));
      for (final h in list) {
        chapters.add(Chapter(h, 'Chapter ${h.split('-chapter-').last}', ''));
      }
    }

    return SeriesInfo(
      slug: slug,
      title: title,
      cover: cover,
      status: td('Status'),
      rating: td('Rating'),
      synopsis: synopsis.length > 1200
          ? '${synopsis.substring(0, 1200)}…'
          : synopsis,
      genres: genres,
      chapters: chapters,
    );
  }

  // ------------------------------------------------------------------
  // Halaman chapter (URL gambar)
  // ------------------------------------------------------------------
  static ChapterPages parseChapter(String chSlug, String html) {
    final tM = RegExp(r'<title>([^<]+)</title>').firstMatch(html);
    final re = RegExp(
      'https://(?:image\\d+|img)\\.komiku\\.(?:to|org|com)/[^\\s"\'<>]+?\\.(?:webp|jpg|jpeg|png)',
      caseSensitive: false,
    );
    final urls = <String>[];
    final seen = <String>{};
    for (final m in re.allMatches(html)) {
      final u = m.group(0)!.replaceAll('&amp;', '&');
      final lower = u.toLowerCase();
      if (!lower.contains('/upload')) continue;
      if (lower.contains('promosi') ||
          lower.contains('banner') ||
          lower.contains('logo') ||
          lower.contains('plus')) {
        continue;
      }
      if (seen.add(u)) urls.add(u);
    }
    return ChapterPages(
      chSlug,
      tM == null ? chSlug : clean(tM.group(1)!),
      urls,
    );
  }
}
