import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        icon: Icons.camera_alt,
                        label: 'Fotoğraf Çek',
                        onPressed: () => camera.capture(
                          source: translation.sourceLanguage,
                          target: translation.targetLanguage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SecondaryButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Galeriden Seç',
                        onPressed: () => camera.capture(
                          source: translation.sourceLanguage,
                          target: translation.targetLanguage,
                          imageSource: ImageSource.gallery,
                        ),
                      ),
                    ),
                  ],
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: kAccentOrange),
              const SizedBox(height: 10),
              Text(
                'Metin taranıyor ve çevriliyor...',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ],
          )
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

/// İkincil (turuncu dolgu olmayan) aksiyon butonu — "Galeriden Seç" gibi
/// birincil olmayan aksiyonlar için [PrimaryButton]'ın soluk eşleniği.
class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Çekilen fotoğrafı, üzerine tanınan her metin bloğunun çevirisini
/// bindirerek gösterir. `BoxFit.fill` kullanılır ki fotoğrafın gösterilen
/// genişlik/yükseklik oranı bilinsin ve ML Kit'in verdiği piksel
/// koordinatları (kutular) bağımsız X/Y ölçek çarpanlarıyla doğrudan
/// dönüştürülebilsin (letterbox ofseti hesaplamaya gerek kalmaz).
///
/// Her kutu TAM OPAK bir zeminle çizilir (orijinal metnin "hayalet" gibi
/// altından görünmesini önlemek için) ve yazı tipi boyutu, metnin kutuya
/// tam oturması için [_fitFontSize] ile hesaplanır — sabit/varsayılan
/// punto yerine her kutu için özel olarak büyütülüp küçültülür. Kutular,
/// büyükten küçüğe sıralanıp çizilir ki küçük/iç içe kutular büyük
/// kutuların ALTINDA kalmasın.
class _OverlayedPhoto extends StatefulWidget {
  final CameraTranslateProvider camera;

  const _OverlayedPhoto({required this.camera});

  @override
  State<_OverlayedPhoto> createState() => _OverlayedPhotoState();
}

class _OverlayedPhotoState extends State<_OverlayedPhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _OverlayedPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Yeni bir fotoğraf çekildiğinde giriş animasyonunu baştan oynat.
    if (oldWidget.camera.imagePath != widget.camera.imagePath) {
      _entranceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// [index]. kutu için kademeli giriş animasyonu (fade + hafif büyüme).
  Animation<double> _staggerFor(int index, int total) {
    final start = (index / (total + 1)).clamp(0.0, 0.7);
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intrinsic = widget.camera.imageIntrinsicSize;
    final imagePath = widget.camera.imagePath;
    if (intrinsic == null || imagePath == null) {
      return const SizedBox.shrink();
    }

    // Büyük kutular önce, küçük/iç içe kutular en son (Stack'te en üstte)
    // çizilsin ki küçük bir kutu büyük bir kutunun altında kaybolmasın.
    final sortedBlocks = [...widget.camera.blocks]..sort(
        (a, b) => (b.box.width * b.box.height)
            .compareTo(a.box.width * a.box.height));

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
            for (var i = 0; i < sortedBlocks.length; i++)
              _buildOverlayChip(
                block: sortedBlocks[i],
                scaleX: scaleX,
                scaleY: scaleY,
                animation: _staggerFor(i, sortedBlocks.length),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverlayChip({
    required OverlayBlock block,
    required double scaleX,
    required double scaleY,
    required Animation<double> animation,
  }) {
    const padding = EdgeInsets.symmetric(horizontal: 6, vertical: 3);
    final boxSize = Size(
      block.box.width * scaleX,
      block.box.height * scaleY,
    );
    final fontSize = _fitFontSize(
      text: block.translated,
      maxWidth: boxSize.width - padding.horizontal,
      maxHeight: boxSize.height - padding.vertical,
    );

    return Positioned(
      left: block.box.left * scaleX,
      top: block.box.top * scaleY,
      width: boxSize.width,
      height: boxSize.height,
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(animation),
          child: Container(
            alignment: Alignment.center,
            padding: padding,
            decoration: BoxDecoration(
              // Sabit bir renk (ör. lacivert kutu) yerine, o bölgenin
              // fotoğraftaki ORTALAMA rengiyle boyanır — orijinal metin
              // kapanır ama yama, arka planla (kağıt/tabela/duvar) uyumlu
              // olduğu için "yapıştırma" değil, ortama gömülü gibi durur.
              color: block.patchColor,
              borderRadius: BorderRadius.circular(3),
            ),
            // Google Lens/Translate tarzı: dolgu renkli yazı + zıt renkte
            // ince anahat (stroke) — hem açık hem koyu yamalarda okunaklı.
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  block.translated,
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize,
                    height: 1.15,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = fontSize / 7
                      ..color = block.isPatchLight
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  block.translated,
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: block.isPatchLight ? kInkDark : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Verilen [text]'in, [maxWidth]x[maxHeight] alanına (satır kaydırmalı
/// olarak) sığacağı en büyük yazı tipi boyutunu bulur — böylece her kutu
/// kendi boyutuna göre okunaklı bir puntoya sahip olur (sabit/varsayılan
/// punto yerine, ki bu büyük kutularda komik derecede küçük, küçük
/// kutularda ise taşan metne yol açıyordu).
double _fitFontSize({
  required String text,
  required double maxWidth,
  required double maxHeight,
  double maxFontSize = 24,
  double minFontSize = 9,
}) {
  if (maxWidth <= 0 || maxHeight <= 0) return minFontSize;

  for (var fontSize = maxFontSize; fontSize > minFontSize; fontSize -= 1) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, height: 1.15),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 6,
    )..layout(maxWidth: maxWidth);

    if (!painter.didExceedMaxLines && painter.height <= maxHeight) {
      return fontSize;
    }
  }
  return minFontSize;
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
