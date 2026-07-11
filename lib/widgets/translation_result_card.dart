import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard için
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import 'frosted_card.dart';

/// ALT KISIM: Çeviri sonucunun gösterildiği buzlu cam kart.
///
/// Başlıkta gradyan renkli hedef dil adı; çeviri sürerken kartın üstünde
/// ince bir gradyan ilerleme şeridi belirir. Sonuç her güncellendiğinde
/// yumuşak fade ile geçer; kart yüksekliği sıçramadan uyarlanır.
class TranslationResultCard extends StatelessWidget {
  const TranslationResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = provider.translatedText;

    return FrostedCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Çeviri sürerken üst kenarda beliren ince gradyan şerit.
          AnimatedOpacity(
            opacity: provider.isTranslating ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Container(
              height: 3,
              decoration: const BoxDecoration(gradient: kAccentGradient),
            ),
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 150),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık satırı: gradyan hedef dil adı + kopyala butonu
                  Row(
                    children: [
                      Text(provider.targetLanguage.flag,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      // Dil adına gradyan renk uygular.
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            kAccentGradient.createShader(bounds),
                        child: Text(
                          provider.targetLanguage.displayName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white, // ShaderMask için taban.
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // "Metni Kopyala" butonu — sadece sonuç varken aktif.
                      _CopyButton(text: result),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Çeviri sonucu (veya zarif boş durum) — her değişimde
                  // yumuşak fade, kart yüksekliği sıçramadan uyarlanır.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topLeft,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: result.isEmpty
                          ? Padding(
                              key: const ValueKey('empty'),
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.translate,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Çeviri burada görünecek...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              result,
                              key: ValueKey(result),
                              style: TextStyle(
                                fontSize: 19,
                                height: 1.45,
                                color: colorScheme.onSurface,
                              ),
                            ),
                    ),
                  ),
                ],
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
