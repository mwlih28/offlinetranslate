import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// ÇEVİRİ SERVİSİ (Business Logic Katmanı)
///
/// Bu sınıf, Google ML Kit On-Device Translation ile ilgili TÜM iş mantığını
/// içerir ve arayüzden (UI) tamamen bağımsızdır. Böylece:
///  - UI kodu çeviri detaylarını bilmek zorunda kalmaz,
///  - Servis, birim testlerinde (unit test) kolayca taklit edilebilir (mock),
///  - İleride çeviri motoru değişirse sadece bu dosya güncellenir.
class TranslationService {
  /// Dil modellerinin indirilmesi, silinmesi ve kontrolünden sorumlu
  /// ML Kit yöneticisi.
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  /// Aktif çevirmen nesnesi. Her çeviride yeniden oluşturmak yerine,
  /// aynı dil çifti için tekrar tekrar KULLANILIR (performans için).
  OnDeviceTranslator? _translator;

  /// Aktif çevirmenin hangi dil çifti için oluşturulduğunu tutar.
  TranslateLanguage? _activeSource;
  TranslateLanguage? _activeTarget;

  // ---------------------------------------------------------------------------
  // MODEL YÖNETİMİ (İndirme / Silme / Kontrol)
  // ---------------------------------------------------------------------------

  /// Verilen dilin çeviri modeli cihaza indirilmiş mi?
  Future<bool> isModelDownloaded(TranslateLanguage language) {
    return _modelManager.isModelDownloaded(language.bcpCode);
  }

  /// Verilen dilin çeviri modelini cihaza indirir (~30 MB / dil).
  ///
  /// [isWifiRequired: false] → kullanıcı mobil veri ile de indirebilsin.
  /// İndirme İNTERNET gerektirir; ancak indirme tamamlandıktan sonra
  /// çeviri tamamen OFFLINE çalışır.
  Future<bool> downloadModel(TranslateLanguage language) {
    return _modelManager.downloadModel(
      language.bcpCode,
      isWifiRequired: false,
    );
  }

  /// Verilen dilin modelini cihazdan siler (depolama alanı açmak için).
  Future<bool> deleteModel(TranslateLanguage language) {
    return _modelManager.deleteModel(language.bcpCode);
  }

  // ---------------------------------------------------------------------------
  // ÇEVİRİ
  // ---------------------------------------------------------------------------

  /// [text] metnini [from] dilinden [to] diline çevirir.
  ///
  /// Not: Her iki dilin modelinin de cihazda indirilmiş olması gerekir;
  /// bu kontrol üst katmanda (Provider) yapılır.
  Future<String> translate({
    required String text,
    required TranslateLanguage from,
    required TranslateLanguage to,
  }) async {
    // Dil çifti değiştiyse eski çevirmeni kapatıp yenisini oluştur.
    // (OnDeviceTranslator, oluşturulduğu dil çiftine sabittir.)
    if (_translator == null || _activeSource != from || _activeTarget != to) {
      await _translator?.close(); // Kaynak sızıntısını önle.
      _translator = OnDeviceTranslator(
        sourceLanguage: from,
        targetLanguage: to,
      );
      _activeSource = from;
      _activeTarget = to;
    }

    // Çeviri tamamen cihaz üzerinde (on-device) yapılır — internet gerekmez.
    return _translator!.translateText(text);
  }

  /// Servis artık kullanılmayacağında native kaynakları serbest bırakır.
  Future<void> dispose() async {
    await _translator?.close();
    _translator = null;
    _activeSource = null;
    _activeTarget = null;
  }
}
