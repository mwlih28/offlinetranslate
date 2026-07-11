import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/model_download_banner.dart';
import '../widgets/model_manager_sheet.dart';
import '../widgets/source_text_field.dart';
import '../widgets/translation_result_card.dart';

/// ANA EKRAN: Tüm arayüz parçalarını bir araya getirir.
///
/// Düzen (yukarıdan aşağıya):
///  1. AppBar (başlık + dil paketi yönetim butonu)
///  2. Dil seçimi satırı (kaynak ⇄ hedef)
///  3. Model indirme banner'ı (gerekliyse)
///  4. Kaynak metin girişi (temizleme butonlu)
///  5. Çeviri sonucu kartı (kopyalama butonlu)
///
/// [StatefulWidget] olmasının tek sebebi: içerik bir kez, ekran açılırken
/// yumuşak bir fade + yukarı kayma animasyonuyla belirsin diye. Bu animasyon
/// Provider'daki durum değişikliklerinden ETKİLENMEZ (sadece initState'te
/// bir kez çalışır), böylece her çeviri güncellemesinde tekrar oynamaz.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeIn);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Çeviri'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          // Dil paketlerini yönetme (indir/sil) ekranını açar.
          IconButton(
            tooltip: 'Dil paketlerini yönet',
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () => ModelManagerSheet.show(context),
          ),
        ],
      ),
      body: Container(
        // Arka planda çok hafif bir gradyan — düz/tek renk yerine
        // ekrana derinlik hissi katar, abartıya kaçmadan.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.10),
            ],
          ),
        ),
        child: SafeArea(
          // Küçük ekranlarda klavye açılınca taşmayı önlemek için kaydırılabilir.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1) Dil seçimi: [Kaynak] ⇄ [Hedef]
                    const LanguageSelector(),

                    // 2) Model eksikse indirme uyarısı + "İndir" butonu
                    const ModelDownloadBanner(),

                    // 3) Hata mesajı (varsa)
                    const _ErrorMessage(),
                    const SizedBox(height: 16),

                    // 4) Çevrilecek metin girişi
                    const SourceTextField(),
                    const SizedBox(height: 16),

                    // 5) Çeviri sonucu
                    const TranslationResultCard(),
                  ],
                ),
              ),
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
          : Container(
              key: const ValueKey('error'),
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
