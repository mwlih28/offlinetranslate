import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Uygulamada desteklenen bir dili temsil eden model sınıfı.
///
/// ML Kit'in [TranslateLanguage] enum'ını, arayüzde gösterilecek
/// Türkçe dil adı ve bayrak emojisi ile birlikte sarmalar (wrap).
class AppLanguage {
  /// ML Kit'in çeviri motorunun tanıdığı dil kodu (örn: TranslateLanguage.turkish).
  final TranslateLanguage mlkitLanguage;

  /// Arayüzde (Dropdown menüde) gösterilecek Türkçe dil adı.
  final String displayName;

  /// Dropdown menüde görsellik için bayrak emojisi.
  final String flag;

  const AppLanguage({
    required this.mlkitLanguage,
    required this.displayName,
    required this.flag,
  });

  /// Model indirme/silme işlemlerinde kullanılan BCP-47 dil kodu (örn: "tr", "en").
  String get bcpCode => mlkitLanguage.bcpCode;

  /// Dropdown gibi widget'ların iki dili karşılaştırabilmesi için
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
  AppLanguage(mlkitLanguage: TranslateLanguage.turkish, displayName: 'Türkçe', flag: '🇹🇷'),
  AppLanguage(mlkitLanguage: TranslateLanguage.english, displayName: 'İngilizce', flag: '🇬🇧'),
  AppLanguage(mlkitLanguage: TranslateLanguage.german, displayName: 'Almanca', flag: '🇩🇪'),
  AppLanguage(mlkitLanguage: TranslateLanguage.french, displayName: 'Fransızca', flag: '🇫🇷'),
  AppLanguage(mlkitLanguage: TranslateLanguage.spanish, displayName: 'İspanyolca', flag: '🇪🇸'),
  AppLanguage(mlkitLanguage: TranslateLanguage.italian, displayName: 'İtalyanca', flag: '🇮🇹'),
  AppLanguage(mlkitLanguage: TranslateLanguage.russian, displayName: 'Rusça', flag: '🇷🇺'),
  AppLanguage(mlkitLanguage: TranslateLanguage.arabic, displayName: 'Arapça', flag: '🇸🇦'),
  AppLanguage(mlkitLanguage: TranslateLanguage.japanese, displayName: 'Japonca', flag: '🇯🇵'),
  AppLanguage(mlkitLanguage: TranslateLanguage.korean, displayName: 'Korece', flag: '🇰🇷'),
  AppLanguage(mlkitLanguage: TranslateLanguage.chinese, displayName: 'Çince', flag: '🇨🇳'),
  AppLanguage(mlkitLanguage: TranslateLanguage.portuguese, displayName: 'Portekizce', flag: '🇵🇹'),
];
