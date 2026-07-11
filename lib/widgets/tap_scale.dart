import 'package:flutter/material.dart';

/// DOKUNMA MİKRO-ETKİLEŞİMİ: Basılı tutunca hafifçe küçülen, bırakınca
/// geri yaylanan sarmalayıcı. Uygulamadaki tüm tıklanabilir kart ve
/// butonlara "canlı" bir his vermek için kullanılır.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Basılıyken uygulanacak ölçek (1.0 = değişim yok).
  final double pressedScale;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
