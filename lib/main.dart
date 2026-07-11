import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/translation_provider.dart';
import 'screens/home_screen.dart';

void main() {
  // google_fonts'un çalışma zamanında ASLA internetten font indirmeye
  // çalışmamasını sağlar — fontlar derleme sırasında pakete gömülür.
  // Bu, uygulamanın "tamamen offline" garantisi için zorunludur.
  GoogleFonts.config.allowRuntimeFetching = false;

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
    final lightBase = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    );
    final darkBase = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
    );

    return ChangeNotifierProvider(
      // Provider oluşturulur oluşturulmaz model durumlarını kontrol etmeye başlar.
      create: (_) => TranslationProvider(),
      child: MaterialApp(
        title: 'Offline Çeviri',
        debugShowCheckedModeBanner: false,

        // MATERIAL 3 TEMASI + Manrope tipografisi.
        theme: lightBase.copyWith(
          textTheme: GoogleFonts.manropeTextTheme(lightBase.textTheme),
        ),

        // Karanlık mod desteği (sistem ayarını takip eder).
        darkTheme: darkBase.copyWith(
          textTheme: GoogleFonts.manropeTextTheme(darkBase.textTheme),
        ),
        themeMode: ThemeMode.system,

        home: const HomeScreen(),
      ),
    );
  }
}
