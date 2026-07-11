import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/model_download_banner.dart';
import '../widgets/offline_badge.dart';
import '../widgets/source_text_field.dart';
import '../widgets/translation_result_card.dart';

/// ÇEVİRİ SEKMESİ (ana ekran).
///
/// Düzen (yukarıdan aşağıya):
///  1. Başlık ("Offline Çeviri")
///  2. Dil seçimi satırı (kaynak ⇄ hedef çipleri)
///  3. Model indirme banner'ı (gerekliyse) + hata mesajı
///  4. Bembeyaz kaynak metin kartı
///  5. Açık lavanta çeviri sonucu kartı
///  6. Yeşil "Çevrimdışı Modu Aktif" rozeti
///
/// Bölümler ekran açılırken KADEMELİ olarak (her biri bir öncekinden
/// biraz sonra) fade+kayma ile belirir — tek [AnimationController]'dan
/// [Interval] eğrileriyle türetilir ve yalnızca bir kez oynar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// [index]. bölüm için kademeli giriş animasyonu üretir:
  /// her bölüm bir öncekinden ~%12 gecikmeyle başlar.
  Widget _staggered(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 0.8);
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Küçük ekranlarda klavye açılınca taşmayı önlemek için
      // kaydırılabilir.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) Başlık
            _staggered(
              0,
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 18),
                child: Text(
                  'Offline Çeviri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            // 2) Dil seçimi: [Kaynak] ⇄ [Hedef]
            _staggered(1, const LanguageSelector()),

            // 3) Model eksikse indirme uyarısı + "İndir" butonu
            _staggered(2, const ModelDownloadBanner()),

            // 4) Hata mesajı (varsa)
            const _ErrorMessage(),
            const SizedBox(height: 16),

            // 5) Çevrilecek metin girişi (bembeyaz kart)
            _staggered(3, const SourceTextField()),
            const SizedBox(height: 14),

            // 6) Çeviri sonucu (lavanta kart)
            _staggered(4, const TranslationResultCard()),
            const SizedBox(height: 18),

            // 7) Çevrimdışı durum rozeti (ortalanmış)
            _staggered(5, const Center(child: OfflineBadge())),
          ],
        ),
      ),
    );
  }
}

/// Provider'daki hata mesajını (varsa) gösteren küçük yardımcı widget.
///
/// Ani gösterip/gizlemek yerine yukarıdan kayarak+solarak belirir/kaybolur.
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage();

  @override
  Widget build(BuildContext context) {
    final error =
        context.select<TranslationProvider, String?>((p) => p.errorMessage);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: error == null
          ? const SizedBox.shrink(key: ValueKey('no-error'))
          : Container(
              key: const ValueKey('error'),
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5C2B33),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFFB4B4)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(color: Color(0xFFFFD9D9)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
