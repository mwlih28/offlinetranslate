import 'package:flutter/foundation.dart';

import '../models/favorite_translation.dart';
import '../services/favorites_service.dart';

/// FAVORİLER DURUM YÖNETİMİ
///
/// Favori çevirilerin listesini tutar; ekleme/çıkarma/temizleme
/// işlemlerini [FavoritesService] üzerinden kalıcı hâle getirir.
class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _service;

  FavoritesProvider({FavoritesService? service})
      : _service = service ?? FavoritesService() {
    _load();
  }

  List<FavoriteTranslation> _items = [];

  /// Favoriler (en yeni en üstte). Dışarıya salt-okunur verilir.
  List<FavoriteTranslation> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  Future<void> _load() async {
    try {
      _items = await _service.load();
      notifyListeners();
    } catch (_) {
      // Depolamaya erişilemezse (örn. test ortamı) boş listeyle devam et.
    }
  }

  /// Verilen çeviri favorilerde kayıtlı mı?
  bool contains(FavoriteTranslation fav) =>
      _items.any((f) => f.sameAs(fav));

  /// Favoriye ekler; zaten ekliyse çıkarır (yıldız butonu davranışı).
  Future<void> toggle(FavoriteTranslation fav) async {
    final existingIndex = _items.indexWhere((f) => f.sameAs(fav));
    if (existingIndex >= 0) {
      _items.removeAt(existingIndex);
    } else {
      _items.insert(0, fav); // En yeni en üstte.
    }
    notifyListeners();
    await _persist();
  }

  /// Tek bir favoriyi siler.
  Future<void> remove(FavoriteTranslation fav) async {
    _items.removeWhere((f) => f.sameAs(fav));
    notifyListeners();
    await _persist();
  }

  /// Tüm favorileri siler (Ayarlar ekranından).
  Future<void> clearAll() async {
    _items = [];
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _service.save(_items);
    } catch (_) {
      // Kaydetme başarısız olsa da bellekteki liste geçerli kalır.
    }
  }
}
