import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/translation_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OfflineTranslateApp());
}

/// UYGULAMANIN KÖKÜ.
///
/// [ChangeNotifierProvider], [TranslationProvider]'ı widget ağacının en
/// üstüne yerleştirir; böylece tüm ekran ve widget'lar aynı duruma erişir.
class OfflineTranslateApp extends StatelessWidget {
  const OfflineTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Provider oluşturulur oluşturulmaz model durumlarını kontrol etmeye başlar.
      create: (_) => TranslationProvider(),
      child: MaterialApp(
        title: 'Offline Çeviri',
        debugShowCheckedModeBanner: false,

        // MATERIAL 3 TEMASI
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),

        // Karanlık mod desteği (sistem ayarını takip eder).
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,

        home: const HomeScreen(),
      ),
    );
  }
}
