import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';

/// "ÇEVRİMDIŞI MODU AKTİF" ROZETİ.
///
/// Seçili dil çiftinin her iki paketi de cihazda hazırsa yeşil rozet
/// gösterir (çeviri artık internetsiz çalışıyor demektir). Paket eksikse
/// soluk bir "Dil paketi gerekli" rozeti görünür. Geçişler yumuşaktır.
class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();

    final isChecking =
        provider.sourceModelStatus == ModelStatus.checking ||
            provider.targetModelStatus == ModelStatus.checking;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: isChecking
          ? const SizedBox.shrink(key: ValueKey('checking'))
          : provider.isReadyToTranslate
              ? _badge(
                  key: const ValueKey('online'),
                  background: kGreenBadgeBg,
                  foreground: kGreenBadgeInk,
                  icon: Icons.cloud_done_outlined,
                  label: 'Çevrimdışı Modu Aktif',
                )
              : _badge(
                  key: const ValueKey('offline'),
                  background: kSlateChip,
                  foreground: Colors.white70,
                  icon: Icons.cloud_off_outlined,
                  label: 'Dil paketi gerekli',
                ),
    );
  }

  Widget _badge({
    required Key key,
    required Color background,
    required Color foreground,
    required IconData icon,
    required String label,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
