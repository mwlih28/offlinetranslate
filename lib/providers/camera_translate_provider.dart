import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/language.dart';
import '../services/language_id_service.dart';
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
/// Fotoğraf çekme (image_picker) → metin tanıma (OcrService, birden çok
/// script denenerek) → dil algılama (LanguageIdService) → gerekirse model
/// indirme → her blok için çeviri (mevcut TranslationService) adımlarını
/// yürütür. Yeni bir çeviri mantığı YAZILMAZ; mevcut
/// `TranslationService.translate()` aynen yeniden kullanılır.
///
/// Kaynak dil kullanıcıdan ÖNCEDEN İSTENMEZ: fotoğraftaki metnin script'i
/// (Latin/Çince/Japonca/Korece) sırayla denenir, okunan metnin dili
/// [LanguageIdService] ile tespit edilir. Çeviri sekmesindeki mevcut
/// kaynak dil sadece bir İPUCU olarak kullanılır (script denemesine hangi
/// script'ten başlanacağını hızlandırır, algılama başarısız olursa yedek
/// olur) — Google Çeviri'nin kamera modundaki gibi.
class CameraTranslateProvider extends ChangeNotifier {
  final OcrService _ocr;
  final TranslationService _translation;
  final LanguageIdService _languageId;
  final ImagePicker _picker;

  CameraTranslateProvider({
    OcrService? ocrService,
    TranslationService? translationService,
    LanguageIdService? languageIdService,
    ImagePicker? imagePicker,
  })  : _ocr = ocrService ?? OcrService(),
        _translation = translationService ?? TranslationService(),
        _languageId = languageIdService ?? LanguageIdService(),
        _picker = imagePicker ?? ImagePicker();

  String? _imagePath;
  ui.Size? _imageIntrinsicSize;
  List<OverlayBlock> _blocks = [];
  bool _isBusy = false;
  String? _error;
  String? _statusMessage;
  AppLanguage? _detectedSource;

  String? get imagePath => _imagePath;
  ui.Size? get imageIntrinsicSize => _imageIntrinsicSize;
  List<OverlayBlock> get blocks => _blocks;
  bool get isBusy => _isBusy;
  String? get error => _error;

  /// İşlem sürerken gösterilecek adım açıklaması (ör. "Dil algılanıyor...").
  String? get statusMessage => _statusMessage;

  /// Son çekilen fotoğrafta otomatik olarak algılanan kaynak dil.
  AppLanguage? get detectedSource => _detectedSource;

  /// Fotoğraf çeker (kameradan ya da [imageSource] galeriden ise
  /// galeriden), metnin dilini otomatik algılar ve her blok için çeviri
  /// yapar. [sourceHint], Çeviri sekmesindeki o anki seçili kaynak dildir —
  /// hangi script'in önce deneneceğini hızlandırır ve algılama
  /// başarısız olursa yedek kaynak dil olarak kullanılır.
  Future<void> capture({
    required AppLanguage target,
    AppLanguage? sourceHint,
    ImageSource imageSource = ImageSource.camera,
  }) async {
    final photo = await _picker.pickImage(source: imageSource);
    if (photo == null) return; // Kullanıcı iptal etti.

    _isBusy = true;
    _error = null;
    _statusMessage = 'Metin taranıyor...';
    _imagePath = photo.path;
    _blocks = [];
    _detectedSource = null;
    notifyListeners();

    try {
      final bytes = await photo.readAsBytes();
      final decoded = await ui.instantiateImageCodec(bytes);
      final frame = await decoded.getNextFrame();
      _imageIntrinsicSize = ui.Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );

      // Hangi script'in denenceği: önce ipucu dilin script'i (varsa),
      // ardından kalan desteklenen script'ler. İlk okunabilir sonucu
      // veren kazanır — böylece fotoğraftaki gerçek dil, ipucu dille
      // aynı script'te olmasa bile (ör. ipucu Türkçe ama fotoğraf
      // Japonca) doğru okunabilir.
      final hintScript = sourceHint == null ? null : scriptFor(sourceHint);
      final scriptsToTry = <TextRecognitionScript>{
        if (hintScript != null) hintScript,
        TextRecognitionScript.latin,
        TextRecognitionScript.chinese,
        TextRecognitionScript.japanese,
        TextRecognitionScript.korean,
      };

      RecognizedText? recognized;
      for (final script in scriptsToTry) {
        final result = await _ocr.recognize(photo.path, script);
        if (result.text.trim().length >= 2) {
          recognized = result;
          break;
        }
      }

      if (recognized == null || recognized.blocks.isEmpty) {
        _error = 'Fotoğrafta okunabilir bir metin bulunamadı. Desteklenen '
            'diller: Türkçe, İngilizce, Almanca, Fransızca, İspanyolca, '
            'İtalyanca, Portekizce, Çince, Japonca, Korece.';
        return;
      }

      // Okunan metnin dilini algıla (fotoğraf başına TEK bir kaynak dil
      // varsayılır — gerçekçi kullanım genelde tek dilli bir belge/tabela).
      _statusMessage = 'Dil algılanıyor...';
      notifyListeners();

      final rawCode = await _languageId.identify(recognized.text);
      AppLanguage? source;
      if (rawCode != null) {
        source = appLanguageFromBcp(rawCode.split('-').first.toLowerCase());
        if (source == null) {
          _error = 'Algılanan dil ("$rawCode") şu an desteklenmiyor.';
          return;
        }
      } else {
        // Dil algılanamadıysa (metin çok kısa/belirsiz), ipucu dille
        // devam et (en azından bir tahminle).
        source = sourceHint;
      }

      if (source == null) {
        _error = 'Metnin dili algılanamadı.';
        return;
      }
      if (source == target) {
        _error = 'Algılanan dil (${source.displayName}) hedef dille aynı. '
            'Farklı bir hedef dil seçin.';
        return;
      }

      _detectedSource = source;
      notifyListeners();

      // Algılanan dilin modeli cihazda yoksa otomatik indir (mevcut
      // indirme mantığı reused ediliyor, sadece kamera akışından tetiklenir).
      final hasModel = await _translation.isModelDownloaded(
        source.mlkitLanguage,
      );
      if (!hasModel) {
        _statusMessage = '${source.displayName} dil paketi indiriliyor...';
        notifyListeners();
        final downloaded = await _translation.downloadModel(
          source.mlkitLanguage,
        );
        if (!downloaded) {
          _error = '${source.displayName} dil paketi indirilemedi. '
              'İnternet bağlantınızı kontrol edip tekrar deneyin.';
          return;
        }
      }

      _statusMessage = 'Çevriliyor...';
      notifyListeners();

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
      _statusMessage = null;
      notifyListeners();
    }
  }

  /// Fotoğrafı ve sonuçları temizleyip başa döner ("Tekrar Çek").
  void reset() {
    _imagePath = null;
    _imageIntrinsicSize = null;
    _blocks = [];
    _error = null;
    _statusMessage = null;
    _detectedSource = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocr.dispose();
    _translation.dispose();
    _languageId.dispose();
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
