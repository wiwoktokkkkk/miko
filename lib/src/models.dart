import 'dart:convert';

/// Card dari halaman beranda / ranking (markup `article.ls4`).
class ComicCard {
  ComicCard({
    required this.slug,
    required this.title,
    this.cover,
    this.rank,
    this.meta = '',
    this.lastChapterLabel = '',
    this.lastChapterSlug,
    this.origin = '',
  });

  /// Slug series berformat `manga/nama` (atau `manhua/...`, `manhwa/...`).
  final String slug;
  final String title;
  final String? cover;
  final int? rank;
  final String meta;
  final String lastChapterLabel;
  final String? lastChapterSlug;

  /// Asal judul (Manga/Manhua/Manhwa) dari bendera pada kartu ls2.
  final String origin;

  String get kind => slug.split('/').first;
  String get shortSlug => slug.split('/').last;
}

/// Card katalog dari API `api.komiku.org/manga/` (markup `div.bge`).
class BrowseCard {
  BrowseCard({
    required this.slug,
    required this.title,
    required this.type,
    required this.genre,
    required this.meta,
    this.cover,
    this.up = '',
    this.synopsis = '',
    this.firstChapterSlug,
    this.lastChapterSlug,
  });

  final String slug;
  final String title;
  final String type;
  final String genre;
  final String meta;
  final String? cover;
  final String up;
  final String synopsis;
  final String? firstChapterSlug;
  final String? lastChapterSlug;

  String get kind => slug.split('/').first;
  String get shortSlug => slug.split('/').last;
}

/// Satu baris chapter pada halaman detail series.
class Chapter {
  Chapter(this.slug, this.label, this.date);

  final String slug;
  final String label;
  final String date;
}

/// Detail lengkap sebuah series.
class SeriesInfo {
  SeriesInfo({
    required this.slug,
    required this.title,
    this.cover = '',
    this.status = '',
    this.rating = '',
    this.synopsis = '',
    this.genres = const [],
    this.chapters = const [],
  });

  final String slug;
  final String title;
  final String cover;
  final String status;
  final String rating;
  final String synopsis;
  final List<String> genres;
  final List<Chapter> chapters;

  String get kind => slug.split('/').first;
  String get shortSlug => slug.split('/').last;
}

/// Hasil satu halaman katalog (infinite scroll).
class BrowsePage {
  BrowsePage({required this.cards, required this.hasNext});

  final List<BrowseCard> cards;
  final bool hasNext;
}

/// Daftar genre dari `/p/daftar-genre/`.
class GenreInfo {
  GenreInfo(this.slug, this.name, this.count);

  final String slug;
  final String name;
  final String count;
}

/// Umpak genre di beranda (markup `div.ls3`).
class GenreTile {
  GenreTile(this.label, this.image, this.href);

  final String label;
  final String image;
  final String href;

  /// Slug genre bila href berupa `/genre/xxx/`.
  String? get genreSlug {
    final m = RegExp(r'^/genre/([a-z0-9\-]+)/?$').firstMatch(href);
    return m?.group(1);
  }

  /// Status filter bila href berupa `/statusmanga/end/`.
  String? get status {
    final m = RegExp(r'^/statusmanga/([a-z]+)/?$').firstMatch(href);
    return m?.group(1);
  }
}

/// Hasil pencarian resmi (wp-json).
class SearchResult {
  SearchResult(this.title, this.slug, this.isChapter);

  final String title;
  final String slug;
  final bool isChapter;

  /// Slug series (tanpa bagian `-chapter-N`).
  String get seriesSlug {
    if (!isChapter) return slug;
    return slug.split('-chapter-').first;
  }
}

/// Konten halaman baca satu chapter.
class ChapterPages {
  ChapterPages(this.slug, this.title, this.pages);

  final String slug;
  final String title;
  final List<String> pages;
}

/// Data beranda: peringkat, terbaru, baru ditambahkan, umpak genre.
class HomeData {
  HomeData({
    this.rankHarian = const [],
    this.rankMingguan = const [],
    this.terbaru = const [],
    this.baru = const [],
    this.genreTiles = const [],
  });

  final List<ComicCard> rankHarian;
  final List<ComicCard> rankMingguan;
  final List<ComicCard> terbaru;
  final List<ComicCard> baru;
  final List<GenreTile> genreTiles;
}

/// Entry favorit (tersimpan lokal bersama judul & cover).
class FavEntry {
  FavEntry({required this.slug, required this.title, required this.cover});

  final String slug;
  final String title;
  final String cover;

  Map<String, dynamic> toMap() => {
    'slug': slug,
    'title': title,
    'cover': cover,
  };

  factory FavEntry.fromMap(Map<String, dynamic> m) => FavEntry(
    slug: m['slug'] as String? ?? '',
    title: m['title'] as String? ?? '',
    cover: m['cover'] as String? ?? '',
  );

  static List<FavEntry> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FavEntry.fromMap((e as Map<String, dynamic>)))
          .where((e) => e.slug.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Item riwayat baca (tersimpan lokal).
class HistoryItem {
  HistoryItem({
    required this.seriesSlug,
    required this.seriesTitle,
    required this.cover,
    required this.chapterSlug,
    required this.chapterLabel,
    required this.ts,
  });

  final String seriesSlug;
  final String seriesTitle;
  final String cover;
  final String chapterSlug;
  final String chapterLabel;
  final DateTime ts;

  Map<String, dynamic> toMap() => {
    'seriesSlug': seriesSlug,
    'seriesTitle': seriesTitle,
    'cover': cover,
    'chapterSlug': chapterSlug,
    'chapterLabel': chapterLabel,
    'ts': ts.millisecondsSinceEpoch,
  };

  factory HistoryItem.fromMap(Map<String, dynamic> m) => HistoryItem(
    seriesSlug: m['seriesSlug'] as String? ?? '',
    seriesTitle: m['seriesTitle'] as String? ?? '',
    cover: m['cover'] as String? ?? '',
    chapterSlug: m['chapterSlug'] as String? ?? '',
    chapterLabel: m['chapterLabel'] as String? ?? '',
    ts: DateTime.fromMillisecondsSinceEpoch(
      (m['ts'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    ),
  );

  static List<HistoryItem> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => HistoryItem.fromMap((e as Map<String, dynamic>)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
