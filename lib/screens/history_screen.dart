import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/favorite_translation.dart';
import '../models/history_entry.dart';
import '../models/language.dart';
import '../providers/favorites_provider.dart';
import '../providers/history_provider.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/tap_scale.dart';

/// GEÇMİŞ EKRANI: Yapılan TÜM çevirilerin otomatik kaydı (favorilerden
/// bağımsız). Çeviri sekmesindeki saat ikonuyla açılır (ayrı bir alt
/// sekme değil — bottom nav'ın kalabalıklaşmaması için).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _reuse(BuildContext context, HistoryEntry entry) {
    final translation = context.read<TranslationProvider>();

    final source = appLanguageFromBcp(entry.sourceCode);
    final target = appLanguageFromBcp(entry.targetCode);
    if (source != null) translation.setSourceLanguage(source);
    if (target != null) translation.setTargetLanguage(target);

    translation.textController.text = entry.sourceText;

    Navigator.of(context).pop();
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final history = context.read<HistoryProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geçmişi temizle'),
        content: const Text(
          'Tüm çeviri geçmişi kalıcı olarak silinecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await history.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        title: const Text('Geçmiş', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!history.isEmpty)
            IconButton(
              tooltip: 'Tümünü temizle',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearAll(context),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Yaptığınız tüm çeviriler otomatik olarak burada saklanır '
                '(en fazla 200 kayıt).',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: history.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: history.items.length,
                      itemBuilder: (context, index) {
                        final entry = history.items[index];
                        return _HistoryCard(
                          entry: entry,
                          index: index,
                          onTap: () => _reuse(context, entry),
                          onDelete: () => history.remove(entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history,
              size: 56, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          const Text(
            'Henüz geçmiş yok',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Yaptığınız çeviriler otomatik olarak burada listelenecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek bir geçmiş kartı (beyaz kart, koyu metin) — Favoriler kartıyla
/// aynı tasarım dili, ek olarak "favorilere ekle" hızlı aksiyonu vardır.
class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.entry,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final source = appLanguageFromBcp(entry.sourceCode);
    final target = appLanguageFromBcp(entry.targetCode);
    final favorites = context.watch<FavoritesProvider>();

    final fav = FavoriteTranslation(
      sourceCode: entry.sourceCode,
      targetCode: entry.targetCode,
      sourceText: entry.sourceText,
      translatedText: entry.translatedText,
      createdAt: entry.createdAt,
    );
    final isFavorite = favorites.contains(fav);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 30),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: child,
        ),
      ),
      child: TapScale(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(
            color: kCardWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${source?.flag ?? ''} ${source?.displayName ?? entry.sourceCode}'
                      '  →  '
                      '${target?.flag ?? ''} ${target?.displayName ?? entry.targetCode}',
                      style: const TextStyle(
                        color: kInkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.sourceText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kInkMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.translatedText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kInkDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Sağ aksiyonlar: favorile + kopyala + sil
              Column(
                children: [
                  IconButton(
                    tooltip:
                        isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: isFavorite ? kAccentOrange : kInkMuted,
                    ),
                    onPressed: () => favorites.toggle(fav),
                  ),
                  IconButton(
                    tooltip: 'Çeviriyi kopyala',
                    icon:
                        const Icon(Icons.copy, size: 18, color: kInkMuted),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: entry.translatedText));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Metin panoya kopyalandı ✅'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Geçmişten sil',
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFD64545)),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
