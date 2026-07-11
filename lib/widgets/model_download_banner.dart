import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';
import 'primary_button.dart';

/// DİL İNDİRME YÖNETİMİ: Model indirme uyarı bandı (banner).
///
/// Seçili dil çiftinin modelleri cihazda hazırsa HİÇBİR ŞEY göstermez.
/// Modellerden en az biri eksikse: koyu füme kart içinde uyarı mesajı +
/// turuncu "İndir" butonu gösterir. İndirme sürerken spinner gösterir.
class ModelDownloadBanner extends StatelessWidget {
  const ModelDownloadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();

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
                  color: kNavyLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kAccentOrange.withValues(alpha: 0.4),
                  ),
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
                        color: kAccentOrange,
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
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Turuncu indirme butonu / ilerleme göstergesi
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
                                color: kAccentOrange,
                              ),
                            )
                          : PrimaryButton(
                              key: const ValueKey('download-button'),
                              icon: Icons.download,
                              label: 'İndir',
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
