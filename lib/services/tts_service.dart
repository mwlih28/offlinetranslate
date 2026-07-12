import 'package:flutter_tts/flutter_tts.dart';

import '../models/language.dart';

/// SESLİ OKUMA SERVİSİ (Business Logic Katmanı)
///
/// Çeviri sonucunu cihazın KENDİ metin-okuma (TTS) motoruyla seslendirir.
/// Android'de `TextToSpeech`, iOS'ta `AVSpeechSynthesizer` kullanılır —
/// ikisi de cihaz üzerinde çalışır, internet GEREKTİRMEZ (ilgili dil
/// sesi cihazda kurulu olduğu sürece). UI'dan tamamen bağımsızdır.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    // speak() Future'ı sesin KUYRUĞA alındığı anda tamamlanır, konuşmanın
    // bitişini değil — gerçek bitişi/iptali yakalamak için bu callback'ler
    // gerekir (sağlayıcı katmanı isSpeaking durumunu bununla günceller).
    _tts.setCompletionHandler(() => onFinished?.call());
    _tts.setCancelHandler(() => onFinished?.call());
    _tts.setErrorHandler((_) => onFinished?.call());
  }

  /// Konuşma bittiğinde (veya iptal/hata olduğunda) çağrılır.
  void Function()? onFinished;

  /// Verilen metni, [bcpCode]'a karşılık gelen dilde seslendirir.
  Future<void> speak({required String text, required String bcpCode}) async {
    final locale = ttsLocaleByBcp[bcpCode] ?? bcpCode;
    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  /// Devam eden seslendirmeyi durdurur.
  Future<void> stop() => _tts.stop();

  /// Servis artık kullanılmayacağında kaynakları serbest bırakır.
  Future<void> dispose() => _tts.stop();
}
