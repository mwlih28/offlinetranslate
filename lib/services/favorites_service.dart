import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_translation.dart';

/// FAVORİ SAKLAMA SERVİSİ (Business Logic Katmanı)
///
/// Favori çevirileri cihazın yerel depolamasına (shared_preferences)
/// JSON olarak yazar/okur. UI'dan tamamen bağımsızdır ve internet
/// GEREKTİRMEZ — uygulamanın offline garantisi bozulmaz.
class FavoritesService {
  static const _storageKey = 'favorite_translations';

  /// Kayıtlı tüm favorileri yükler (en yeni en üstte).
  Future<List<FavoriteTranslation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    final items = <FavoriteTranslation>[];
    for (final json in raw) {
      try {
        items.add(FavoriteTranslation.fromJson(json));
      } catch (_) {
        // Bozuk kayıt varsa sessizce atla — diğerleri etkilenmesin.
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Favori listesinin tamamını kaydeder.
  Future<void> save(List<FavoriteTranslation> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      items.map((f) => f.toJson()).toList(),
    );
  }
}
