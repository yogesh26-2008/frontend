import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    final islandBg = isDark ? const Color(0xFFF0F0EC) : const Color(0xFF1A1A1A);
    final islandText = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // 1. Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: isDark
                      ? [const Color(0xFF1C1C1F), const Color(0xFF050506)]
                      : [const Color(0xFFF8F8FA), const Color(0xFFE2E2E8)],
                ),
              ),
            ),
          ),

          // 2. Decorative Background Orbs
          _Orb(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            size: 300,
            top: 100,
            left: -50,
          ),
          _Orb(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
            size: 250,
            bottom: 150,
            right: -30,
          ),

          // 3. Frosted Glass Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.1)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ),

          // 4. Content
          SafeArea(
            child: Stack(
              children: [
                // Trandia Island (Centered Top)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _TrandiaIsland(
                      background: islandBg,
                      textColor: islandText,
                    ),
                  ),
                ),

                // Modern Curved Message Icon (Top Right)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 12),
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Open Chat
                      },
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: CustomPaint(
                          painter: _ModernMessageIconPainter(isDark: isDark),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3D Glass Infinity Button (Bottom Right)
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: _GlassInfinityButton(isDark: isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Modern Curved Message Icon Painter
// ─────────────────────────────────────────────
class _ModernMessageIconPainter extends CustomPainter {
  final bool isDark;
  const _ModernMessageIconPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 2;

    // Gradient shader for the icon
    final gradient = ui.Gradient.linear(
      Offset(cx - 14, cy - 12),
      Offset(cx + 14, cy + 12),
      isDark
          ? [const Color(0xFFFFFFFF), const Color(0xFFCCCCCC)]
          : [const Color(0xFF1A1A1A), const Color(0xFF555555)],
    );

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient;

    final thinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..shader = gradient;

    // Outer speech bubble — smooth rounded rectangle with tail
    final bubblePath = Path();
    const r = 5.0;
    const l = -12.0, t = -12.0, rr = 12.0, b = 6.0;

    bubblePath.moveTo(cx + l + r, cy + t);
    bubblePath.lineTo(cx + rr - r, cy + t);
    bubblePath.quadraticBezierTo(cx + rr, cy + t, cx + rr, cy + t + r);
    bubblePath.lineTo(cx + rr, cy + b - r);
    bubblePath.quadraticBezierTo(cx + rr, cy + b, cx + rr - r, cy + b);
    bubblePath.lineTo(cx + 2, cy + b);
    // Curved tail at bottom-left
    bubblePath.quadraticBezierTo(cx - 2, cy + b + 1, cx - 5, cy + b + 7);
    bubblePath.quadraticBezierTo(cx - 6, cy + b + 3, cx + l + r + 2, cy + b);
    bubblePath.lineTo(cx + l + r, cy + b);
    bubblePath.quadraticBezierTo(cx + l, cy + b, cx + l, cy + b - r);
    bubblePath.lineTo(cx + l, cy + t + r);
    bubblePath.quadraticBezierTo(cx + l, cy + t, cx + l + r, cy + t);
    bubblePath.close();

    canvas.drawPath(bubblePath, strokePaint);

    // Inner message lines
    canvas.drawLine(
      Offset(cx - 7, cy - 4),
      Offset(cx + 7, cy - 4),
      thinPaint,
    );
    canvas.drawLine(
      Offset(cx - 7, cy + 1),
      Offset(cx + 3, cy + 1),
      thinPaint,
    );
  }

  @override
  bool shouldRepaint(_ModernMessageIconPainter old) => old.isDark != isDark;
}

// ─────────────────────────────────────────────
// 3D Glass Infinity Button
// ─────────────────────────────────────────────
class _GlassInfinityButton extends StatefulWidget {
  final bool isDark;
  const _GlassInfinityButton({required this.isDark});

  @override
  State<_GlassInfinityButton> createState() => _GlassInfinityButtonState();
}

class _GlassInfinityButtonState extends State<_GlassInfinityButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1A1A1A);
    final glassColor = widget.isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);
    final borderColor = widget.isDark
        ? Colors.white.withOpacity(0.18)
        : Colors.black.withOpacity(0.12);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTapDown: (_) => _ctrl.forward(),
            onTapUp: (_) {
              _ctrl.reverse();
              HapticFeedback.lightImpact();
              // TODO: Button action
            },
            onTapCancel: () => _ctrl.reverse(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withOpacity(0.10 + _glow.value * 0.12),
                        blurRadius: 24 + _glow.value * 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Glass body
                ClipOval(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: glassColor,
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      child: CustomPaint(
                        painter: _InfinityPainter(
                          color: baseColor,
                          glowAmount: _glow.value,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top specular highlight (3D glass shine)
                Positioned(
                  top: 6,
                  child: Container(
                    width: 28,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(
                            widget.isDark ? 0.22 : 0.55,
                          ),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Infinity Symbol Painter
// ─────────────────────────────────────────────
class _InfinityPainter extends CustomPainter {
  final Color color;
  final double glowAmount;

  const _InfinityPainter({required this.color, this.glowAmount = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const a = 11.0; // half-width of one lobe
    const b = 7.0;  // half-height of one lobe

    // Glow layer (slightly thicker, translucent)
    if (glowAmount > 0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = color.withOpacity(0.18 * glowAmount)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(_infinityPath(cx, cy, a, b), glowPaint);
    }

    // Main infinity stroke
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withOpacity(0.90);

    canvas.drawPath(_infinityPath(cx, cy, a, b), paint);
  }

  Path _infinityPath(double cx, double cy, double a, double b) {
    // Lemniscate of Bernoulli approximated with cubic beziers
    final path = Path();
    // Left lobe
    path.moveTo(cx, cy);
    path.cubicTo(
      cx - a * 0.5, cy - b * 1.4,
      cx - a * 2.0, cy - b * 1.4,
      cx - a * 2.0, cy,
    );
    path.cubicTo(
      cx - a * 2.0, cy + b * 1.4,
      cx - a * 0.5, cy + b * 1.4,
      cx, cy,
    );
    // Right lobe
    path.cubicTo(
      cx + a * 0.5, cy - b * 1.4,
      cx + a * 2.0, cy - b * 1.4,
      cx + a * 2.0, cy,
    );
    path.cubicTo(
      cx + a * 2.0, cy + b * 1.4,
      cx + a * 0.5, cy + b * 1.4,
      cx, cy,
    );
    return path;
  }

  @override
  bool shouldRepaint(_InfinityPainter old) =>
      old.color != color || old.glowAmount != glowAmount;
}

// ─────────────────────────────────────────────
// Orb (background decoration, unchanged)
// ─────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  final double? top, bottom, left, right;

  const _Orb({
    required this.color,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Trandia Island (unchanged)
// ─────────────────────────────────────────────
class _TrandiaIsland extends StatelessWidget {
  final Color background;
  final Color textColor;

  const _TrandiaIsland({
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 37,
      width: 124,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            decoration: TextDecoration.none,
          ),
          child: const Text('Trandia'),
        ),
      ),
    );
  }
}
