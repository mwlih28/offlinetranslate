import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';

/// "Kaynak dili otomatik algıla" anahtarı (Google Çeviri'deki "Dili
/// Algıla" özelliğine benzer). Açıkken yazılan metnin dili tespit edilip
/// kaynak dil otomatik olarak o dile ayarlanır — algılanan dilin modeli
/// henüz inmemişse mevcut model indirme banner'ı normal şekilde devreye
/// girer (sanki kullanıcı elle seçmiş gibi, ayrı bir akış yazılmadı).
class AutoDetectToggle extends StatelessWidget {
  const AutoDetectToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(Icons.auto_awesome,
              size: 16, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kaynak dili otomatik algıla',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: provider.autoDetectSource,
            activeThumbColor: kAccentOrange,
            onChanged: provider.setAutoDetectSource,
          ),
        ],
      ),
    );
  }
}
