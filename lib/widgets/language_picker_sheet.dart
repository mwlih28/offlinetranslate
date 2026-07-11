import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../models/language.dart';
import 'tap_scale.dart';

/// ÖZEL DİL SEÇME EKRANI (Bottom Sheet).
///
/// Varsayılan DropdownButton menüsü yerine kullanılan, buzlu cam zeminli,
/// satırları kademeli (staggered) beliren modern dil seçici. Dil piline
/// dokununca açılır; seçim yapılınca kapanıp [onSelected]'ı çağırır.
class LanguagePickerSheet extends StatelessWidget {
  final String title;
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelected;

  const LanguagePickerSheet({
    super.key,
    required this.title,
    required this.selected,
    required this.onSelected,
  });

  /// Sheet'i açan yardımcı metot.
  static void show(
    BuildContext context, {
    required String title,
    required AppLanguage selected,
    required ValueChanged<AppLanguage> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      // Buzlu cam efekti kendi zeminimizle sağlanır.
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (_) => LanguagePickerSheet(
        title: title,
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.80),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Sürükleme tutamacı
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Başlık ("Kaynak Dil" / "Hedef Dil")
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                    child: Row(
                      children: [
                        Icon(Icons.translate,
                            size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(title, style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),

                  // Dil listesi — satırlar kademeli belirir.
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: supportedLanguages.length,
                      itemBuilder: (context, index) {
                        final lang = supportedLanguages[index];
                        final isSelected = lang == selected;

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration:
                              Duration(milliseconds: 250 + index * 35),
                          curve: Curves.easeOut,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 14),
                              child: child,
                            ),
                          ),
                          child: TapScale(
                            onTap: () {
                              onSelected(lang);
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                // Seçili dil hafif vurgulu görünür.
                                color: isSelected
                                    ? colorScheme.primary
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.45),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Text(lang.flag,
                                      style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      lang.displayName,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Seçili dilde onay işareti (geçişli).
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(
                                            scale: anim, child: child),
                                    child: isSelected
                                        ? Icon(Icons.check_circle,
                                            key: const ValueKey('on'),
                                            color: colorScheme.primary)
                                        : const SizedBox.shrink(
                                            key: ValueKey('off')),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
