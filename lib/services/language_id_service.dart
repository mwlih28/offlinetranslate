import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

/// DİL ALGILAMA SERVİSİ (Business Logic Katmanı)
///
/// Yazılan/tanınan metnin hangi dilde olduğunu, cihaza gömülü küçük bir
/// modelle (indirme GEREKTİRMEZ) tespit eder. UI'dan tamamen bağımsızdır.
class LanguageIdService {
  final LanguageIdentifier _identifier =
      LanguageIdentifier(confidenceThreshold: 0.5);

  /// [text]'in BCP-47 dil kodunu döner (örn: "en"); belirlenemezse `null`.
  Future<String?> identify(String text) async {
    final code = await _identifier.identifyLanguage(text);
    if (code == _identifier.undeterminedLanguageCode) return null;
    return code;
  }

  Future<void> dispose() => _identifier.close();
}
