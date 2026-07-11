import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';

/// ORTA KISIM: Kullanıcının çevrilecek metni yazdığı BEMBEYAZ kart.
///
/// Koyu lacivert zemin üzerinde en çok dikkat çeken yüzeydir (tasarım
/// dilinin ana ögesi). Odaklanınca kenarlığı turuncuya döner; sağ altta
/// temizleme (✕) butonu, sol altta soluk karakter sayısı vardır.
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
    final focused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focused ? kAccentOrange : Colors.transparent,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Geniş, çok satırlı, çerçevesiz metin girişi
          TextField(
            controller: provider.textController,
            focusNode: _focusNode,
            maxLines: 6,
            minLines: 6,
            textInputAction: TextInputAction.newline,
            cursorColor: kAccentOrange,
            style: const TextStyle(
              fontSize: 18,
              color: kInkDark,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              hintText: 'Çevrilecek metni buraya yazın...',
              hintStyle: TextStyle(color: kInkMuted),
              border: InputBorder.none,
              // Alt butonlar metnin üzerine binmesin diye alt boşluk.
              contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 48),
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
                    style: const TextStyle(fontSize: 12, color: kInkMuted),
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
                          color: kInkMuted,
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
