import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';
import 'language_picker_sheet.dart';
import 'tap_scale.dart';

/// ÜST KISIM: Dil seçim satırı.
///
/// [Kaynak Dil Çipi] — [⇄ Swap] — [Hedef Dil Çipi]
///
/// Çipler koyu füme (slate) yüzeylerdir; büyük dil adı + altında dilin
/// kendi dilindeki adı ve bayrak gösterirler. Dokununca özel tasarım
/// [LanguagePickerSheet] açılır.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: Provider'daki durum değiştiğinde bu widget yeniden çizilir.
    final provider = context.watch<TranslationProvider>();

    return Row(
      children: [
        // Kaynak dil çipi
        Expanded(
          child: _LanguageChip(
            language: provider.sourceLanguage,
            onTap: () => LanguagePickerSheet.show(
              context,
              title: 'Kaynak Dil',
              selected: provider.sourceLanguage,
              onSelected: provider.setSourceLanguage,
            ),
          ),
        ),

        // Dilleri takas eden buton (dönüş + pop animasyonlu)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _AnimatedSwapButton(onPressed: provider.swapLanguages),
        ),

        // Hedef dil çipi
        Expanded(
          child: _LanguageChip(
            language: provider.targetLanguage,
            onTap: () => LanguagePickerSheet.show(
              context,
              title: 'Hedef Dil',
              selected: provider.targetLanguage,
              onSelected: provider.setTargetLanguage,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tek bir dil çipi: büyük dil adı (Türkçe), altında dilin kendi
/// dilindeki adı + bayrak. Dil değişince içerik fade+kayma ile geçer.
class _LanguageChip extends StatelessWidget {
  final AppLanguage language;
  final VoidCallback onTap;

  const _LanguageChip({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kSlateChip,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              // Seçili dil — değişince yumuşak geçiş.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.10, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(language.mlkitLanguage),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${language.nativeName} ${language.flag}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.expand_more, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Dilleri takas eden buton. Basıldığında 180° döner ve kısa bir
/// büyüyüp-küçülme ("pop") efekti yapar.
class _AnimatedSwapButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedSwapButton({required this.onPressed});

  @override
  State<_AnimatedSwapButton> createState() => _AnimatedSwapButtonState();
}

class _AnimatedSwapButtonState extends State<_AnimatedSwapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  double _turns = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Durumu hemen güncelle; animasyon paralel oynar.
    widget.onPressed();
    setState(() => _turns += 0.5); // Her tıklamada yarım tur (180°) ekle.
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Dilleri değiştir',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedRotation(
            turns: _turns,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: ScaleTransition(
              scale: _scale,
              child: const Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
