import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Penyimpanan lokal: favorit & riwayat baca (singleton).
class AppStore extends ChangeNotifier {
  AppStore._();

  static final AppStore instance = AppStore._();

  static const int _maxHistory = 50;
  static const String _kFavs = 'miko_favs';
  static const String _kHistory = 'miko_history';

  /// Muat data lokal; panggil sekali sebelum [runApp].
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final store = instance;
    store._prefs = prefs;
    store._favs = FavEntry.decodeList(prefs.getString(_kFavs));
    store._history = HistoryItem.decodeList(prefs.getString(_kHistory));
  }

  SharedPreferences? _prefs;
  List<FavEntry> _favs = <FavEntry>[];
  List<HistoryItem> _history = <HistoryItem>[];

  List<FavEntry> get favorites => List.unmodifiable(_favs);
  List<HistoryItem> get history => List.unmodifiable(_history);

  bool isFav(String slug) => _favs.any((e) => e.slug == slug);

  Future<void> toggleFav(SeriesInfo info) async {
    if (isFav(info.slug)) {
      _favs.removeWhere((e) => e.slug == info.slug);
    } else {
      _favs.insert(
        0,
        FavEntry(slug: info.slug, title: info.title, cover: info.cover),
      );
    }
    notifyListeners();
    await _prefs?.setString(
      _kFavs,
      jsonEncode(_favs.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> addHistory(HistoryItem item) async {
    if (item.seriesSlug.isEmpty || item.chapterSlug.isEmpty) return;
    _history.removeWhere((e) => e.seriesSlug == item.seriesSlug);
    _history.insert(0, item);
    if (_history.length > _maxHistory) {
      _history = _history.sublist(0, _maxHistory);
    }
    notifyListeners();
    await _prefs?.setString(
      _kHistory,
      jsonEncode(_history.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> removeHistory(String seriesSlug) async {
    _history.removeWhere((e) => e.seriesSlug == seriesSlug);
    notifyListeners();
    await _prefs?.setString(
      _kHistory,
      jsonEncode(_history.map((e) => e.toMap()).toList()),
    );
  }

  HistoryItem? historyFor(String seriesSlug) {
    for (final h in _history) {
      if (h.seriesSlug == seriesSlug) return h;
    }
    return null;
  }
}
