import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/camera_translate_provider.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';

/// KAMERA SEKMESİ: Fotoğraf çekip tanınan metnin ÜZERİNE çevirisini
/// bindirir (Google Translate'in kamera modu gibi).
///
/// Dil seçimini KENDİSİ yapmaz — mevcut [TranslationProvider]'ın seçili
/// kaynak/hedef dilini kullanır (tekrarlı UI'dan kaçınmak için).
class CameraTranslateScreen extends StatelessWidget {
  const CameraTranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final translation = context.watch<TranslationProvider>();
    final camera = context.watch<CameraTranslateProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 18),
              child: Text(
                'Kamera ile Çeviri',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Expanded(
              child: _CameraBody(translation: translation, camera: camera),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraBody extends StatelessWidget {
  final TranslationProvider translation;
  final CameraTranslateProvider camera;

  const _CameraBody({required this.translation, required this.camera});

  @override
  Widget build(BuildContext context) {
    // Modeller hazır değilse fotoğraf çekmeye izin verme.
    if (!translation.isReadyToTranslate) {
      return _InfoCard(
        icon: Icons.cloud_download_outlined,
        title: 'Önce dil paketlerini indirin',
        message: 'Kamera ile çeviri için ${translation.sourceLanguage.displayName} '
            've ${translation.targetLanguage.displayName} dil paketlerinin '
            'cihazda indirilmiş olması gerekir. Çeviri sekmesindeki "İndir" '
            'butonunu kullanın.',
      );
    }

    // Kaynak dilin script'i OCR tarafından desteklenmiyorsa (Arapça/Rusça).
    if (scriptFor(translation.sourceLanguage) == null) {
      return _InfoCard(
        icon: Icons.info_outline,
        title: 'Bu dil için kamera desteklenmiyor',
        message: '${translation.sourceLanguage.displayName} metnini kamerayla '
            'tanıma şu an desteklenmiyor. Desteklenen kaynak diller: Türkçe, '
            'İngilizce, Almanca, Fransızca, İspanyolca, İtalyanca, '
            'Portekizce, Çince, Japonca, Korece.',
      );
    }

    if (camera.imagePath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Bir fotoğraf çekin, üzerindeki metnin çevirisi\n'
              'doğrudan fotoğrafın üzerinde gösterilsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 24),
            if (camera.isBusy)
              const CircularProgressIndicator(color: kAccentOrange)
            else
              PrimaryButton(
                icon: Icons.camera_alt,
                label: 'Fotoğraf Çek',
                onPressed: () => camera.capture(
                  source: translation.sourceLanguage,
                  target: translation.targetLanguage,
                ),
              ),
            if (camera.error != null) ...[
              const SizedBox(height: 16),
              Text(
                camera.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFB4B4)),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _OverlayedPhoto(camera: camera),
          ),
        ),
        const SizedBox(height: 16),
        if (camera.isBusy)
          const CircularProgressIndicator(color: kAccentOrange)
        else
          PrimaryButton(
            icon: Icons.refresh,
            label: 'Tekrar Çek',
            onPressed: camera.reset,
          ),
        if (camera.error != null) ...[
          const SizedBox(height: 12),
          Text(
            camera.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFFB4B4)),
          ),
        ],
      ],
    );
  }
}

/// Çekilen fotoğrafı, üzerine tanınan her metin bloğunun çevirisini
/// bindirerek gösterir. `BoxFit.fill` kullanılır ki fotoğrafın gösterilen
/// genişlik/yükseklik oranı bilinsin ve ML Kit'in verdiği piksel
/// koordinatları (kutular) bağımsız X/Y ölçek çarpanlarıyla doğrudan
/// dönüştürülebilsin (letterbox ofseti hesaplamaya gerek kalmaz).
class _OverlayedPhoto extends StatelessWidget {
  final CameraTranslateProvider camera;

  const _OverlayedPhoto({required this.camera});

  @override
  Widget build(BuildContext context) {
    final intrinsic = camera.imageIntrinsicSize;
    final imagePath = camera.imagePath;
    if (intrinsic == null || imagePath == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final renderedWidth = constraints.maxWidth;
        final renderedHeight = constraints.maxHeight;
        final scaleX = renderedWidth / intrinsic.width;
        final scaleY = renderedHeight / intrinsic.height;

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath),
              fit: BoxFit.fill,
              width: renderedWidth,
              height: renderedHeight,
            ),
            for (final block in camera.blocks)
              Positioned(
                left: block.box.left * scaleX,
                top: block.box.top * scaleY,
                width: block.box.width * scaleX,
                height: block.box.height * scaleY,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: kNavy.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      block.translated,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kNavyLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kAccentOrange.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: kAccentOrange),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }
}
