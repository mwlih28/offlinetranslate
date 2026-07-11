import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/translation_provider.dart';

/// DİL PAKETİ YÖNETİM EKRANI (Bottom Sheet).
///
/// AppBar'daki indirme ikonundan açılır. Desteklenen TÜM dilleri listeler;
/// her dilin yanında duruma göre "İndir" butonu, silme (çöp kutusu) butonu
/// veya indirme göstergesi bulunur. Böylece kullanıcı dil paketlerini
/// tek yerden indirebilir ve depolama alanı açmak için silebilir.
class ModelManagerSheet extends StatelessWidget {
  const ModelManagerSheet({super.key});

  /// Bottom sheet'i açan yardımcı metot.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Icon(Icons.language, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Dil Paketleri',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'İndirilen diller internetsiz (offline) çeviride kullanılır. '
                'Her paket yaklaşık 30 MB yer kaplar.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),

            // Dil listesi — sheet açılırken satırlar kademeli (staggered)
            // fade+kayma ile belirir.
            Expanded(
              child: ListView.builder(
                controller: scrollController,
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
                    child: ListTile(
                      leading: Text(lang.flag,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(lang.displayName),
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
        return FilledButton.tonalIcon(
          key: const ValueKey('download'),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('İndir'),
          onPressed: () => provider.downloadModel(lang),
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
