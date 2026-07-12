import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// GÖRÜNTÜDEN METİN OKUMA (OCR) SERVİSİ (Business Logic Katmanı)
///
/// Google ML Kit'in on-device metin tanıma motorunu kullanır — model
/// indirmeye gerek YOKTUR, tamamen cihaz üzerinde ve internetsiz çalışır.
/// UI'dan tamamen bağımsızdır.
class OcrService {
  /// Her script için ayrı bir tanıyıcı oluşturulup yeniden kullanılır
  /// (her fotoğrafta yeniden oluşturmak yerine).
  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};

  /// Verilen görüntü dosyasındaki metni, [script]'e uygun tanıyıcıyla okur.
  Future<RecognizedText> recognize(String imagePath, TextRecognitionScript script) async {
    final recognizer = _recognizers.putIfAbsent(
      script,
      () => TextRecognizer(script: script),
    );
    final inputImage = InputImage.fromFilePath(imagePath);
    return recognizer.processImage(inputImage);
  }

  /// Servis artık kullanılmayacağında tüm tanıyıcıları kapatır.
  Future<void> dispose() async {
    for (final recognizer in _recognizers.values) {
      await recognizer.close();
    }
    _recognizers.clear();
  }
}
