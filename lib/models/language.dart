import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Uygulamada desteklenen bir dili temsil eden model sınıfı.
///
/// ML Kit'in [TranslateLanguage] enum'ını, arayüzde gösterilecek
/// Türkçe dil adı, dilin KENDİ dilindeki adı (nativeName) ve bayrak
/// emojisi ile birlikte sarmalar (wrap).
class AppLanguage {
  /// ML Kit'in çeviri motorunun tanıdığı dil kodu (örn: TranslateLanguage.turkish).
  final TranslateLanguage mlkitLanguage;

  /// Arayüzde gösterilecek Türkçe dil adı (örn: "İngilizce").
  final String displayName;

  /// Dilin kendi dilindeki adı (örn: "English") — çiplerde alt satır.
  final String nativeName;

  /// Görsellik için bayrak emojisi.
  final String flag;

  const AppLanguage({
    required this.mlkitLanguage,
    required this.displayName,
    required this.nativeName,
    required this.flag,
  });

  /// Model indirme/silme işlemlerinde kullanılan BCP-47 dil kodu (örn: "tr", "en").
  String get bcpCode => mlkitLanguage.bcpCode;

  /// Widget'ların iki dili karşılaştırabilmesi için
  /// eşitlik kontrolünü ML Kit dil koduna göre yapıyoruz.
  @override
  bool operator ==(Object other) =>
      other is AppLanguage && other.mlkitLanguage == mlkitLanguage;

  @override
  int get hashCode => mlkitLanguage.hashCode;
}

/// Uygulamanın desteklediği dillerin listesi.
///
/// ML Kit 50'den fazla dili destekler; burada pratik bir alt küme seçildi.
/// Yeni bir dil eklemek için bu listeye yeni bir [AppLanguage] eklemek yeterlidir.
const List<AppLanguage> supportedLanguages = [
  AppLanguage(mlkitLanguage: TranslateLanguage.turkish, displayName: 'Türkçe', nativeName: 'Türkçe', flag: '🇹🇷'),
  AppLanguage(mlkitLanguage: TranslateLanguage.english, displayName: 'İngilizce', nativeName: 'English', flag: '🇬🇧'),
  AppLanguage(mlkitLanguage: TranslateLanguage.german, displayName: 'Almanca', nativeName: 'Deutsch', flag: '🇩🇪'),
  AppLanguage(mlkitLanguage: TranslateLanguage.french, displayName: 'Fransızca', nativeName: 'Français', flag: '🇫🇷'),
  AppLanguage(mlkitLanguage: TranslateLanguage.spanish, displayName: 'İspanyolca', nativeName: 'Español', flag: '🇪🇸'),
  AppLanguage(mlkitLanguage: TranslateLanguage.italian, displayName: 'İtalyanca', nativeName: 'Italiano', flag: '🇮🇹'),
  AppLanguage(mlkitLanguage: TranslateLanguage.russian, displayName: 'Rusça', nativeName: 'Русский', flag: '🇷🇺'),
  AppLanguage(mlkitLanguage: TranslateLanguage.arabic, displayName: 'Arapça', nativeName: 'العربية', flag: '🇸🇦'),
  AppLanguage(mlkitLanguage: TranslateLanguage.japanese, displayName: 'Japonca', nativeName: '日本語', flag: '🇯🇵'),
  AppLanguage(mlkitLanguage: TranslateLanguage.korean, displayName: 'Korece', nativeName: '한국어', flag: '🇰🇷'),
  AppLanguage(mlkitLanguage: TranslateLanguage.chinese, displayName: 'Çince', nativeName: '中文', flag: '🇨🇳'),
  AppLanguage(mlkitLanguage: TranslateLanguage.portuguese, displayName: 'Portekizce', nativeName: 'Português', flag: '🇵🇹'),
];

/// BCP-47 koduna (örn: "en") karşılık gelen [AppLanguage]'i bulur.
/// Favorilerden geri yükleme gibi durumlarda kullanılır.
AppLanguage? appLanguageFromBcp(String code) {
  for (final lang in supportedLanguages) {
    if (lang.bcpCode == code) return lang;
  }
  return null;
}

/// Verilen dilin metnini görüntüden okumak (OCR) için hangi ML Kit
/// script tanıyıcısının kullanılacağını belirler.
///
/// ML Kit'in on-device metin tanıma motoru sadece 5 script'i destekler:
/// Latin, Çince, Japonca, Korece, Devanagari. **Arapça ve Rusça (Kiril)
/// script'i desteklenmiyor** — bu diller kaynak dil olarak seçiliyse
/// kamera ile çeviri özelliği kullanılamaz (`null` döner).
TextRecognitionScript? scriptFor(AppLanguage lang) {
  switch (lang.mlkitLanguage) {
    case TranslateLanguage.chinese:
      return TextRecognitionScript.chinese;
    case TranslateLanguage.japanese:
      return TextRecognitionScript.japanese;
    case TranslateLanguage.korean:
      return TextRecognitionScript.korean;
    case TranslateLanguage.arabic:
    case TranslateLanguage.russian:
      return null;
    default:
      // Türkçe, İngilizce, Almanca, Fransızca, İspanyolca, İtalyanca,
      // Portekizce — hepsi Latin alfabesi kullanır.
      return TextRecognitionScript.latin;
  }
}

/// Sesli okuma (TTS) ve sesle yazma (STT) motorlarının beklediği
/// BCP-47 yerel ayar (locale) kodu — sadece dil kodu yetmez, bölge de
/// gerekir (ör. "tr" değil "tr-TR"). Her iki servis de aynı sözlüğü
/// paylaşır.
const Map<String, String> ttsLocaleByBcp = {
  'tr': 'tr-TR',
  'en': 'en-US',
  'de': 'de-DE',
  'fr': 'fr-FR',
  'es': 'es-ES',
  'it': 'it-IT',
  'ru': 'ru-RU',
  'ar': 'ar-SA',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
  'zh': 'zh-CN',
  'pt': 'pt-PT',
};
