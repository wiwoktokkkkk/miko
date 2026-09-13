import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import 'parser.dart';

/// Klien jaringan untuk endpoint publik komiku.org.
class KomikuClient {
  KomikuClient._();

  static final KomikuClient instance = KomikuClient._();

  static const String base = 'https://komiku.org';
  static const String apiBase = 'https://api.komiku.org';
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36';

  /// Header wajib agar CDN komiku tidak memblokir permintaan.
  static const Map<String, String> httpHeaders = {
    'User-Agent': userAgent,
    'Referer': 'https://komiku.org/',
    'Accept-Language': 'id-ID,id;q=0.9,en;q=0.8',
  };

  final http.Client _http = http.Client();
  final Map<String, _CacheEntry> _cache = {};

  // ------------------------------------------------------------------
  // HTTP dasar + cache TTL
  // ------------------------------------------------------------------
  Future<String> _get(String url) async {
    final req = http.Request('GET', Uri.parse(url))
      ..headers.addAll(httpHeaders);
    final streamed = await _http.send(req).timeout(const Duration(seconds: 45));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 404) {
      throw const HttpException404('Halaman tidak ditemukan');
    }
    if (res.statusCode != 200) {
      throw KomikuException('HTTP ${res.statusCode}');
    }
    return res.body;
  }

  Future<T> cached<T>(
    String key,
    Future<T> Function() loader, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final hit = _cache[key];
    final now = DateTime.now();
    if (hit != null && now.difference(hit.time) < ttl) {
      return hit.value as T;
    }
    final value = await loader();
    _cache[key] = _CacheEntry(value, now);
    return value;
  }

  // ------------------------------------------------------------------
  // Beranda & ranking
  // ------------------------------------------------------------------
  Future<HomeData> home() => cached(
    'home',
    () async => Parser.parseHome(await _get('$base/')),
    ttl: const Duration(minutes: 3),
  );

  Future<List<ComicCard>> ranking() => cached(
    'ranking',
    () async => Parser.parseLs4(await _get('$base/p/ranking/')),
    ttl: const Duration(minutes: 5),
  );

  // ------------------------------------------------------------------
  // Katalog (infinite scroll)
  // ------------------------------------------------------------------
  Future<BrowsePage> browse({
    String tipe = '',
    String genre = '',
    String status = '',
    String orderby = 'modified',
    int page = 1,
  }) {
    String path;
    if (page <= 1) {
      path = '$apiBase/manga/';
    } else {
      path = '$apiBase/manga/page/$page/';
    }
    final params = <String, String>{};
    if (tipe.isNotEmpty) params['tipe'] = tipe;
    if (genre.isNotEmpty) params['genre'] = genre;
    if (status.isNotEmpty) params['statusmanga'] = status;
    if (orderby.isNotEmpty && orderby != 'modified') {
      params['orderby'] = orderby;
    }
    final url = params.isEmpty
        ? path
        : '$path?${Uri(queryParameters: params).query}';
    return cached(
      'browse:$tipe:$genre:$status:$orderby:$page',
      () async => Parser.parseBrowse(await _get(url)),
      ttl: const Duration(minutes: 5),
    );
  }

  // ------------------------------------------------------------------
  // Genre
  // ------------------------------------------------------------------
  Future<List<GenreInfo>> genres() => cached(
    'genres',
    () async => Parser.parseGenres(await _get('$base/p/daftar-genre/')),
    ttl: const Duration(hours: 6),
  );

  // ------------------------------------------------------------------
  // Pencarian
  // ------------------------------------------------------------------
  Future<List<SearchResult>> search(String q) {
    final kw = q.trim();
    return cached('search:$kw', () async {
      final raw = await _get(
        '$base/wp-json/wp/v2/search?search=${Uri.encodeQueryComponent(kw)}&per_page=24',
      );
      return Parser.parseSearch(jsonDecode(raw) as List<dynamic>);
    }, ttl: const Duration(minutes: 5));
  }

  // ------------------------------------------------------------------
  // Series & chapter
  // ------------------------------------------------------------------
  Future<SeriesInfo> series(String slug) {
    final normalized = slug.endsWith('/')
        ? slug.substring(0, slug.length - 1)
        : slug;
    final kind = normalized.contains('/')
        ? normalized.split('/').first
        : 'manga';
    final shortSlug = normalized.contains('/')
        ? normalized.split('/').last
        : normalized;
    return cached(
      'series:$kind/$shortSlug',
      () async => Parser.parseSeries(
        '$kind/$shortSlug',
        await _get('$base/$kind/$shortSlug/'),
      ),
      ttl: const Duration(minutes: 10),
    );
  }

  Future<ChapterPages> chapterPages(String chSlug) {
    final normalized = chSlug.endsWith('/')
        ? chSlug.substring(0, chSlug.length - 1)
        : chSlug;
    return cached(
      'chapter:$normalized',
      () async =>
          Parser.parseChapter(normalized, await _get('$base/$normalized/')),
      ttl: const Duration(hours: 12),
    );
  }
}

class _CacheEntry {
  _CacheEntry(this.value, this.time);
  final dynamic value;
  final DateTime time;
}

class KomikuException implements Exception {
  const KomikuException(this.message);
  final String message;
  @override
  String toString() => message;
}

class HttpException404 extends KomikuException {
  const HttpException404(super.message);
}
