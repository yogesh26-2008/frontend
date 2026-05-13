import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double _kBtnSize  = 64.0;
const double _kNavWidth = _kBtnSize;
const double _kItemH    = 54.0;
const double _kNavGap   = 6.0;
const double _kIconSize = 24.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _navOpen   = false;
  int  _activeNav = 0;

  late AnimationController _navCtrl;

  // individual staggered item animations
  final List<Animation<double>> _itemScales   = [];
  final List<Animation<double>> _itemOpacities = [];

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    // Stagger each item: items appear bottom→top with spring
    for (int i = 0; i < 5; i++) {
      // reversed: item 4 (bottom) first, item 0 (top) last
      final start = (4 - i) * 0.08;
      final end   = start + 0.55;

      _itemScales.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _navCtrl,
            curve: Interval(start, end.clamp(0, 1).toDouble(),
                curve: Curves.easeOutBack),
          ),
        ),
      );
      _itemOpacities.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _navCtrl,
            curve: Interval(start, (start + 0.30).clamp(0, 1).toDouble(),
                curve: Curves.easeOut),
          ),
        ),
      );
    }
  }

  @override
  void dispose() { _navCtrl.dispose(); super.dispose(); }

  void _toggleNav() {
    HapticFeedback.mediumImpact();
    setState(() => _navOpen = !_navOpen);
    if (_navOpen) {
      _navCtrl.forward(from: 0);
    } else {
      _navCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(isDark
        ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));

    final islandBg   = isDark ? const Color(0xFFF0F0EC) : const Color(0xFF1A1A1A);
    final islandText = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(children: [
        // Background
        Positioned.fill(child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter, radius: 1.5,
              colors: isDark
                  ? [const Color(0xFF1C1C1F), const Color(0xFF050506)]
                  : [const Color(0xFFF8F8FA), const Color(0xFFE2E2E8)],
            ),
          ),
        )),
        _Orb(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), size: 300, top: 100, left: -50),
        _Orb(color: (isDark ? Colors.white : Colors.black).withOpacity(0.03), size: 250, bottom: 150, right: -30),
        Positioned.fill(child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(color: (isDark ? Colors.black : Colors.white).withOpacity(0.1)),
        )),

        SafeArea(child: Stack(children: [

          // Trandia Island
          Align(alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.only(top: 8),
              child: _TrandiaIsland(background: islandBg, textColor: islandText))),

          // Message icon
          Align(alignment: Alignment.topRight,
            child: Padding(padding: const EdgeInsets.only(top: 10, right: 16),
              child: GestureDetector(
                onTap: () {},
                child: SizedBox(
                  width: 36, height: 36,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(_kIconSize, _kIconSize),
                      painter: _EnvelopeIconPainter(isDark: isDark),
                    ),
                  ),
                ),
              ))),

          // Vertical navbar — staggered pop
          Positioned(
            bottom: 30 + _kBtnSize + _kNavGap,
            right: 20,
            child: AnimatedBuilder(
              animation: _navCtrl,
              builder: (_, __) {
                return IgnorePointer(
                  ignoring: !_navOpen,
                  child: _StaggeredNavbar(
                    isDark: isDark,
                    activeIndex: _activeNav,
                    itemScales: _itemScales,
                    itemOpacities: _itemOpacities,
                    onTap: (i) => setState(() => _activeNav = i),
                  ),
                );
              },
            ),
          ),

          // Infinity button
          Positioned(
            bottom: 30, right: 20,
            child: _InfinityBtn(isDark: isDark, isOpen: _navOpen, onTap: _toggleNav),
          ),
        ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  STAGGERED NAVBAR — each icon pops in with spring
// ══════════════════════════════════════════════════════
class _StaggeredNavbar extends StatelessWidget {
  final bool isDark;
  final int  activeIndex;
  final List<Animation<double>> itemScales;
  final List<Animation<double>> itemOpacities;
  final ValueChanged<int> onTap;

  const _StaggeredNavbar({
    required this.isDark,
    required this.activeIndex,
    required this.itemScales,
    required this.itemOpacities,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navH   = 5 * _kItemH + 12.0;
    final glass  = (isDark ? Colors.white : Colors.black).withOpacity(0.09);
    final border = (isDark ? Colors.white : Colors.black).withOpacity(0.16);

    // container fades in as a whole
    final containerOpacity = itemOpacities.last; // last starts earliest

    return FadeTransition(
      opacity: containerOpacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kNavWidth / 2),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: _kNavWidth,
            height: navH,
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(_kNavWidth / 2),
              border: Border.all(color: border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                  blurRadius: 20, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final active = activeIndex == i;
                  return ScaleTransition(
                    scale: itemScales[i],
                    child: FadeTransition(
                      opacity: itemOpacities[i],
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap(i);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: _kNavWidth,
                          height: _kItemH,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active
                                    ? (isDark
                                        ? Colors.white.withOpacity(0.18)
                                        : Colors.black.withOpacity(0.12))
                                    : Colors.transparent,
                              ),
                              child: Center(
                                child: CustomPaint(
                                  size: const Size(_kIconSize, _kIconSize),
                                  painter: _NavIconPainter(
                                      index: i, isDark: isDark, active: active),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  ENVELOPE ICON — smooth curves, no sharp corners
// ══════════════════════════════════════════════════════
class _EnvelopeIconPainter extends CustomPainter {
  final bool isDark;
  const _EnvelopeIconPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isDark ? Colors.white : const Color(0xFF2A2A2A);
    final w = size.width;
    final h = size.height;

    final p = Paint()
      ..color = color.withOpacity(0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer rounded envelope body — large radius for soft look
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 1.2, w - 1.0, h - 2.4),
      const Radius.circular(5.0),
    );
    canvas.drawRRect(body, p);

    // V-fold — curved, not sharp. Use quadratic bezier for soft peak
    final fold = Path()
      ..moveTo(0.5 + 5.0, 1.2)
      ..quadraticBezierTo(w / 2, h * 0.55, w - 0.5 - 5.0, 1.2);
    canvas.drawPath(fold, p);
  }

  @override
  bool shouldRepaint(_EnvelopeIconPainter o) => o.isDark != isDark;
}

// ══════════════════════════════════════════════════════
//  NAV ICON PAINTERS — fully curved, no sharp corners
// ══════════════════════════════════════════════════════
class _NavIconPainter extends CustomPainter {
  final int  index;
  final bool isDark;
  final bool active;
  const _NavIconPainter(
      {required this.index, required this.isDark, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final base = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final col  = active ? base : base.withOpacity(0.50);
    final sw   = active ? 1.8 : 1.6;

    final p = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final filled = Paint()..color = col..style = PaintingStyle.fill;

    final w  = size.width;
    final h  = size.height;
    final cx = w / 2;
    final cy = h / 2;

    switch (index) {

      // ── 0 HOME — smooth house, all curves, no sharp angles ──────────
      case 0:
        // Roof: quadratic arc (smooth curved peak)
        final roofPath = Path()
          ..moveTo(w * 0.05, h * 0.52)
          ..quadraticBezierTo(cx, h * 0.02, w * 0.95, h * 0.52);
        canvas.drawPath(roofPath, p..strokeWidth = sw + 0.2);

        // Body outline — rounded bottom corners
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.50, w * 0.76, h * 0.46),
          const Radius.circular(3.0),
        );
        canvas.drawRRect(body, p);

        // Door — rounded rect, centered bottom
        final door = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.13, h * 0.64, w * 0.26, h * 0.32),
          const Radius.circular(2.5),
        );
        canvas.drawRRect(door, p);
        break;

      // ── 1 SHOTS — circle with curved rounded-triangle play ───────────
      case 1:
        canvas.drawCircle(Offset(cx, cy), w / 2 - 1.0, p);
        // Curved play triangle using cubics for rounded look
        final tri = Path()
          ..moveTo(cx - 3.5, cy - 5.0)
          ..cubicTo(cx - 3.5, cy - 6.0, cx + 6.5, cy - 1.5, cx + 6.5, cy)
          ..cubicTo(cx + 6.5, cy + 1.5, cx - 3.5, cy + 6.0, cx - 3.5, cy + 5.0)
          ..cubicTo(cx - 3.5, cy + 4.0, cx - 3.5, cy - 4.0, cx - 3.5, cy - 5.0)
          ..close();
        canvas.drawPath(tri, filled);
        break;

      // ── 2 ADD — rounded square + smooth plus ─────────────────────────
      case 2:
        final box = RRect.fromRectAndRadius(
          Rect.fromLTWH(0.8, 0.8, w - 1.6, h - 1.6),
          const Radius.circular(6.0),
        );
        canvas.drawRRect(box, p);
        // Plus with rounded caps
        canvas.drawLine(Offset(cx, cy - 5.0), Offset(cx, cy + 5.0), p);
        canvas.drawLine(Offset(cx - 5.0, cy), Offset(cx + 5.0, cy), p);
        break;

      // ── 3 SEARCH — smooth circular magnifier ─────────────────────────
      case 3:
        final r  = w * 0.265;
        final ox = cx - 2.8;
        final oy = cy - 2.8;
        canvas.drawCircle(Offset(ox, oy), r, p);
        canvas.drawLine(
          Offset(ox + r * 0.72, oy + r * 0.72),
          Offset(w - 1.0, h - 1.0),
          Paint()
            ..color = col
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw + 0.5
            ..strokeCap = StrokeCap.round,
        );
        break;

      // ── 4 PROFILE — smooth head + curved body ────────────────────────
      case 4:
        // Head
        canvas.drawCircle(Offset(cx, h * 0.30), h * 0.185, filled);
        // Smooth curved body — cubic bezier dome
        final body = Path()
          ..moveTo(w * 0.06, h - 1.0)
          ..cubicTo(
            w * 0.06, h * 0.62,
            w * 0.94, h * 0.62,
            w * 0.94, h - 1.0,
          )
          ..close();
        canvas.drawPath(body, filled);
        break;
    }
  }

  @override
  bool shouldRepaint(_NavIconPainter o) =>
      o.index != index || o.isDark != isDark || o.active != active;
}

// ══════════════════════════════════════════════════════
//  INFINITY BUTTON
// ══════════════════════════════════════════════════════
class _InfinityBtn extends StatefulWidget {
  final bool isDark;
  final bool isOpen;
  final VoidCallback onTap;
  const _InfinityBtn(
      {required this.isDark, required this.isOpen, required this.onTap});

  @override
  State<_InfinityBtn> createState() => _InfinityBtnState();
}

class _InfinityBtnState extends State<_InfinityBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final glass  = (widget.isDark ? Colors.white : Colors.black).withOpacity(0.09);
    final border = (widget.isDark ? Colors.white : Colors.black).withOpacity(0.18);
    final iconC  = widget.isDark ? Colors.white : const Color(0xFF1A1A1A);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: GestureDetector(
          onTapDown:   (_) => _ctrl.forward(),
          onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
          onTapCancel: () => _ctrl.reverse(),
          child: ClipOval(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: _kBtnSize, height: _kBtnSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glass,
                  border: Border.all(color: border, width: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomPaint(painter: _InfinityPainter(color: iconC)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  INFINITY PAINTER
// ══════════════════════════════════════════════════════
class _InfinityPainter extends CustomPainter {
  final Color color;
  const _InfinityPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    const a  = 13.0;
    const b  =  7.0;

    final path = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx + a * 0.5, cy - b, cx + a, cy - b, cx + a, cy)
      ..cubicTo(cx + a, cy + b, cx + a * 0.5, cy + b, cx, cy)
      ..cubicTo(cx - a * 0.5, cy - b, cx - a, cy - b, cx - a, cy)
      ..cubicTo(cx - a, cy + b, cx - a * 0.5, cy + b, cx, cy);

    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withOpacity(0.88));
  }

  @override
  bool shouldRepaint(_InfinityPainter o) => o.color != color;
}

// ══════════════════════════════════════════════════════
//  ORB
// ══════════════════════════════════════════════════════
class _Orb extends StatelessWidget {
  final Color color; final double size;
  final double? top, bottom, left, right;
  const _Orb({required this.color, required this.size,
      this.top, this.bottom, this.left, this.right});

  @override
  Widget build(BuildContext context) => Positioned(
    top: top, bottom: bottom, left: left, right: right,
    child: Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color, color.withOpacity(0)]))));
}

// ══════════════════════════════════════════════════════
//  TRANDIA ISLAND
// ══════════════════════════════════════════════════════
class _TrandiaIsland extends StatelessWidget {
  final Color background, textColor;
  const _TrandiaIsland({required this.background, required this.textColor});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    height: 37, width: 124,
    decoration: BoxDecoration(
        color: background, borderRadius: BorderRadius.circular(22)),
    child: Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
            color: textColor, fontSize: 14, fontWeight: FontWeight.w600,
            letterSpacing: -0.2, decoration: TextDecoration.none),
        child: const Text('Trandia'),
      ),
    ),
  );
}
