import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard için
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';

/// ALT KISIM: Çeviri sonucunun gösterildiği alan.
///
/// Arka planı hafif gri (surfaceContainerHighest) bir kart içinde
/// çeviri sonucu ve sağ üstte "Metni Kopyala" butonu bulunur.
class TranslationResultCard extends StatelessWidget {
  const TranslationResultCard({super.key});

  /// Çeviri sonucunu panoya kopyalar ve kullanıcıya SnackBar ile bildirir.
  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Metin panoya kopyalandı ✅'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = provider.translatedText;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Hafif gri / farklı tonda arka plan (Material 3 yüzey rengi).
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık satırı: hedef dil adı + kopyala butonu
          Row(
            children: [
              Text(
                '${provider.targetLanguage.flag} '
                '${provider.targetLanguage.displayName}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),

              // Çeviri sürerken küçük bir yükleniyor göstergesi
              if (provider.isTranslating)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),

              // "Metni Kopyala" butonu — sadece sonuç varken aktif.
              IconButton(
                tooltip: 'Metni kopyala',
                icon: const Icon(Icons.copy),
                onPressed: result.isEmpty
                    ? null
                    : () => _copyToClipboard(context, result),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Çeviri sonucu (veya yönlendirici yer tutucu metin)
          Text(
            result.isEmpty ? 'Çeviri burada görünecek...' : result,
            style: TextStyle(
              fontSize: 18,
              color: result.isEmpty
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                  : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
