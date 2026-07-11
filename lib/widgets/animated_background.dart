import 'dart:math' as math;

import 'package:flutter/material.dart';

/// CANLI ARKA PLAN: Derin bir gradyan zemin üzerinde yavaşça (18 sn'lik
/// döngü) süzülen üç büyük, yumuşak ışık küresi ("blob") çizer.
///
/// Kürecikler [CustomPainter] ile tek katmanda, kenarları
/// [MaskFilter.blur] ile eritilerek çizilir — ayrı widget/filtre katmanları
/// olmadığı için ucuzdur. Üstteki buzlu cam kartlar ([FrostedCard]) bu
/// hareketi bulanıklaştırarak "premium" derinlik hissi verir.
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Sonsuz döngü: 0→1 arası ilerleyen zaman değeri (t) üretir.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Zemin gradyanı ve küre renkleri temaya göre seçilir.
    final baseColors = isDark
        ? const [Color(0xFF0B1020), Color(0xFF141A33)]
        : const [Color(0xFFEEF1FF), Color(0xFFFDFDFF)];
    final blobColors = isDark
        ? [
            const Color(0xFF6366F1).withValues(alpha: 0.38), // indigo
            const Color(0xFFA855F7).withValues(alpha: 0.28), // menekşe
            const Color(0xFF22D3EE).withValues(alpha: 0.20), // camgöbeği
          ]
        : [
            const Color(0xFF6366F1).withValues(alpha: 0.22),
            const Color(0xFFA855F7).withValues(alpha: 0.16),
            const Color(0xFF22D3EE).withValues(alpha: 0.14),
          ];

    return Stack(
      children: [
        // 1) Sabit zemin gradyanı
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: baseColors,
              ),
            ),
          ),
        ),

        // 2) Süzülen ışık küreleri (dokunuşları engellemesin, kendi
        //    katmanında boyansın)
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _BlobPainter(
                    t: _controller.value,
                    colors: blobColors,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 3) Asıl ekran içeriği
        widget.child,
      ],
    );
  }
}

/// Üç yumuşak küreyi sinüs/kosinüs yörüngelerinde çizen painter.
class _BlobPainter extends CustomPainter {
  final double t; // 0..1 arası döngü zamanı
  final List<Color> colors;

  _BlobPainter({required this.t, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final angle = 2 * math.pi * t;

    // Her kürenin farklı hızı/fazı vardır → düzensiz, doğal bir süzülme.
    final specs = [
      (speed: 1.0, phase: 0.0, cx: 0.20, cy: 0.15, r: 0.42),
      (speed: -0.7, phase: 2.1, cx: 0.85, cy: 0.35, r: 0.36),
      (speed: 0.5, phase: 4.2, cx: 0.45, cy: 0.90, r: 0.40),
    ];

    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      final a = angle * s.speed + s.phase;
      final center = Offset(
        size.width * (s.cx + 0.10 * math.sin(a)),
        size.height * (s.cy + 0.07 * math.cos(a * 1.3)),
      );
      final paint = Paint()
        ..color = colors[i % colors.length]
        // Kenarları eriterek "ışık küresi" görünümü verir.
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(center, size.shortestSide * s.r, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.colors != colors;
}
