import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard için
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';

/// ALT KISIM: Çeviri sonucunun gösterildiği alan.
///
/// Hafif gradyanlı, gölgeli bir kart içinde çeviri sonucu ve sağ üstte
/// "Metni Kopyala" butonu bulunur. Sonuç her güncellendiğinde yumuşak
/// bir fade-in ile belirir; kart, metin uzunluğuna göre sıçramadan
/// büyüyüp küçülür.
class TranslationResultCard extends StatelessWidget {
  const TranslationResultCard({super.key});

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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: provider.isTranslating
                    ? const Padding(
                        key: ValueKey('translating'),
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('idle')),
              ),

              // "Metni Kopyala" butonu — sadece sonuç varken aktif.
              _CopyButton(text: result),
            ],
          ),
          const SizedBox(height: 4),

          // Çeviri sonucu (veya yönlendirici yer tutucu metin) — her
          // değişimde yumuşak fade, kart yüksekliği sıçramadan uyarlanır.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                result.isEmpty ? 'Çeviri burada görünecek...' : result,
                key: ValueKey(result),
                style: TextStyle(
                  fontSize: 18,
                  color: result.isEmpty
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kopyalama butonu. Basıldığında ikon kısa süreliğine ✓ işaretine
/// "morph" olur (rotasyon+fade), ardından tekrar kopyala ikonuna döner.
class _CopyButton extends StatefulWidget {
  final String text;

  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _justCopied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!context.mounted) return;

    setState(() => _justCopied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _justCopied = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Metin panoya kopyalandı ✅'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Metni kopyala',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _justCopied
            ? const Icon(Icons.check, key: ValueKey('check'))
            : const Icon(Icons.copy, key: ValueKey('copy')),
      ),
      onPressed: widget.text.isEmpty ? null : () => _copyToClipboard(context),
    );
  }
}
