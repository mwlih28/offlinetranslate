import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';

/// GEÇMİŞ SAKLAMA SERVİSİ (Business Logic Katmanı)
///
/// Yapılan çevirileri cihazın yerel depolamasına (shared_preferences)
/// JSON olarak yazar/okur. UI'dan tamamen bağımsızdır ve internet
/// GEREKTİRMEZ.
class HistoryService {
  static const _storageKey = 'translation_history';

  /// Kayıtlı geçmişi yükler (en yeni en üstte).
  Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    final items = <HistoryEntry>[];
    for (final json in raw) {
      try {
        items.add(HistoryEntry.fromJson(json));
      } catch (_) {
        // Bozuk kayıt varsa sessizce atla — diğerleri etkilenmesin.
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Geçmiş listesinin tamamını kaydeder.
  Future<void> save(List<HistoryEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      items.map((e) => e.toJson()).toList(),
    );
  }
}
