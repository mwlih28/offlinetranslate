import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard için
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/favorite_translation.dart';
import '../providers/favorites_provider.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';

/// ALT KISIM: Çeviri sonucunun gösterildiği açık lavanta kart.
///
/// Üstte hedef dil etiketi (çeviri sürerken ince turuncu ilerleme
/// şeridi), ortada sonuç metni, altta aksiyon satırı:
/// [★ Favori] [⧉ Kopyala] [↗ Paylaş].
class TranslationResultCard extends StatelessWidget {
  const TranslationResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final result = provider.translatedText;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCardLavender,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Çeviri sürerken üst kenarda beliren ince turuncu şerit.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AnimatedOpacity(
              opacity: provider.isTranslating ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Container(height: 3, color: kAccentOrange),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hedef dil etiketi
                Text(
                  '${provider.targetLanguage.flag} '
                  '${provider.targetLanguage.displayName}',
                  style: const TextStyle(
                    color: kInkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),

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
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Row(
                              children: [
                                Icon(Icons.translate,
                                    size: 18,
                                    color:
                                        kInkMuted.withValues(alpha: 0.6)),
                                const SizedBox(width: 8),
                                Text(
                                  'Çeviri burada görünecek...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        kInkMuted.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            key: ValueKey(result),
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              result,
                              style: const TextStyle(
                                fontSize: 19,
                                height: 1.45,
                                color: kInkDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ),

                // Aksiyon satırı: sesli oku + favori + kopyala + paylaş
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const _SpeakButton(),
                    _FavoriteButton(result: result),
                    _CopyButton(text: result),
                    _ShareButton(text: result),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sesli okuma butonu: mevcut çeviri sonucunu cihazın TTS motoruyla
/// seslendirir; seslendirme sürerken ikon dolu hoparlöre döner.
class _SpeakButton extends StatelessWidget {
  const _SpeakButton();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final text = provider.translatedText;

    return IconButton(
      tooltip: 'Sesli oku',
      color: kInkMuted,
      icon: Icon(
        provider.isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
      ),
      onPressed: text.isEmpty ? null : () => provider.speakResult(),
    );
  }
}

/// Favori (yıldız) butonu: mevcut çeviri favorilerdeyse dolu turuncu
/// yıldız gösterir; dokununca ekler/çıkarır (kalıcı olarak saklanır).
class _FavoriteButton extends StatelessWidget {
  final String result;

  const _FavoriteButton({required this.result});

  @override
  Widget build(BuildContext context) {
    final translation = context.watch<TranslationProvider>();
    final favorites = context.watch<FavoritesProvider>();

    final sourceText = translation.textController.text.trim();
    final canFavorite = result.isNotEmpty && sourceText.isNotEmpty;

    final fav = FavoriteTranslation(
      sourceCode: translation.sourceLanguage.bcpCode,
      targetCode: translation.targetLanguage.bcpCode,
      sourceText: sourceText,
      translatedText: result,
      createdAt: DateTime.now(),
    );
    final isSaved = canFavorite && favorites.contains(fav);

    return IconButton(
      tooltip: isSaved ? 'Favorilerden çıkar' : 'Favorilere ekle',
      onPressed: canFavorite
          ? () {
              favorites.toggle(fav);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isSaved
                      ? 'Favorilerden çıkarıldı'
                      : 'Favorilere eklendi ⭐'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : null,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          isSaved ? Icons.star : Icons.star_border,
          key: ValueKey(isSaved),
          color: isSaved ? kAccentOrange : kInkMuted,
        ),
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
      color: kInkMuted,
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

/// Paylaşma butonu: çeviri sonucunu sistemin paylaşım menüsüyle
/// diğer uygulamalara gönderir.
class _ShareButton extends StatelessWidget {
  final String text;

  const _ShareButton({required this.text});

  Future<void> _share(BuildContext context) async {
    // iPad'de paylaşım penceresinin nereden açılacağı zorunludur;
    // butonun ekran konumunu veriyoruz.
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Paylaş',
      color: kInkMuted,
      icon: const Icon(Icons.ios_share),
      onPressed: text.isEmpty ? null : () => _share(context),
    );
  }
}
