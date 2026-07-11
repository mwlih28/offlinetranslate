import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';

/// DİL İNDİRME YÖNETİMİ: Model indirme uyarı bandı (banner).
///
/// Seçili dil çiftinin modelleri cihazda hazırsa HİÇBİR ŞEY göstermez.
/// Modellerden en az biri eksikse: uyarı mesajı + "İndir" butonu gösterir.
/// İndirme sürerken ilerleme göstergesi (spinner) gösterir.
class ModelDownloadBanner extends StatelessWidget {
  const ModelDownloadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Her iki model de hazır → banner'a gerek yok.
    if (provider.isReadyToTranslate) {
      return const SizedBox.shrink();
    }

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

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isDownloading ? Icons.downloading : Icons.cloud_download_outlined,
            color: colorScheme.onSecondaryContainer,
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
              style: TextStyle(color: colorScheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(width: 8),

          // İndirme butonu / ilerleme göstergesi
          if (isDownloading || isChecking)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            FilledButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('İndir'),
              onPressed: provider.downloadMissingModels,
            ),
        ],
      ),
    );
  }
}
