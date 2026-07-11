import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/favorite_translation.dart';
import '../models/language.dart';
import '../providers/favorites_provider.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/tap_scale.dart';

/// FAVORİLER SEKMESİ: Yıldızlanan çevirilerin listesi.
///
/// Favoriler cihazda kalıcı saklanır (internetsiz). Bir favoriye
/// dokununca çeviri ekranına yüklenir; kaydırmadan silme ve kopyalama
/// aksiyonları vardır.
class FavoritesScreen extends StatelessWidget {
  /// Bir favori seçildiğinde Çeviri sekmesine dönmek için çağrılır.
  final VoidCallback onOpenTranslate;

  const FavoritesScreen({super.key, required this.onOpenTranslate});

  /// Favoriyi çeviri ekranına yükler.
  void _loadFavorite(BuildContext context, FavoriteTranslation fav) {
    final translation = context.read<TranslationProvider>();

    final source = appLanguageFromBcp(fav.sourceCode);
    final target = appLanguageFromBcp(fav.targetCode);
    if (source != null) translation.setSourceLanguage(source);
    if (target != null) translation.setTargetLanguage(target);

    // Metni yerleştir — listener tetiklenir ve (paketler hazırsa)
    // çeviri otomatik yeniden yapılır.
    translation.textController.text = fav.sourceText;

    onOpenTranslate();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Favoriler',
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
              'Yıldızladığınız çeviriler burada saklanır — internetsiz '
              'erişebilirsiniz.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: favorites.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: favorites.items.length,
                    itemBuilder: (context, index) {
                      final fav = favorites.items[index];
                      return _FavoriteCard(
                        favorite: fav,
                        index: index,
                        onTap: () => _loadFavorite(context, fav),
                        onDelete: () => favorites.remove(fav),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Hiç favori yokken gösterilen boş durum.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border,
              size: 56, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          const Text(
            'Henüz favori yok',
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
              'Bir çeviriyi kaydetmek için sonuç kartındaki '
              'yıldız (☆) butonuna dokunun.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek bir favori kartı (beyaz kart, koyu metin).
class _FavoriteCard extends StatelessWidget {
  final FavoriteTranslation favorite;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FavoriteCard({
    required this.favorite,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final source = appLanguageFromBcp(favorite.sourceCode);
    final target = appLanguageFromBcp(favorite.targetCode);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 40),
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
                    // Dil çifti etiketi: "İngilizce → Türkçe"
                    Text(
                      '${source?.flag ?? ''} ${source?.displayName ?? favorite.sourceCode}'
                      '  →  '
                      '${target?.flag ?? ''} ${target?.displayName ?? favorite.targetCode}',
                      style: const TextStyle(
                        color: kInkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      favorite.sourceText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kInkMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      favorite.translatedText,
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

              // Sağ aksiyonlar: kopyala + sil
              Column(
                children: [
                  IconButton(
                    tooltip: 'Çeviriyi kopyala',
                    icon:
                        const Icon(Icons.copy, size: 18, color: kInkMuted),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: favorite.translatedText));
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
                    tooltip: 'Favoriden sil',
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
