import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:offlinetranslate/main.dart';

void main() {
  testWidgets('Ana ekran açılır ve temel arayüz öğeleri görünür',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OfflineTranslateApp());
    await tester.pump();

    // AppBar başlığı görünüyor mu?
    expect(find.text('Offline Çeviri'), findsOneWidget);

    // Metin girişi yer tutucusu görünüyor mu?
    expect(find.text('Çevrilecek metni buraya yazın...'), findsOneWidget);

    // Dilleri takas eden buton mevcut mu?
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });
}
