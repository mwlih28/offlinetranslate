import 'package:flutter/material.dart';

import '../models/language.dart';
import '../theme/app_colors.dart';
import 'tap_scale.dart';

/// ÖZEL DİL SEÇME EKRANI (Bottom Sheet).
///
/// Koyu lacivert zeminli, satırları kademeli (staggered) beliren modern
/// dil seçici. Dil çipine dokununca açılır; seçim yapılınca kapanıp
/// [onSelected]'ı çağırır.
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kNavyLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Sürükleme tutamacı
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Başlık ("Kaynak Dil" / "Hedef Dil")
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Row(
                  children: [
                    const Icon(Icons.translate,
                        size: 20, color: kAccentOrange),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
                      duration: Duration(milliseconds: 250 + index * 35),
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
                            // Seçili dil turuncu vurguyla belirtilir.
                            color: isSelected
                                ? kAccentOrange.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(
                                    color: kAccentOrange
                                        .withValues(alpha: 0.55),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Text(lang.flag,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.displayName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      lang.nativeName,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Seçili dilde onay işareti (geçişli).
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(
                                        scale: anim, child: child),
                                child: isSelected
                                    ? const Icon(Icons.check_circle,
                                        key: ValueKey('on'),
                                        color: kAccentOrange)
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
        );
      },
    );
  }
}
