import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';

/// DİL İNDİRME YÖNETİMİ: Model indirme uyarı bandı (banner).
///
/// Seçili dil çiftinin modelleri cihazda hazırsa HİÇBİR ŞEY göstermez.
/// Modellerden en az biri eksikse: uyarı mesajı + "İndir" butonu gösterir.
/// İndirme sürerken ilerleme göstergesi (spinner) gösterir.
///
/// Görünür/gizli geçişi ile içindeki ikon/aksiyon değişimleri ani değil,
/// [AnimatedSize] + [AnimatedSwitcher] ile yumuşak geçişlidir.
class ModelDownloadBanner extends StatelessWidget {
  const ModelDownloadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final visible = !provider.isReadyToTranslate;

    // Durum hâlâ kontrol ediliyorsa küçük bir bekleme göstergesi yeterli.
    final isChecking = provider.sourceModelStatus == ModelStatus.checking ||
        provider.targetModelStatus == ModelStatus.checking;

    // Herhangi bir model şu anda indiriliyor mu?
    final isDownloading =
        provider.sourceModelStatus == ModelStatus.downloading ||
            provider.targetModelStatus == ModelStatus.downloading;

    // Eksik olan dillerin adlarını mesaj için topla.
    final missing = <String>[
      if (provider.sourceModelStatus != ModelStatus.downloaded)
        provider.sourceLanguage.displayName,
      if (provider.targetModelStatus != ModelStatus.downloaded)
        provider.targetLanguage.displayName,
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: !visible
            ? const SizedBox.shrink(key: ValueKey('hidden'))
            : Container(
                key: const ValueKey('visible'),
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: Icon(
                        isDownloading
                            ? Icons.downloading
                            : Icons.cloud_download_outlined,
                        key: ValueKey(isDownloading),
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Bilgilendirme metni
                    Expanded(
                      child: Text(
                        isChecking
                            ? 'Dil paketleri kontrol ediliyor...'
                            : isDownloading
                                ? 'Dil paketi indiriliyor, lütfen bekleyin...'
                                : 'Offline çeviri için ${missing.join(" ve ")} '
                                    'dil paketi indirilmeli.',
                        style:
                            TextStyle(color: colorScheme.onSecondaryContainer),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // İndirme butonu / ilerleme göstergesi
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: (isDownloading || isChecking)
                          ? const SizedBox(
                              key: ValueKey('progress'),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                strokeCap: StrokeCap.round,
                              ),
                            )
                          : FilledButton.icon(
                              key: const ValueKey('download-button'),
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('İndir'),
                              onPressed: provider.downloadMissingModels,
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
