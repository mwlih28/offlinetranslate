import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/translation_provider.dart';

/// ÜST KISIM: Dil seçim satırı.
///
/// [Kaynak Dil Dropdown] — [⇄ Swap Butonu] — [Hedef Dil Dropdown]
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: Provider'daki durum değiştiğinde bu widget yeniden çizilir.
    final provider = context.watch<TranslationProvider>();

    return Row(
      children: [
        // Kaynak dil seçimi
        Expanded(
          child: _LanguageDropdown(
            label: 'Kaynak Dil',
            selected: provider.sourceLanguage,
            onChanged: (lang) {
              if (lang != null) provider.setSourceLanguage(lang);
            },
          ),
        ),

        // Dilleri takas eden (swap) buton — dönüş + "pop" animasyonlu.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _AnimatedSwapButton(onPressed: provider.swapLanguages),
        ),

        // Hedef dil seçimi
        Expanded(
          child: _LanguageDropdown(
            label: 'Hedef Dil',
            selected: provider.targetLanguage,
            onChanged: (lang) {
              if (lang != null) provider.setTargetLanguage(lang);
            },
          ),
        ),
      ],
    );
  }
}

/// Tek bir dil seçim dropdown'ı. Material 3 görünümü için
/// [InputDecorator] ile çerçeveli bir kutu içine yerleştirilmiştir.
///
/// Seçili dil değiştiğinde kutunun tamamı [AnimatedSwitcher] ile
/// fade+kayma efektiyle geçiş yapar (ani değişim yerine).
class _LanguageDropdown extends StatelessWidget {
  final String label;
  final AppLanguage selected;
  final ValueChanged<AppLanguage?> onChanged;

  const _LanguageDropdown({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: InputDecorator(
        key: ValueKey(selected.mlkitLanguage),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AppLanguage>(
            value: selected,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            items: supportedLanguages
                .map(
                  (lang) => DropdownMenuItem<AppLanguage>(
                    value: lang,
                    child: Text(
                      '${lang.flag} ${lang.displayName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
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
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
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
    return AnimatedRotation(
      turns: _turns,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: ScaleTransition(
        scale: _scale,
        child: IconButton.filledTonal(
          tooltip: 'Dilleri değiştir',
          icon: const Icon(Icons.swap_horiz),
          onPressed: _handleTap,
        ),
      ),
    );
  }
}
