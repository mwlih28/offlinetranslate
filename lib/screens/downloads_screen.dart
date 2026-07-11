import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/tap_scale.dart';

/// İNDİRİLENLER SEKMESİ: Dil paketi yönetim ekranı.
///
/// Desteklenen TÜM dilleri listeler; her dilin yanında duruma göre
/// turuncu "İndir" butonu, silme (çöp kutusu) butonu veya indirme
/// göstergesi bulunur. Satırlar kademeli (staggered) belirir.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'İndirilenler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'İndirilen diller internetsiz (offline) çeviride kullanılır. '
              'Her paket yaklaşık 30 MB yer kaplar.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),

          // Dil listesi — satırlar kademeli belirir.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: supportedLanguages.length,
              itemBuilder: (context, index) {
                final lang = supportedLanguages[index];
                final status = provider.statusOf(lang);

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + index * 40),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 16),
                      child: child,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: kNavyLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flag,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _statusLabel(status),
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // Durum aksiyonu — geçişli değişir.
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                                scale: animation, child: child),
                          ),
                          child:
                              _buildActionButton(context, provider, lang,
                                  status),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Durumun altyazı metni.
  String _statusLabel(ModelStatus status) {
    switch (status) {
      case ModelStatus.checking:
        return 'Kontrol ediliyor...';
      case ModelStatus.notDownloaded:
        return 'İndirilmedi';
      case ModelStatus.downloading:
        return 'İndiriliyor...';
      case ModelStatus.downloaded:
        return 'Cihazda hazır ✅';
    }
  }

  /// Duruma göre satırın sağındaki aksiyon butonu.
  Widget _buildActionButton(
    BuildContext context,
    TranslationProvider provider,
    AppLanguage lang,
    ModelStatus status,
  ) {
    switch (status) {
      case ModelStatus.checking:
      case ModelStatus.downloading:
        return const SizedBox(
          key: ValueKey('progress'),
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            strokeCap: StrokeCap.round,
            color: kAccentOrange,
          ),
        );

      case ModelStatus.notDownloaded:
        // Tıklamayı TapScale yönetir (çift tetiklemeyi önlemek için
        // PrimaryButton'ın kendi onPressed'i verilmez).
        return TapScale(
          key: const ValueKey('download'),
          onTap: () => provider.downloadModel(lang),
          child: const PrimaryButton(icon: Icons.download, label: 'İndir'),
        );

      case ModelStatus.downloaded:
        return IconButton(
          key: const ValueKey('delete'),
          tooltip: 'Paketi sil',
          icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
          onPressed: () => provider.deleteModel(lang),
        );
    }
  }
}
