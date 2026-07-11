import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/favorites_provider.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';

/// AYARLAR SEKMESİ.
///
/// Depolama temizleme aksiyonları ve uygulama hakkında bilgiler.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Onay istemi gösterir; kullanıcı onaylarsa [onConfirm] çalışır.
  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNavyLight,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content:
            Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Vazgeç', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, sil',
                style: TextStyle(color: kAccentOrange)),
          ),
        ],
      ),
    );
    if (approved == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final translation = context.watch<TranslationProvider>();
    final favorites = context.watch<FavoritesProvider>();

    // İndirilmiş paket sayısı (silme aksiyonunun altyazısı için).
    final downloadedCount = supportedLanguages
        .where((l) => translation.statusOf(l) == ModelStatus.downloaded)
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              'Ayarlar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // ---- DEPOLAMA ----
          const _SectionLabel('Depolama'),
          _SettingsTile(
            icon: Icons.delete_sweep_outlined,
            iconColor: const Color(0xFFFF6B6B),
            title: 'Tüm dil paketlerini sil',
            subtitle: downloadedCount == 0
                ? 'İndirilmiş paket yok'
                : '$downloadedCount paket indirilmiş (~${downloadedCount * 30} MB)',
            onTap: downloadedCount == 0
                ? null
                : () => _confirm(
                      context,
                      title: 'Tüm paketler silinsin mi?',
                      message:
                          'İndirilen $downloadedCount dil paketi cihazdan '
                          'silinecek. Offline çeviri için yeniden indirmeniz '
                          'gerekir.',
                      onConfirm: () {
                        for (final lang in supportedLanguages) {
                          if (translation.statusOf(lang) ==
                              ModelStatus.downloaded) {
                            translation.deleteModel(lang);
                          }
                        }
                      },
                    ),
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            iconColor: kAccentOrange,
            title: 'Favorileri temizle',
            subtitle: favorites.isEmpty
                ? 'Kayıtlı favori yok'
                : '${favorites.items.length} favori kayıtlı',
            onTap: favorites.isEmpty
                ? null
                : () => _confirm(
                      context,
                      title: 'Favoriler temizlensin mi?',
                      message:
                          'Kayıtlı ${favorites.items.length} favori çeviri '
                          'kalıcı olarak silinecek.',
                      onConfirm: favorites.clearAll,
                    ),
          ),
          const SizedBox(height: 20),

          // ---- HAKKINDA ----
          const _SectionLabel('Hakkında'),
          const _SettingsTile(
            icon: Icons.translate,
            iconColor: Colors.white70,
            title: 'Çeviri motoru',
            subtitle:
                'Google ML Kit — çeviri tamamen cihaz üzerinde yapılır',
          ),
          const _SettingsTile(
            icon: Icons.wifi_off_outlined,
            iconColor: Colors.white70,
            title: 'İnternetsiz çalışır',
            subtitle:
                'Dil paketleri indirildikten sonra internet gerekmez — '
                'uçak modunda bile çevirir',
          ),
          const _SettingsTile(
            icon: Icons.info_outline,
            iconColor: Colors.white70,
            title: 'Sürüm',
            subtitle: '1.0.0',
          ),
        ],
      ),
    );
  }
}

/// Bölüm başlığı etiketi.
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: kAccentOrange,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Tek bir ayar satırı (koyu füme kart).
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: kNavyLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: Colors.white38)
            : null,
      ),
    );
  }
}
