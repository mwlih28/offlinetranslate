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

        // Dilleri takas eden (swap) buton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton.filledTonal(
            tooltip: 'Dilleri değiştir',
            icon: const Icon(Icons.swap_horiz),
            onPressed: provider.swapLanguages,
          ),
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
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppLanguage>(
          value: selected,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
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
    );
  }
}
