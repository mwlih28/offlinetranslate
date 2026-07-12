import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/language.dart';
import '../services/ocr_service.dart';
import '../services/translation_service.dart';

/// Fotoğraf üzerinde tanınan tek bir metin bloğunun konumu + orijinal ve
/// çevrilmiş metni. Ekran, bu bloğun [box]'ını fotoğrafın gösterildiği
/// alana ölçekleyip üzerine [translated]'ı bindirir.
class OverlayBlock {
  final Rect box;
  final String original;
  final String translated;

  const OverlayBlock({
    required this.box,
    required this.original,
    required this.translated,
  });
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
