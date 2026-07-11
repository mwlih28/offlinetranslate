import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:offlinetranslate/main.dart';
import 'package:offlinetranslate/providers/translation_provider.dart';

// NOT: Bu dosyada pumpAndSettle() yerine sabit süreli pump() kullanılıyor.
// Model indirme banner'ındaki CircularProgressIndicator sürekli dönen
// (indeterminate) bir animasyon olduğundan pumpAndSettle() "artık bekleyen
// kare yok" durumuna asla ulaşamaz ve zaman aşımına uğrar. Sabit süreli
// pump(), kendi geçiş animasyonlarımızın (300-900ms) bitmesi için yeterlidir.

void main() {
  setUp(() {
    // Favoriler deposu test ortamında boş bellek-içi değerlerle çalışsın.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Ana ekran açılır ve temel arayüz öğeleri görünür',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OfflineTranslateApp());
    await tester.pump(const Duration(milliseconds: 1000));

    // Başlık görünüyor mu?
    expect(find.text('Offline Çeviri'), findsOneWidget);

    // Metin girişi yer tutucusu görünüyor mu?
    expect(find.text('Çevrilecek metni buraya yazın...'), findsOneWidget);

    // Dilleri takas eden buton mevcut mu?
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

    // Alt gezinme sekmeleri mevcut mu?
    expect(find.text('Çeviri'), findsOneWidget);
    expect(find.text('İndirilenler'), findsOneWidget);
    expect(find.text('Favoriler'), findsOneWidget);
    expect(find.text('Ayarlar'), findsOneWidget);
  });

  testWidgets('Dil takas butonuna basınca kaynak/hedef diller yer değiştirir',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OfflineTranslateApp());
    await tester.pump(const Duration(milliseconds: 1000));

    final context = tester.element(find.byType(Scaffold).first);
    final provider = context.read<TranslationProvider>();

    final originalSource = provider.sourceLanguage;
    final originalTarget = provider.targetLanguage;

    // Swap butonuna bas ve animasyonun (dönüş + pop) bitmesini bekle.
    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pump(const Duration(milliseconds: 600));

    expect(provider.sourceLanguage, originalTarget);
    expect(provider.targetLanguage, originalSource);
  });

  testWidgets('Favoriler sekmesine geçince boş durum mesajı görünür',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OfflineTranslateApp());
    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.text('Favoriler'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Henüz favori yok'), findsOneWidget);
  });
}
