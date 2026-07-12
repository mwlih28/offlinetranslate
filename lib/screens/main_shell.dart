import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';
import 'camera_translate_screen.dart';
import 'downloads_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// UYGULAMA KABUĞU: Alt gezinme çubuğu + sekme sayfaları.
///
/// Sekmeler: Çeviri · İndirilenler (indirilen paket sayısı rozetli) ·
/// Favoriler · Ayarlar. Sayfalar [IndexedStack] içinde tutulur, böylece
/// sekmeler arasında geçişte durumları (yazılan metin vb.) kaybolmaz.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final translation = context.watch<TranslationProvider>();

    // İndirilenler sekmesindeki rozet: cihazda hazır paket sayısı.
    final downloadedCount = supportedLanguages
        .where((l) => translation.statusOf(l) == ModelStatus.downloaded)
        .length;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          const DownloadsScreen(),
          // Bir favoriye dokunulduğunda Çeviri sekmesine dön.
          FavoritesScreen(
              onOpenTranslate: () => setState(() => _index = 0)),
          const SettingsScreen(),
          const CameraTranslateScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Çeviri',
          ),
          NavigationDestination(
            // İndirilen paket sayısı rozeti (mockup'taki turuncu rozet).
            icon: Badge(
              isLabelVisible: downloadedCount > 0,
              backgroundColor: kAccentOrange,
              label: Text('$downloadedCount'),
              child: const Icon(Icons.download_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: downloadedCount > 0,
              backgroundColor: kAccentOrange,
              label: Text('$downloadedCount'),
              child: const Icon(Icons.download),
            ),
            label: 'İndirilenler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Favoriler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Kamera',
          ),
        ],
      ),
    );
  }
}
