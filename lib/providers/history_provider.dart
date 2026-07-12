import 'package:flutter/foundation.dart';

import '../models/history_entry.dart';
import '../services/history_service.dart';

/// GEÇMİŞ DURUM YÖNETİMİ
///
/// Yapılan TÜM çevirilerin (favorilerden bağımsız) otomatik kaydını
/// tutar; depolamanın sınırsız büyümemesi için en fazla [_maxItems] kayıt
/// saklanır (yenisi eklenince en eski silinir).
class HistoryProvider extends ChangeNotifier {
  static const _maxItems = 200;

  final HistoryService _service;

  HistoryProvider({HistoryService? service})
      : _service = service ?? HistoryService() {
    _load();
  }

  List<HistoryEntry> _items = [];

  /// Geçmiş (en yeni en üstte). Dışarıya salt-okunur verilir.
  List<HistoryEntry> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  Future<void> _load() async {
    try {
      _items = await _service.load();
      notifyListeners();
    } catch (_) {
      // Depolamaya erişilemezse (örn. test ortamı) boş listeyle devam et.
    }
  }

  /// Yeni bir çeviriyi geçmişe ekler (en üste). Bir önceki kayıtla
  /// birebir aynıysa (art arda aynı metin tekrar çevrilmişse) tekrar
  /// eklenmez.
  Future<void> add(HistoryEntry entry) async {
    if (_items.isNotEmpty) {
      final last = _items.first;
      final isDuplicate = last.sourceCode == entry.sourceCode &&
          last.targetCode == entry.targetCode &&
          last.sourceText == entry.sourceText &&
          last.translatedText == entry.translatedText;
      if (isDuplicate) return;
    }

    _items.insert(0, entry);
    if (_items.length > _maxItems) {
      _items = _items.sublist(0, _maxItems);
    }
    notifyListeners();
    await _persist();
  }

  /// Tek bir geçmiş kaydını siler.
  Future<void> remove(HistoryEntry entry) async {
    _items.remove(entry);
    notifyListeners();
    await _persist();
  }

  /// Tüm geçmişi siler.
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
