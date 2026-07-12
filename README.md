# 📱 Offline Çeviri Uygulaması (Flutter + Google ML Kit)

Google ML Kit **On-Device Translation** kullanarak **tamamen internetsiz (offline)** çalışan, Android ve iOS destekli bir çeviri uygulaması.

> ⚠️ Tek istisna: Dil paketlerinin (modellerin) **ilk indirilmesi** internet gerektirir. Paketler bir kez indirildikten sonra çeviri %100 offline çalışır — uçak modunda bile.

## ✨ Özellikler

- 🌐 12 dil desteği (Türkçe, İngilizce, Almanca, Fransızca, İspanyolca, İtalyanca, Rusça, Arapça, Japonca, Korece, Çince, Portekizce)
- 🔄 Kaynak/hedef dil seçimi ve tek dokunuşla dilleri takas etme (swap)
- 📦 Dil paketi yönetimi: indirme durumu kontrolü, "İndir" butonu, paket silme
- ⚡ Yazarken otomatik (debounce'lu) canlı çeviri
- 🧹 Metni temizleme ve 📋 çeviriyi panoya kopyalama
- 🎨 Material 3 tasarım + otomatik karanlık mod

---

## 🖥️ Bilgisayarınız Yoksa: Bulutta Derleme (PC/Mac Gerekmez)

Bu depo, `android/` ve `ios/` platform klasörleri **dahil olmak üzere** tamamen hazırdır. Bilgisayarınız olmasa bile, uygulamayı sadece telefon/tarayıcı üzerinden bulutta derleyip kurabilirsiniz:

### 🤖 Android → GitHub Actions (ücretsiz, hesap gerekmez)

Depoda `.github/workflows/build-android.yml` zaten tanımlı. Her push'ta veya elle tetiklendiğinde GitHub'ın bulut sunucusunda APK derlenir:

1. GitHub'da bu depoya gidin → **Actions** sekmesi.
2. "Android APK Derle" iş akışını görün; bitince açılan sayfanın en altındaki **Artifacts** bölümünden `offline-ceviri-android-apk` dosyasını indirin (zip içinde `.apk` var).
3. Telefonunuzda "Bilinmeyen kaynaklardan yükleme"ye izin verip APK'yı açarak kurun.

Bunun için **hiçbir hesap veya ödeme gerekmez** — sadece GitHub deposu yeterli.

### 🍏 iOS → Codemagic (imzalı IPA + TestFlight, Mac gerekmez)

Apple, imzasız bir uygulamanın gerçek iPhone'a kurulmasına **izin vermez** (bu CI sağlayıcısından bağımsız, Apple'ın kuralı). Bu nedenle iOS için bir **Apple Developer hesabı** (yıllık 99$) şarttır — ama sertifika/profil oluşturma dahil her adım tarayıcıdan yapılabilir, Mac'e ihtiyacınız yoktur:

1. https://codemagic.io adresine GitHub hesabınızla giriş yapın, bu depoyu ekleyin. Codemagic, depodaki `codemagic.yaml` dosyasını otomatik algılar.
2. **Apple Developer** hesabınızla App Store Connect üzerinden bir "API Key" oluşturun (Apple'ın kendi web sitesinden, telefon tarayıcısından bile yapılabilir).
3. Codemagic panelinde **Teams → Integrations → Apple Developer Portal** kısmına bu API anahtarını `codemagic` adıyla ekleyin.
4. **Teams → Code signing identities** kısmından Android için bir keystore oluşturun (tek tıkla).
5. Codemagic'te "Start new build" ile `ios-workflow`'u çalıştırın — sertifika/profil otomatik oluşturulur, imzalı IPA üretilir ve **TestFlight'a otomatik yüklenir**. TestFlight uygulamasından telefonunuza kurarsınız.

> 💡 Codemagic'in ücretsiz katmanı ayda 500 dakika bulut derleme süresi verir — küçük bir proje için fazlasıyla yeterli.

---

## 💻 Bilgisayarınız Varsa: Yerel Kurulum

### 1️⃣ Gereksinimler

| Araç | Sürüm |
|---|---|
| Flutter SDK | 3.27+ (Dart 3.6+) |
| Android | minSdkVersion **21+** (Android 5.0) — proje varsayılanı **24** |
| iOS | Deployment target **15.5+**, Xcode 15.3+ |

Flutter kurulu değilse: https://docs.flutter.dev/get-started/install — kurulumdan sonra `flutter doctor` ile her şeyin yeşil olduğunu doğrulayın.

### 2️⃣ Projeyi Çalıştırma

`android/` ve `ios/` klasörleri **bu depoda zaten hazır** — ayrıca `flutter create` çalıştırmanıza gerek yoktur:

```bash
git clone <bu-deponun-adresi>
cd offlinetranslate
flutter pub get
flutter run
```

### 3️⃣ pubspec.yaml (Paketler)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Cihaz üzerinde (on-device) offline çeviri motoru
  google_mlkit_translation: ^0.14.0

  # Durum yönetimi (UI ↔ iş mantığı ayrımı için)
  provider: ^6.1.5

  cupertino_icons: ^1.0.8
```

### 4️⃣ Android Ayarları (bu depoda uygulanmış durumda)

- `android/app/build.gradle.kts` → `minSdk = flutter.minSdkVersion` (varsayılan **24**, ML Kit'in istediği 21'in üzerinde).
- `android/app/src/main/AndroidManifest.xml` → `INTERNET` izni eklendi (**sadece dil paketi indirmek için**; çevirinin kendisi offline):

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Dil modelleri APK'ya gömülmez; kullanıcı uygulama içinden indirir (~30 MB/dil), bu yüzden uygulama boyutu küçük kalır.

### 5️⃣ iOS Ayarları (bu depoda uygulanmış durumda)

- `ios/Runner.xcodeproj/project.pbxproj` → `IPHONEOS_DEPLOYMENT_TARGET = 15.5` olarak ayarlandı (ML Kit gereksinimi).
- Bu proje Flutter'ın güncel **Swift Package Manager** entegrasyonunu kullanır; ayrı bir `Podfile`/`pod install` adımı gerekmez. (Eğer bir eski Flutter/Xcode sürümüyle CocoaPods hatası alırsanız: `flutter config --enable-swift-package-manager=false` ile CocoaPods'a geri dönüp `cd ios && pod install --repo-update` çalıştırabilirsiniz.)
- ML Kit yalnızca 64-bit mimarileri destekler (arm64 + x86_64) — gerçek cihaz ve Apple Silicon simülatörde sorunsuz çalışır.
- Kamera/mikrofon kullanılmadığı için `Info.plist`'e özel bir izin eklemeye gerek yoktur.

## 6️⃣ Mimari

**Durum yönetimi için `Provider` seçildi** (setState yerine). Sebep: Kullanıcı arayüzü ile çeviri iş mantığının tamamen ayrılması istendi; `setState` tüm mantığı widget'ın içine gömerken, Provider ile iş mantığı bağımsız ve test edilebilir sınıflarda yaşar.

Katmanlar:

```
lib/
├── main.dart                          # Giriş noktası, Material 3 tema, Provider kurulumu
├── models/
│   └── language.dart                  # Desteklenen diller (TranslateLanguage + Türkçe ad + bayrak)
├── services/
│   └── translation_service.dart       # 🧠 İŞ MANTIĞI: ML Kit çeviri + model indir/sil/kontrol
│                                      #    (UI'dan %100 bağımsız — Flutter import etmez)
├── providers/
│   └── translation_provider.dart      # 🔄 DURUM: ChangeNotifier — UI ile servis arasındaki köprü
├── screens/
│   └── home_screen.dart               # Ana ekran düzeni
└── widgets/                           # 🎨 ARAYÜZ: küçük, tek sorumluluklu parçalar
    ├── language_selector.dart         # İki dropdown + swap (⇄) butonu
    ├── model_download_banner.dart     # Model eksikse uyarı + "İndir" butonu
    ├── model_manager_sheet.dart       # Tüm dil paketlerini yönetme (indir/sil) ekranı
    ├── source_text_field.dart         # Metin girişi + temizleme (✕) butonu
    └── translation_result_card.dart   # Gri arka planlı sonuç alanı + kopyala butonu
```

Veri akışı:

```
Kullanıcı yazdı → TranslationProvider (500ms debounce)
              → TranslationService.translate() → ML Kit (cihaz üzerinde)
              → sonuç → notifyListeners() → UI güncellenir
```

### Offline çeviri mantığı nasıl çalışır?

1. Uygulama açılışında `TranslationProvider`, tüm dillerin model durumunu `OnDeviceTranslatorModelManager.isModelDownloaded()` ile kontrol eder.
2. Seçili dil çiftinden herhangi birinin modeli cihazda yoksa, arayüzde bir **uyarı bandı + "İndir" butonu** görünür ve çeviri devre dışı kalır.
3. "İndir" ile `downloadModel(bcpCode, isWifiRequired: false)` çağrılır — model (~30 MB) cihaza kaydedilir.
4. Her iki model de hazır olduğunda çeviri, `OnDeviceTranslator.translateText()` ile **tamamen cihaz üzerinde** yapılır. İnternet kapalıyken de çalışır.
5. Kullanıcı, sağ üstteki ikon ile açılan yönetim ekranından istediği paketi silebilir (`deleteModel`).

## 7️⃣ Offline Testi

1. Uygulamayı internete bağlıyken açın.
2. Kaynak ve hedef dili seçin (örn: İngilizce → Türkçe) ve banner'daki **İndir** butonuna basın.
3. İndirme bittikten sonra cihazı **uçak moduna** alın.
4. Metin yazın — çeviri internetsiz çalışmaya devam eder. ✈️✅

## ❓ Sık Karşılaşılan Sorunlar

| Sorun | Çözüm |
|---|---|
| GitHub Actions'da Android derlemesi kırmızı (❌) | Actions sekmesinden log'a bakın; genelde `flutter analyze` hatasıdır, PR/commit ile düzeltin |
| Codemagic'te iOS imzalama hatası | Apple Developer hesabınızın aktif olduğundan ve API Key'in doğru "Integrations" adıyla (`codemagic`) eklendiğinden emin olun |
| Release APK'da model inmiyor | `AndroidManifest.xml`'de `INTERNET` izninin olduğunu kontrol edin (4. adım) |
| Çeviri butonu/sonucu gelmiyor | Her İKİ dilin paketinin de indirildiğinden emin olun (sağ üst ikon → Dil Paketleri) |
| Yerelde iOS pod hatası | Swift Package Manager kullanıldığından `pod install` gerekmez; sorun sürerse CocoaPods'a geçin (5. adımdaki not) |
| Release APK'da model indirirken `NullPointerException: getClass() on null object` | **ÇÖZÜLDÜ** — aşağıdaki bölüme bakın. R8/ProGuard minifikasyonu kapatıldı (`isMinifyEnabled = false`). |

### ✅ Çözülmüş Sorun: R8 Minifikasyonu ML Kit'in Reflection Kodunu Bozuyordu

Gerçek cihazlarda (Xiaomi tablet, Samsung Galaxy S23 — farklı marka/ağ/hesap) model indirme şu hatayla başarısız oluyordu:

```
java.lang.NullPointerException: Attempt to invoke virtual method
'java.lang.Class java.lang.Object.getClass()' on a null object reference
```

**Kesin kök neden** (native stack trace'te doğrulandı — obfuske sınıf adları `a3.b.B`, `b1.a.p` ve `r8-map-id-...` etiketi görüldü): **Flutter'ın kendi Gradle eklentisi, `android/app/build.gradle.kts` içinde HİÇBİR YERDE görünmeden, release derlemeleri için R8 kod küçültme/gizlemeyi (minifikasyon) varsayılan olarak açıyor** (`FlutterPlugin.kt` içinde `releaseBuildType.isMinifyEnabled = true`). Projede ML Kit/Play Hizmetleri için özel bir ProGuard "keep" kuralı olmadığından, R8 bu kütüphanelerin reflection tabanlı iç sınıflarını yeniden adlandırıp koddaki dinamik sınıf/metot aramalarını kırıyordu.

Denenip **elenen** yanlış teoriler (kayıt için):
- ❌ Paket sürümü sorunu değildi (`google_mlkit_translation` 0.13.1 ↔ 0.14.0)
- ❌ Google Play Hizmetleri'nin eksikliği/güncel olmaması değildi (cihazlarda mevcut, sertifikalı, güncel)
- ❌ Android 14'ün broadcast receiver kuralı değildi
- ❌ Play Hizmetleri'nin paylaşılan kütüphanelerini (`play-services-basement` vb.) zorla güncelleme işe yaramadı

**Çözüm** (`android/app/build.gradle.kts`):
```kotlin
buildTypes {
    release {
        isMinifyEnabled = false
    }
}
```

Ayrıca teşhis sürecinde, plugin'in native hata raporlamasının stack trace hiç içermediği (sadece `e.toString()` gönderiyordu) fark edildi; bu yüzden `third_party/google_mlkit_commons/` altında **yamalı bir yerel kopya** tutuluyor (`dependency_overrides` ile bağlı) — hata raporlarında artık gerçek native stack trace görünüyor, bu ileride başka sorunların da hızlı teşhis edilmesini sağlar.
