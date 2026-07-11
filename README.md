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

## 1️⃣ Adım: Gereksinimler

| Araç | Sürüm |
|---|---|
| Flutter SDK | 3.27+ (Dart 3.6+) |
| Android | minSdkVersion **21+** (Android 5.0) |
| iOS | Deployment target **15.5+**, Xcode 15.3+ |

Flutter kurulu değilse: https://docs.flutter.dev/get-started/install — kurulumdan sonra `flutter doctor` ile her şeyin yeşil olduğunu doğrulayın.

## 2️⃣ Adım: Projeyi Oluşturma

Bu depo `lib/` kaynak kodunu ve `pubspec.yaml` dosyasını içerir. Platform klasörlerini (`android/`, `ios/`) kendi makinenizde üretmeniz gerekir:

```bash
git clone <bu-deponun-adresi>
cd offlinetranslate

# android/ ve ios/ klasörlerini mevcut projeye ekler:
flutter create . --platforms=android,ios --org com.example

# Paketleri indir:
flutter pub get
```

> `flutter create .` mevcut `lib/` ve `pubspec.yaml` dosyalarına DOKUNMAZ; sadece eksik platform dosyalarını üretir.

## 3️⃣ Adım: pubspec.yaml (Paketler)

Bu depodaki `pubspec.yaml` zaten hazırdır. Kullanılan güncel paketler:

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

## 4️⃣ Adım: Android Ayarları

### a) minSdkVersion kontrolü

`android/app/build.gradle.kts` (veya eski projelerde `build.gradle`) içinde `minSdk` en az **21** olmalı. Güncel Flutter sürümlerinde varsayılan zaten 21+ olduğundan çoğu zaman değişiklik gerekmez:

```kotlin
android {
    defaultConfig {
        minSdk = 21   // ML Kit Translation için minimum
    }
}
```

### b) İnternet izni (sadece model indirme için)

`android/app/src/main/AndroidManifest.xml` dosyasına, `<application>` etiketinin ÜSTÜNE ekleyin:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- SADECE dil paketlerinin ilk indirilmesi için gereklidir.
         Çevirinin kendisi tamamen offline çalışır. -->
    <uses-permission android:name="android.permission.INTERNET" />

    <application ...>
```

> 💡 Not: Debug modda Flutter bu izni otomatik ekler; ancak **release** APK/AAB için manifest'e elle eklenmesi şarttır.

### c) (İsteğe bağlı) Release boyut notu

Dil modelleri APK'ya gömülmez; kullanıcı uygulama içinden indirir (~30 MB/dil). Bu yüzden uygulama boyutu küçük kalır.

## 5️⃣ Adım: iOS Ayarları

### a) Minimum iOS sürümü

`ios/Podfile` dosyasının en üstündeki satırın yorumunu kaldırıp **15.5** yapın:

```ruby
platform :ios, '15.5'
```

Ayrıca Xcode'da `Runner > General > Minimum Deployments` değerini **15.5** yapın.

### b) Pod kurulumu

```bash
cd ios
pod install --repo-update
cd ..
```

> 💡 ML Kit yalnızca 64-bit mimarileri destekler (arm64 + x86_64). Gerçek cihazlarda ve Apple Silicon Mac simülatörlerinde sorunsuz çalışır.
>
> 💡 Kamera/mikrofon kullanılmadığı için `Info.plist`'e özel bir izin eklemeye **gerek yoktur**.

## 6️⃣ Adım: Mimari

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

## 7️⃣ Adım: Çalıştırma ve Offline Testi

```bash
# Bağlı cihaz/emülatörde çalıştır:
flutter run
```

**Offline çalıştığını doğrulamak için:**

1. Uygulamayı internete bağlıyken açın.
2. Kaynak ve hedef dili seçin (örn: İngilizce → Türkçe) ve banner'daki **İndir** butonuna basın.
3. İndirme bittikten sonra cihazı **uçak moduna** alın.
4. Metin yazın — çeviri internetsiz çalışmaya devam eder. ✈️✅

**Release derlemesi:**

```bash
flutter build apk --release        # Android
flutter build ios --release        # iOS (macOS + Xcode gerekir)
```

## ❓ Sık Karşılaşılan Sorunlar

| Sorun | Çözüm |
|---|---|
| Android'de `minSdkVersion` hatası | `android/app/build.gradle.kts` içinde `minSdk = 21` yapın |
| iOS'ta pod hatası | `Podfile`'da `platform :ios, '15.5'` satırının aktif olduğundan emin olun, sonra `pod install --repo-update` |
| Release APK'da model inmiyor | Manifest'e `INTERNET` izninin eklendiğini kontrol edin (4b adımı) |
| Çeviri butonu/sonucu gelmiyor | Her İKİ dilin paketinin de indirildiğinden emin olun (sağ üst ikon → Dil Paketleri) |
