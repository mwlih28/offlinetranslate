import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import 'frosted_card.dart';

/// ORTA KISIM: Kullanıcının çevrilecek metni yazdığı buzlu cam kart.
///
/// Odaklanınca kartın kenarlığı yumuşakça vurgu rengine döner.
/// Sağ altta temizleme (✕) butonu, sol altta soluk karakter sayısı vardır.
///
/// [StatefulWidget] olmasının sebebi: odak durumunu izleyen [FocusNode].
class SourceTextField extends StatefulWidget {
  const SourceTextField({super.key});

  @override
  State<SourceTextField> createState() => _SourceTextFieldState();
}

class _SourceTextFieldState extends State<SourceTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Odak değişince kenarlık rengini güncellemek için yeniden çiz.
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final focused = _focusNode.hasFocus;

    return FrostedCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      elevated: true,
      // Odaklanınca kenarlık vurgu rengine döner (FrostedCard içindeki
      // AnimatedContainer sayesinde geçiş otomatik yumuşaktır).
      borderColor:
          focused ? colorScheme.primary.withValues(alpha: 0.65) : null,
      borderWidth: focused ? 1.6 : 1,
      child: Stack(
        children: [
          // Geniş, çok satırlı, çerçevesiz metin girişi
          TextField(
            controller: provider.textController,
            focusNode: _focusNode,
            maxLines: 6,
            minLines: 6,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Çevrilecek metni buraya yazın...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
              border: InputBorder.none,
              // Alt butonlar metnin üzerine binmesin diye alt boşluk.
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            ),
          ),

          // Sol alt: soluk karakter sayısı (sadece metin varken).
          Positioned(
            left: 16,
            bottom: 14,
            child: ListenableBuilder(
              listenable: provider.textController,
              builder: (context, _) {
                final length = provider.textController.text.length;
                return AnimatedOpacity(
                  opacity: length == 0 ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '$length karakter',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sağ alt: temizleme (✕) butonu — metin varken scale+fade ile
          // belirir, boşalınca aynı şekilde kaybolur.
          Positioned(
            right: 8,
            bottom: 6,
            child: ListenableBuilder(
              listenable: provider.textController,
              builder: (context, _) {
                final isEmpty = provider.textController.text.isEmpty;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: isEmpty
                      ? const SizedBox.shrink(key: ValueKey('no-clear'))
                      : IconButton(
                          key: const ValueKey('clear'),
                          tooltip: 'Metni temizle',
                          icon: const Icon(Icons.close),
                          onPressed: provider.clearText,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
