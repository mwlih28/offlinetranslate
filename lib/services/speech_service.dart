import 'package:speech_to_text/speech_to_text.dart';

/// SESLE YAZMA (STT) SERVİSİ (Business Logic Katmanı)
///
/// Cihazın konuşma tanıma motorunu kullanarak söylenen sözü metne çevirir.
/// UI'dan tamamen bağımsızdır.
///
/// NOT (offline dürüstlüğü): Bu özellik her zaman %100 offline OLMAYABİLİR.
/// Android/iOS'un konuşma tanıma altyapısı, cihaza/dile göre ya cihaz
/// üzerinde ya da bulut üzerinden çalışır — biz `onDevice: true` ZORLAMIYORUZ
/// çünkü bu, cihaz üzerinde tanıma desteklenmediğinde dinlemeyi tamamen
/// BAŞARISIZ kılıyor (paketin kendi davranışı). Bunun yerine cihazın en
/// uygun yöntemi seçmesine izin verilir; kullanıcı arayüzde bu konuda
/// bilgilendirilir (bkz. TranslationProvider.shouldShowSttNotice).
class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Konuşma tanıma motorunu bir kez başlatır (izin ister).
  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize();
    return _isAvailable;
  }

  /// Dinlemeye başlar; tanınan her ara/final sonuç [onResult] ile bildirilir.
  Future<void> listen({
    required void Function(String text) onResult,
    required String localeId,
  }) {
    return _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        listenFor: const Duration(seconds: 30),
      ),
    );
  }

  /// Dinlemeyi durdurur.
  Future<void> stop() => _speech.stop();

  /// Şu anda dinliyor mu?
  bool get isListening => _speech.isListening;
}
