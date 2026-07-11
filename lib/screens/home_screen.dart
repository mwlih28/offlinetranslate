import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/frosted_card.dart';
import '../widgets/language_selector.dart';
import '../widgets/model_download_banner.dart';
import '../widgets/model_manager_sheet.dart';
import '../widgets/source_text_field.dart';
import '../widgets/tap_scale.dart';
import '../widgets/translation_result_card.dart';

/// ANA EKRAN: Tüm arayüz parçalarını bir araya getirir.
///
/// Düzen (yukarıdan aşağıya):
///  1. Özel başlık satırı (gradyan "Offline Çeviri" + paket yönetim butonu)
///  2. Dil seçimi satırı (kaynak ⇄ hedef)
///  3. Model indirme banner'ı (gerekliyse)
///  4. Kaynak metin girişi (temizleme butonlu)
///  5. Çeviri sonucu kartı (kopyalama butonlu)
///
/// Arkada [AnimatedBackground] (süzülen ışık küreleri) durur; tüm kartlar
/// buzlu cam ([FrostedCard]) görünümündedir. Bölümler ekran açılırken
/// KADEMELİ olarak (her biri bir öncekinden biraz sonra) fade+kayma ile
/// belirir — tek [AnimationController]'dan [Interval] eğrileriyle türetilir
/// ve Provider güncellemelerinden etkilenmez (bir kez oynar).
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
    final theme = Theme.of(context);

    return Scaffold(
      // Zemin AnimatedBackground tarafından çizilir.
      body: AnimatedBackground(
        child: SafeArea(
          // Küçük ekranlarda klavye açılınca taşmayı önlemek için
          // kaydırılabilir.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1) Özel başlık satırı
                _staggered(
                  0,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 0, 20),
                    child: Row(
                      children: [
                        // Gradyan renkli uygulama başlığı
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              kAccentGradient.createShader(bounds),
                          child: Text(
                            'Offline Çeviri',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white, // ShaderMask tabanı.
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Dil paketlerini yönetme (indir/sil) butonu
                        TapScale(
                          onTap: () => ModelManagerSheet.show(context),
                          child: Tooltip(
                            message: 'Dil paketlerini yönet',
                            child: FrostedCard(
                              padding: const EdgeInsets.all(10),
                              borderRadius: 16,
                              child: Icon(
                                Icons.download_for_offline_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
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

                // 5) Çevrilecek metin girişi
                _staggered(3, const SourceTextField()),
                const SizedBox(height: 16),

                // 6) Çeviri sonucu
                _staggered(4, const TranslationResultCard()),
              ],
            ),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

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
          : Padding(
              key: const ValueKey('error'),
              padding: const EdgeInsets.only(top: 12),
              child: FrostedCard(
                padding: const EdgeInsets.all(12),
                borderRadius: 20,
                tint: colorScheme.errorContainer.withValues(alpha: 0.65),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        error,
                        style:
                            TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
