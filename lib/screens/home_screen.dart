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
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Çeviri'),
        centerTitle: true,
        actions: [
          // Dil paketlerini yönetme (indir/sil) ekranını açar.
          IconButton(
            tooltip: 'Dil paketlerini yönet',
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () => ModelManagerSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        // Küçük ekranlarda klavye açılınca taşmayı önlemek için kaydırılabilir.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
    );
  }
}

/// Provider'daki hata mesajını (varsa) gösteren küçük yardımcı widget.
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage();

  @override
  Widget build(BuildContext context) {
    final error =
        context.select<TranslationProvider, String?>((p) => p.errorMessage);
    if (error == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
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
    );
  }
}
