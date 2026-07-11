import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/favorites_provider.dart';
import 'providers/translation_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_colors.dart';

void main() {
  // google_fonts'un çalışma zamanında ASLA internetten font indirmeye
  // çalışmamasını sağlar — fontlar derleme sırasında pakete gömülür.
  // Bu, uygulamanın "tamamen offline" garantisi için zorunludur.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const OfflineTranslateApp());
}

/// UYGULAMANIN KÖKÜ.
///
/// [MultiProvider] iki durum katmanını widget ağacının en üstüne koyar:
///  - [TranslationProvider]: çeviri + dil paketi durumu
///  - [FavoritesProvider]: kalıcı favori çeviriler
///
/// Tema: koyu lacivert zemin + beyaz kartlar + turuncu vurgu
/// (tasarım paleti lib/theme/app_colors.dart'tadır).
class OfflineTranslateApp extends StatelessWidget {
  const OfflineTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAccentOrange,
        brightness: Brightness.dark,
      ).copyWith(
        primary: kAccentOrange,
        surface: kNavy,
      ),
      scaffoldBackgroundColor: kNavy,
      // Dokunuşlarda modern parıltı efekti.
      splashFactory: InkSparkle.splashFactory,

      // Alt gezinme çubuğu: beyaz zemin, koyu ikonlar, turuncu seçim.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        height: 68,
        indicatorColor: kAccentOrange.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? kAccentOrange
                : kInkDark,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? kAccentOrange
                : kInkDark,
          ),
        ),
      ),
    );

    return MultiProvider(
      providers: [
        // Provider oluşturulur oluşturulmaz model durumlarını kontrol eder.
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
        // Favoriler cihaz depolamasından yüklenir.
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'Offline Çeviri',
        debugShowCheckedModeBanner: false,
        theme: base.copyWith(
          textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
        ),
        home: const MainShell(),
      ),
    );
  }
}
