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
