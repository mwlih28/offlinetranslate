import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Uygulamanın ana vurgu gradyanı (indigo → menekşe).
/// Swap butonu, "İndir" butonları ve başlık ShaderMask'lerinde kullanılır.
const kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
);

/// BUZLU CAM (glassmorphism) KART.
///
/// Arkasındaki canlı arka planı bulanıklaştıran ([BackdropFilter]),
/// yarı saydam dolgulu ve ince parlak kenarlıklı yüzey. Uygulamadaki
/// tüm kartlar bunu kullanır — görsel tutarlılık tek yerden sağlanır.
///
/// İç [AnimatedContainer] sayesinde [borderColor]/[tint] değişimleri
/// (örn. metin alanı odaklanınca kenarlığın renklenmesi) otomatik olarak
/// yumuşak geçişlidir.
class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// Dolgunun rengi. Verilmezse temaya göre yarı saydam varsayılan seçilir.
  final Color? tint;

  /// Kenarlık rengi. Verilmezse temaya göre ince parlak varsayılan seçilir.
  final Color? borderColor;
  final double borderWidth;

  /// Kartın altına yumuşak gölge eklensin mi?
  final bool elevated;

  const FrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.tint,
    this.borderColor,
    this.borderWidth = 1,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fill = tint ??
        (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.55));
    final edge = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.70));

    return Container(
      // Gölge, kırpmanın (ClipRRect) DIŞINDA kalmalı; yoksa kesilir.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: padding,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: edge, width: borderWidth),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// GRADYAN DOLGULU HAP BUTON ("İndir" vb. ana aksiyonlar için).
/// Basınca hafifçe küçülür (TapScale mantığı çağıran tarafta eklenir
/// gerekirse); kendisi gradyan + gölge + ikon/etiket düzenini sağlar.
class GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const GradientButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: kAccentGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
