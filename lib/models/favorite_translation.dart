import 'dart:convert';

/// Favorilere kaydedilmiş tek bir çeviriyi temsil eder.
///
/// Cihazda kalıcı olarak (shared_preferences ile) JSON metni hâlinde
/// saklanır — tamamen offline çalışır.
class FavoriteTranslation {
  /// Kaynak dilin BCP-47 kodu (örn: "en").
  final String sourceCode;

  /// Hedef dilin BCP-47 kodu (örn: "tr").
  final String targetCode;

  /// Çevrilen (kaynak) metin.
  final String sourceText;

  /// Çeviri sonucu.
  final String translatedText;

  /// Favoriye eklenme zamanı (listeyi sıralamak için).
  final DateTime createdAt;

  const FavoriteTranslation({
    required this.sourceCode,
    required this.targetCode,
    required this.sourceText,
    required this.translatedText,
    required this.createdAt,
  });

  /// İki favorinin "aynı çeviri" olup olmadığını belirler
  /// (tarih hariç tüm alanlar karşılaştırılır).
  bool sameAs(FavoriteTranslation other) =>
      sourceCode == other.sourceCode &&
      targetCode == other.targetCode &&
      sourceText == other.sourceText &&
      translatedText == other.translatedText;

  Map<String, dynamic> toMap() => {
        'sourceCode': sourceCode,
        'targetCode': targetCode,
        'sourceText': sourceText,
        'translatedText': translatedText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FavoriteTranslation.fromMap(Map<String, dynamic> map) {
    return FavoriteTranslation(
      sourceCode: map['sourceCode'] as String,
      targetCode: map['targetCode'] as String,
      sourceText: map['sourceText'] as String,
      translatedText: map['translatedText'] as String,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FavoriteTranslation.fromJson(String source) =>
      FavoriteTranslation.fromMap(
          jsonDecode(source) as Map<String, dynamic>);
}
