import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/language.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

/// Bir dil modelinin cihazdaki indirilme durumu.
enum ModelStatus {
  /// Durum henüz kontrol ediliyor.
  checking,

  /// Model cihazda YOK — indirilmesi gerekiyor.
  notDownloaded,

  /// Model şu anda indiriliyor.
  downloading,

  /// Model cihazda hazır — offline çeviri yapılabilir.
  downloaded,
}

/// DURUM YÖNETİMİ (State Management) KATMANI
///
/// [ChangeNotifier] tabanlı bu Provider, arayüzün (UI) ihtiyaç duyduğu tüm
/// durumu tutar ve iş mantığı için [TranslationService]'i kullanır.
/// UI, ML Kit'e asla doğrudan dokunmaz — her şey bu köprü üzerinden geçer.
class TranslationProvider extends ChangeNotifier {
  final TranslationService _service;
  final TtsService _tts;
  final SpeechService _speech;

  static const _sttNoticeShownKey = 'stt_notice_shown';

  TranslationProvider({
    TranslationService? service,
    TtsService? ttsService,
    SpeechService? speechService,
  })  : _service = service ?? TranslationService(),
        _tts = ttsService ?? TtsService(),
        _speech = speechService ?? SpeechService() {
    // Kullanıcı yazdıkça çeviriyi otomatik tetiklemek için
    // TextField controller'ını dinliyoruz.
    textController.addListener(_onTextChanged);

    // TTS gerçekten konuşmayı bitirdiğinde (ya da iptal/hata olduğunda)
    // isSpeaking durumunu kapat.
    _tts.onFinished = () {
      _isSpeaking = false;
      notifyListeners();
    };

    // Açılışta tüm desteklenen dillerin model durumlarını kontrol et.
    refreshAllModelStatuses();
  }

  // ---------------------------------------------------------------------------
  // DURUM (STATE) ALANLARI
  // ---------------------------------------------------------------------------

  /// Kaynak metin alanının controller'ı. Provider'da tutulur ki
  /// swap (dil değiştirme) ve temizleme işlemleri metni güncelleyebilsin.
  final TextEditingController textController = TextEditingController();

  /// Seçili kaynak dil (varsayılan: İngilizce).
  AppLanguage _sourceLanguage = supportedLanguages[1]; // İngilizce

  /// Seçili hedef dil (varsayılan: Türkçe).
  AppLanguage _targetLanguage = supportedLanguages[0]; // Türkçe

  /// Tüm desteklenen dillerin model durumları (banner ve yönetim ekranı için).
  final Map<TranslateLanguage, ModelStatus> _modelStatuses = {
    for (final lang in supportedLanguages)
      lang.mlkitLanguage: ModelStatus.checking,
  };

  /// Çeviri sonucu.
  String _translatedText = '';

  /// Şu anda bir çeviri işlemi sürüyor mu?
  bool _isTranslating = false;

  /// Kullanıcıya gösterilecek hata mesajı (varsa).
  String? _errorMessage;

  /// Canlı çeviri için debounce zamanlayıcısı:
  /// Kullanıcı yazmayı bıraktıktan 500ms sonra çeviri tetiklenir.
  Timer? _debounce;

  /// Eski (geciken) çeviri sonuçlarının yenilerin üzerine yazmasını
  /// önlemek için istek sayacı.
  int _requestId = 0;

  /// Çeviri sonucu şu anda sesli okunuyor mu?
  bool _isSpeaking = false;

  /// Mikrofon şu anda dinliyor mu?
  bool _isListening = false;

  // ---------------------------------------------------------------------------
  // GETTER'LAR (UI bu değerleri okur)
  // ---------------------------------------------------------------------------

  AppLanguage get sourceLanguage => _sourceLanguage;
  AppLanguage get targetLanguage => _targetLanguage;
  String get translatedText => _translatedText;
  bool get isTranslating => _isTranslating;
  String? get errorMessage => _errorMessage;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;

  /// Verilen dilin model durumu.
  ModelStatus statusOf(AppLanguage language) =>
      _modelStatuses[language.mlkitLanguage] ?? ModelStatus.checking;

  ModelStatus get sourceModelStatus => statusOf(_sourceLanguage);
  ModelStatus get targetModelStatus => statusOf(_targetLanguage);

  /// Seçili dil çiftinin HER İKİ modeli de cihazda hazır mı?
  /// (Çeviri ancak bu durumda yapılabilir.)
  bool get isReadyToTranslate =>
      sourceModelStatus == ModelStatus.downloaded &&
      targetModelStatus == ModelStatus.downloaded;

  // ---------------------------------------------------------------------------
  // DİL SEÇİMİ
  // ---------------------------------------------------------------------------

  /// Kaynak dili değiştirir. Yeni dil hedef dille aynıysa dilleri takas eder.
  void setSourceLanguage(AppLanguage language) {
    if (language == _sourceLanguage) return;
    if (language == _targetLanguage) {
      swapLanguages();
      return;
    }
    _sourceLanguage = language;
    _afterLanguageChange();
  }

  /// Hedef dili değiştirir. Yeni dil kaynak dille aynıysa dilleri takas eder.
  void setTargetLanguage(AppLanguage language) {
    if (language == _targetLanguage) return;
    if (language == _sourceLanguage) {
      swapLanguages();
      return;
    }
    _targetLanguage = language;
    _afterLanguageChange();
  }

  /// Kaynak ve hedef dilleri takas eder (⇄ butonu).
  /// Ayrıca mevcut çeviri sonucunu kaynak metin alanına taşır,
  /// böylece kullanıcı ters yönde çeviriye kaldığı yerden devam eder.
  void swapLanguages() {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;

    if (_translatedText.isNotEmpty) {
      // Eski çeviri sonucu yeni kaynak metin olur, eski kaynak metin de
      // anında görsel geri bildirim olarak sonuç alanına yazılır.
      // Not: textController'ı güncellemek listener'ı tetikler ve
      // debounce sonunda yeni yönde çeviri otomatik yapılır.
      final oldTranslated = _translatedText;
      _translatedText = textController.text;
      textController.text = oldTranslated;
    }

    _afterLanguageChange();
  }

  /// Dil değişikliği sonrası ortak işlemler:
  /// eski sonucu geçersiz kılma + yeniden çeviri.
  void _afterLanguageChange() {
    _errorMessage = null;
    notifyListeners();
    _scheduleTranslation();
  }

  // ---------------------------------------------------------------------------
  // METİN İŞLEMLERİ
  // ---------------------------------------------------------------------------

  /// TextField her değiştiğinde çağrılır (controller listener'ı).
  void _onTextChanged() {
    _scheduleTranslation();
  }

  /// Kaynak metni ve çeviri sonucunu temizler (✕ butonu).
  void clearText() {
    _debounce?.cancel();
    textController.clear(); // Listener tetiklenir ama boş metin çevrilmez.
    _translatedText = '';
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ÇEVİRİ MANTIĞI (Debounce'lu canlı çeviri)
  // ---------------------------------------------------------------------------

  /// Çeviriyi hemen değil, kullanıcı yazmayı bıraktıktan 500ms sonra başlatır.
  /// Böylece her tuş vuruşunda gereksiz çeviri yapılmaz.
  void _scheduleTranslation() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _translateNow);
  }

  /// Asıl çeviri işlemini yapar.
  Future<void> _translateNow() async {
    final text = textController.text.trim();

    // Boş metin → sonucu temizle, çeviri yapma.
    if (text.isEmpty) {
      if (_translatedText.isNotEmpty) {
        _translatedText = '';
        notifyListeners();
      }
      return;
    }

    // Modeller hazır değilse çeviri yapılamaz (banner kullanıcıyı uyarır).
    if (!isReadyToTranslate) return;

    // Bu isteğe bir numara ver; işlem bitince hâlâ güncel istek mi diye bak.
    final myRequestId = ++_requestId;

    _isTranslating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.translate(
        text: text,
        from: _sourceLanguage.mlkitLanguage,
        to: _targetLanguage.mlkitLanguage,
      );

      // Bu istek beklerken kullanıcı yeni bir şey yazdıysa sonucu çöpe at.
      if (myRequestId != _requestId) return;

      _translatedText = result;
    } catch (e) {
      if (myRequestId != _requestId) return;
      _errorMessage = 'Çeviri sırasında bir hata oluştu: $e';
    } finally {
      if (myRequestId == _requestId) {
        _isTranslating = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SESLİ OKUMA (TTS)
  // ---------------------------------------------------------------------------

  /// Çeviri sonucunu hedef dilde sesli okur.
  Future<void> speakResult() async {
    if (_translatedText.isEmpty) return;
    _isSpeaking = true;
    notifyListeners();
    try {
      await _tts.speak(text: _translatedText, bcpCode: _targetLanguage.bcpCode);
    } catch (e) {
      _isSpeaking = false;
      _errorMessage = 'Sesli okuma başarısız: $e';
      notifyListeners();
    }
    // NOT: _isSpeaking = false ataması burada YAPILMAZ — gerçek bitiş anı
    // constructor'da bağlanan _tts.onFinished callback'i ile belirlenir
    // (speak() Future'ı ses kuyruğa alınır alınmaz tamamlanır, konuşma
    // bitince değil).
  }

  // ---------------------------------------------------------------------------
  // SESLE YAZMA (STT)
  // ---------------------------------------------------------------------------

  /// İlk mikrofon kullanımında bir kez gösterilecek offline-dürüstlüğü
  /// uyarısının daha önce gösterilip gösterilmediğini kontrol eder.
  Future<bool> shouldShowSttNotice() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_sttNoticeShownKey) ?? false);
  }

  /// Yukarıdaki uyarının bir daha gösterilmemesi için işaretler.
  Future<void> markSttNoticeShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sttNoticeShownKey, true);
  }

  /// Mikrofonla dinlemeye başlar; tanınan söz [textController]'a yazılır —
  /// bu, mevcut debounce+otomatik çeviri akışını DEĞİŞTİRMEDEN tetikler.
  Future<void> startListening() async {
    final available = await _speech.initialize();
    if (!available) {
      _errorMessage = 'Mikrofon kullanılamıyor. Cihaz ayarlarından mikrofon '
          'iznini kontrol edin.';
      notifyListeners();
      return;
    }

    _isListening = true;
    _errorMessage = null;
    notifyListeners();

    await _speech.listen(
      localeId: ttsLocaleByBcp[_sourceLanguage.bcpCode] ?? 'en-US',
      onResult: (text) {
        textController.text = text;
      },
    );
  }

  /// Dinlemeyi durdurur.
  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // MODEL YÖNETİMİ (UI'nın çağırdığı metotlar)
  // ---------------------------------------------------------------------------

  /// Tüm desteklenen dillerin model durumlarını cihazdan sorgular.
  ///
  /// Her dilin kontrolü kendi try/catch'i içinde yapılır: bir dilde hata
  /// oluşsa bile (örn. cihazda Google Play Hizmetleri ile ilgili bir sorun)
  /// döngü durmaz ve o dil sonsuza dek [ModelStatus.checking]'te kilitli
  /// kalmaz — güvenli varsayım olarak "indirilmedi" kabul edilir, böylece
  /// kullanıcı en azından "İndir" butonunu görüp tekrar deneyebilir.
  Future<void> refreshAllModelStatuses() async {
    for (final lang in supportedLanguages) {
      // Zaten indirilmekte olan bir modelin durumunu ezme.
      if (_modelStatuses[lang.mlkitLanguage] == ModelStatus.downloading) {
        continue;
      }
      try {
        final downloaded =
            await _service.isModelDownloaded(lang.mlkitLanguage);
        _modelStatuses[lang.mlkitLanguage] =
            downloaded ? ModelStatus.downloaded : ModelStatus.notDownloaded;
      } catch (e) {
        _modelStatuses[lang.mlkitLanguage] = ModelStatus.notDownloaded;
      }
      // Her dil sonuçlandıkça hemen bildir; tümünün bitmesini beklemez.
      notifyListeners();
    }
  }

  /// Verilen dilin modelini indirir ve durumu günceller.
  Future<void> downloadModel(AppLanguage language) async {
    _modelStatuses[language.mlkitLanguage] = ModelStatus.downloading;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.downloadModel(language.mlkitLanguage);
      _modelStatuses[language.mlkitLanguage] =
          success ? ModelStatus.downloaded : ModelStatus.notDownloaded;
      if (!success) {
        _errorMessage = '${language.displayName} modeli indirilemedi. '
            'Wi-Fi/mobil veri bağlantınızı kontrol edip tekrar deneyin.';
      }
    } catch (e) {
      // Gerçek hata sebebini kullanıcıya yansıt (jenerik mesaj yerine) —
      // böylece asıl sorunun ağ mı, Google Play Hizmetleri mi, yoksa
      // depolama mı olduğu teşhis edilebilir.
      _modelStatuses[language.mlkitLanguage] = ModelStatus.notDownloaded;
      _errorMessage = '${language.displayName} modeli indirilemedi: '
          '${_describeError(e)}. ${_hintFor(e)}';
    }
    notifyListeners();

    // Modeller hazır olduysa bekleyen metni hemen çevir.
    _scheduleTranslation();
  }

  /// Verilen dilin modelini cihazdan siler ve durumu günceller.
  Future<void> deleteModel(AppLanguage language) async {
    try {
      await _service.deleteModel(language.mlkitLanguage);
      _modelStatuses[language.mlkitLanguage] = ModelStatus.notDownloaded;
    } catch (e) {
      _errorMessage = '${language.displayName} modeli silinemedi: $e';
    }
    notifyListeners();
  }

  /// Bir hatayı kullanıcıya gösterilecek okunabilir bir metne çevirir.
  ///
  /// [PlatformException] ise (ML Kit'in native tarafından gelen hatalar hep
  /// bu tiptedir) mesajın yanına native stack trace'in İLK BİRKAÇ SATIRINI
  /// da ekler. NOT: pub.dev'deki orijinal `google_mlkit_commons` hatayı
  /// Flutter'a `stacktrace` alanı OLMADAN iletiyordu (sadece `e.toString()`);
  /// bu yüzden `third_party/google_mlkit_commons`'taki yamalı kopyada
  /// stack trace artık `details` alanına ekleniyor — asıl kaynağımız o.
  String _describeError(Object error) {
    if (error is PlatformException) {
      final base = error.message ?? error.code;
      final trace = (error.details as String?) ?? error.stacktrace;
      if (trace == null || trace.isEmpty) return base;

      // İlk 8 satır genelde hatayı fırlatan native sınıf/metodu göstermeye
      // yeter; tamamını göstermek banner'ı çok büyütür.
      final firstLines = trace.split('\n').take(8).join('\n');
      return '$base\n\n[Native stack trace]\n$firstLines';
    }
    return error.toString();
  }

  /// Hatanın metnine bakarak kullanıcıya somut bir sonraki adım önerir.
  ///
  /// NOT: "getClass() ... null object reference" deseninin cihazdaki Google
  /// Play Hizmetleri'nin eksik/güncel olmamasından kaynaklandığı teorisi
  /// denendi (Play Hizmetleri'ni güncelleme, önbellek/veri temizleme, temel
  /// Play Hizmetleri kütüphanelerini zorla güncel sürüme çekme) ama hiçbiri
  /// düzeltmedi — bu yüzden artık bu iddiayı kesin bir çözüm gibi
  /// sunmuyoruz. Yukarıdaki native stack trace, asıl teşhis için gösterilir.
  String _hintFor(Object error) {
    return 'Yukarıdaki native stack trace\'i (varsa) geliştiriciye iletin — '
        'kesin teşhis için Wi-Fi/mobil veri bağlantınızı kontrol edip '
        'tekrar deneyebilirsiniz.';
  }

  /// Seçili dil çiftinde eksik olan TÜM modelleri indirir ("İndir" butonu).
  Future<void> downloadMissingModels() async {
    if (sourceModelStatus == ModelStatus.notDownloaded) {
      await downloadModel(_sourceLanguage);
    }
    if (targetModelStatus == ModelStatus.notDownloaded) {
      await downloadModel(_targetLanguage);
    }
  }

  // ---------------------------------------------------------------------------
  // TEMİZLİK
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _debounce?.cancel();
    textController.removeListener(_onTextChanged);
    textController.dispose();
    _service.dispose(); // Native ML Kit kaynaklarını serbest bırak.
    _tts.dispose();
    _speech.stop();
    super.dispose();
  }
}
