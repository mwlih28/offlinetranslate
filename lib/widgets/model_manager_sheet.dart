import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/translation_provider.dart';
import 'frosted_card.dart';
import 'tap_scale.dart';

/// DİL PAKETİ YÖNETİM EKRANI (Bottom Sheet).
///
/// Başlıktaki indirme ikonundan açılır. Desteklenen TÜM dilleri buzlu cam
/// zeminli bir listede gösterir; her dilin yanında duruma göre gradyan
/// "İndir" butonu, silme (çöp kutusu) butonu veya indirme göstergesi
/// bulunur. Satırlar kademeli (staggered) belirir.
class ModelManagerSheet extends StatelessWidget {
  const ModelManagerSheet({super.key});

  /// Bottom sheet'i açan yardımcı metot.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // Buzlu cam efekti kendi zeminimizle sağlanır.
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        // Mevcut provider'ı bottom sheet'in widget ağacına da taşıyoruz.
        value: context.read<TranslationProvider>(),
        child: const ModelManagerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
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
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Başlık
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                    child: Row(
                      children: [
                        Icon(Icons.language, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Dil Paketleri',
                            style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'İndirilen diller internetsiz (offline) çeviride '
                      'kullanılır. Her paket yaklaşık 30 MB yer kaplar.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dil listesi — satırlar kademeli belirir.
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: supportedLanguages.length,
                      itemBuilder: (context, index) {
                        final lang = supportedLanguages[index];
                        final status = provider.statusOf(lang);

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration:
                              Duration(milliseconds: 300 + index * 40),
                          curve: Curves.easeOut,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 16),
                              child: child,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 2),
                            leading: Text(lang.flag,
                                style: const TextStyle(fontSize: 24)),
                            title: Text(
                              lang.displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(_statusLabel(status)),
                            trailing: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                    scale: animation, child: child),
                              ),
                              child: _buildActionButton(
                                  context, provider, lang, status),
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
  /// Her durumun kendi [ValueKey]'i, çevreleyen [AnimatedSwitcher]'ın
  /// geçişi doğru tetiklemesini sağlar.
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
          ),
        );

      case ModelStatus.notDownloaded:
        // Tıklamayı TapScale yönetir (çift tetiklemeyi önlemek için
        // GradientButton'ın kendi onPressed'i verilmez).
        return TapScale(
          key: const ValueKey('download'),
          onTap: () => provider.downloadModel(lang),
          child: const GradientButton(
            icon: Icons.download,
            label: 'İndir',
          ),
        );

      case ModelStatus.downloaded:
        return IconButton(
          key: const ValueKey('delete'),
          tooltip: 'Paketi sil',
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => provider.deleteModel(lang),
        );
    }
  }
}
