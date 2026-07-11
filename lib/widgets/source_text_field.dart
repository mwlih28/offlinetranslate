import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';

/// ORTA KISIM: Kullanıcının çevrilecek metni yazdığı geniş metin alanı.
///
/// Sağ alt köşesinde metni temizleyen (✕) buton bulunur.
class SourceTextField extends StatelessWidget {
  const SourceTextField({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Geniş, çok satırlı metin girişi
        TextField(
          controller: provider.textController,
          maxLines: 6,
          minLines: 6,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Çevrilecek metni buraya yazın...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            // Temizleme butonu metnin üzerine binmesin diye sağ-alt boşluk.
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          ),
        ),

        // Sağ alt köşedeki temizleme (✕) butonu — sadece metin varken görünür.
        Positioned(
          right: 8,
          bottom: 8,
          child: ListenableBuilder(
            listenable: provider.textController,
            builder: (context, _) {
              if (provider.textController.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Metni temizle',
                icon: const Icon(Icons.close),
                onPressed: provider.clearText,
              );
            },
          ),
        ),
      ],
    );
  }
}
