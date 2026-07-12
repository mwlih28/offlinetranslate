import 'dart:convert';

/// Geçmişe otomatik kaydedilen tek bir çeviriyi temsil eder.
///
/// Cihazda kalıcı olarak (shared_preferences ile) JSON metni hâlinde
/// saklanır — tamamen offline çalışır.
class HistoryEntry {
  /// Kaynak dilin BCP-47 kodu (örn: "en").
  final String sourceCode;

  /// Hedef dilin BCP-47 kodu (örn: "tr").
  final String targetCode;

  /// Çevrilen (kaynak) metin.
  final String sourceText;

  /// Çeviri sonucu.
  final String translatedText;

  /// Çevirinin yapıldığı zaman (listeyi sıralamak için).
  final DateTime createdAt;

  const HistoryEntry({
    required this.sourceCode,
    required this.targetCode,
    required this.sourceText,
    required this.translatedText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'sourceCode': sourceCode,
        'targetCode': targetCode,
        'sourceText': sourceText,
        'translatedText': translatedText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
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

  factory HistoryEntry.fromJson(String source) =>
      HistoryEntry.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
