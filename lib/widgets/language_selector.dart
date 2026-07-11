import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/translation_provider.dart';
import 'frosted_card.dart';
import 'language_picker_sheet.dart';
import 'tap_scale.dart';

/// ÜST KISIM: Dil seçim satırı.
///
/// [Kaynak Dil Pili] — [⇄ Gradyan Swap Butonu] — [Hedef Dil Pili]
///
/// Piller buzlu cam kartlardır; dokununca özel tasarım
/// [LanguagePickerSheet] açılır (varsayılan dropdown menüsü yerine).
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: Provider'daki durum değiştiğinde bu widget yeniden çizilir.
    final provider = context.watch<TranslationProvider>();

    return Row(
      children: [
        // Kaynak dil pili
        Expanded(
          child: _LanguagePill(
            label: 'Kaynak',
            language: provider.sourceLanguage,
            onTap: () => LanguagePickerSheet.show(
              context,
              title: 'Kaynak Dil',
              selected: provider.sourceLanguage,
              onSelected: provider.setSourceLanguage,
            ),
          ),
        ),

        // Dilleri takas eden gradyan buton (dönüş + pop animasyonlu)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _AnimatedSwapButton(onPressed: provider.swapLanguages),
        ),

        // Hedef dil pili
        Expanded(
          child: _LanguagePill(
            label: 'Hedef',
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

/// Tek bir dil pili: üstte küçük etiket ("Kaynak"/"Hedef"), altında
/// bayrak + dil adı. Dil değişince içerik fade+kayma ile geçiş yapar.
class _LanguagePill extends StatelessWidget {
  final String label;
  final AppLanguage language;
  final VoidCallback onTap;

  const _LanguagePill({
    required this.label,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TapScale(
      onTap: onTap,
      child: FrostedCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),

            // Seçili dil — değişince yumuşak geçiş.
            AnimatedSwitcher(
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
              child: Row(
                key: ValueKey(language.mlkitLanguage),
                children: [
                  Text(language.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      language.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dilleri takas eden gradyan dairesel buton. Basıldığında 180° döner
/// ve kısa bir büyüyüp-küçülme ("pop") efekti yapar.
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
        tween: Tween(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
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
        onTap: _handleTap,
        child: AnimatedRotation(
          turns: _turns,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: kAccentGradient,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.swap_horiz, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
