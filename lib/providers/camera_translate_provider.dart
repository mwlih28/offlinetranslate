import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/language.dart';
import '../services/ocr_service.dart';
import '../services/translation_service.dart';

/// Fotoğraf üzerinde tanınan tek bir metin bloğunun konumu + orijinal ve
/// çevrilmiş metni. Ekran, bu bloğun [box]'ını fotoğrafın gösterildiği
/// alana ölçekleyip üzerine [translated]'ı bindirir.
///
/// [patchColor], o bölgenin fotoğraftaki ORTALAMA rengidir — orijinal
/// metnin üzerini kapatan yama, sabit bir renk yerine arka planla
/// (kağıt/duvar/tabela her ne ise) uyumlu olsun diye kullanılır.
class OverlayBlock {
  final Rect box;
  final String original;
  final String translated;
  final Color patchColor;

  const OverlayBlock({
    required this.box,
    required this.original,
    required this.translated,
    required this.patchColor,
  });

  /// Yama rengi açık mı? (Yazı ve anahat rengini buna göre seçiyoruz.)
  bool get isPatchLight => patchColor.computeLuminance() > 0.5;
}

/// KAMERA İLE ÇEVİRİ — DURUM YÖNETİMİ
///
/// Fotoğraf çekme (image_picker) → metin tanıma (OcrService) → her blok
/// için çeviri (mevcut TranslationService) adımlarını yürütür. Yeni bir
/// çeviri mantığı YAZILMAZ; mevcut `TranslationService.translate()` aynen
/// yeniden kullanılır.
class CameraTranslateProvider extends ChangeNotifier {
  final OcrService _ocr;
  final TranslationService _translation;
  final ImagePicker _picker;

  CameraTranslateProvider({
    OcrService? ocrService,
    TranslationService? translationService,
    ImagePicker? imagePicker,
  })  : _ocr = ocrService ?? OcrService(),
        _translation = translationService ?? TranslationService(),
        _picker = imagePicker ?? ImagePicker();

  String? _imagePath;
  ui.Size? _imageIntrinsicSize;
  List<OverlayBlock> _blocks = [];
  bool _isBusy = false;
  String? _error;

  String? get imagePath => _imagePath;
  ui.Size? get imageIntrinsicSize => _imageIntrinsicSize;
  List<OverlayBlock> get blocks => _blocks;
  bool get isBusy => _isBusy;
  String? get error => _error;

  /// Fotoğraf çeker, metni tanır ve her blok için çeviri yapar.
  Future<void> capture({
    required AppLanguage source,
    required AppLanguage target,
  }) async {
    final script = scriptFor(source);
    if (script == null) {
      _error = '${source.displayName} için kamera ile metin tanıma '
          'desteklenmiyor.';
      notifyListeners();
      return;
    }

    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return; // Kullanıcı iptal etti.

    _isBusy = true;
    _error = null;
    _imagePath = photo.path;
    _blocks = [];
    notifyListeners();

    try {
      final bytes = await photo.readAsBytes();
      final decoded = await ui.instantiateImageCodec(bytes);
      final frame = await decoded.getNextFrame();
      _imageIntrinsicSize = ui.Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );

      final recognized = await _ocr.recognize(photo.path, script);

      // Yama renklerini fotoğrafın ham piksellerinden örnekleyebilmek için
      // görüntüyü bir kez RGBA byte dizisine çeviriyoruz.
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      final newBlocks = <OverlayBlock>[];
      for (final block in recognized.blocks) {
        final text = block.text.trim();
        if (text.isEmpty) continue;
        try {
          final translated = await _translation.translate(
            text: text,
            from: source.mlkitLanguage,
            to: target.mlkitLanguage,
          );
          newBlocks.add(OverlayBlock(
            box: block.boundingBox,
            original: text,
            translated: translated,
            patchColor: pixels == null
                ? const Color(0xFFE7EBF4)
                : _averageColor(
                    pixels,
                    frame.image.width,
                    frame.image.height,
                    block.boundingBox,
                  ),
          ));
        } catch (_) {
          // Bu blok çevrilemedi — diğer bloklar etkilenmesin diye atla.
        }
      }
      _blocks = newBlocks;

      if (_blocks.isEmpty) {
        _error = 'Fotoğrafta okunabilir bir metin bulunamadı.';
      }
    } catch (e) {
      _error = 'Fotoğraf işlenemedi: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Fotoğrafı ve sonuçları temizleyip başa döner ("Tekrar Çek").
  void reset() {
    _imagePath = null;
    _imageIntrinsicSize = null;
    _blocks = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocr.dispose();
    _translation.dispose();
    super.dispose();
  }
}

/// [rect] bölgesindeki piksellerin ORTALAMA rengini bulur — çeviri
/// yamasının arka planla (kağıt/duvar/tabela her ne ise) uyumlu bir renkte
/// olması için kullanılır ("içine boyanmış" gibi değil, ortama gömülü gibi
/// görünsün diye). Performans için tüm pikseller değil, bölge büyüklüğüne
/// göre aralıklı örnekleme yapılır.
Color _averageColor(
  ByteData pixels,
  int imageWidth,
  int imageHeight,
  Rect rect,
) {
  final left = rect.left.clamp(0, imageWidth - 1).floor();
  final top = rect.top.clamp(0, imageHeight - 1).floor();
  final right = rect.right.clamp(1, imageWidth).ceil();
  final bottom = rect.bottom.clamp(1, imageHeight).ceil();
  if (right <= left || bottom <= top) return const Color(0xFFE7EBF4);

  final area = (right - left) * (bottom - top);
  final step = math.max(1, math.sqrt(area / 400).floor());

  var rSum = 0, gSum = 0, bSum = 0, count = 0;
  for (var y = top; y < bottom; y += step) {
    for (var x = left; x < right; x += step) {
      final offset = (y * imageWidth + x) * 4;
      rSum += pixels.getUint8(offset);
      gSum += pixels.getUint8(offset + 1);
      bSum += pixels.getUint8(offset + 2);
      count++;
    }
  }
  if (count == 0) return const Color(0xFFE7EBF4);
  return Color.fromARGB(255, rSum ~/ count, gSum ~/ count, bSum ~/ count);
}
