import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension _ColorOp on Color {
  Color op(double opacity) => withValues(alpha: opacity);
}

const double _kBtnSize  = 64.0;
const double _kNavWidth = _kBtnSize;
const double _kItemH    = 54.0;
const double _kNavGap   = 6.0;
const double _kIconSize = 20.0; // message icon — minor size reduction

// ─── Story data ───────────────────────────────────────
class _StoryData {
  final String name, initials;
  final Color  avatarColor;
  final bool   seen, isOwn;
  const _StoryData({
    required this.name, required this.initials, required this.avatarColor,
    this.seen = false, this.isOwn = false,
  });
}

const _kStories = <_StoryData>[
  _StoryData(name: 'Your Story', initials: '+',  avatarColor: Color(0xFF3A3A3E), isOwn: true),
  _StoryData(name: 'Arjun',      initials: 'AK', avatarColor: Color(0xFF2D3561)),
  _StoryData(name: 'Priya',      initials: 'PS', avatarColor: Color(0xFF1B4332)),
  _StoryData(name: 'Rohan',      initials: 'RV', avatarColor: Color(0xFF3D0C11)),
  _StoryData(name: 'Sneha',      initials: 'SN', avatarColor: Color(0xFF2C2C54)),
  _StoryData(name: 'Dev',        initials: 'DM', avatarColor: Color(0xFF1A1A2E)),
  _StoryData(name: 'Kavya',      initials: 'KR', avatarColor: Color(0xFF2D132C)),
  _StoryData(name: 'Nikhil',     initials: 'NK', avatarColor: Color(0xFF0D3349), seen: true),
];

// ─── Post data ────────────────────────────────────────
class _PostData {
  final String user, userInitials, timeAgo, description;
  final Color  userColor;
  final List<Color> mediaGradient;
  final double aspectRatio;
  final bool   isVideo;
  final int    likes, comments;
  const _PostData({
    required this.user, required this.userInitials, required this.timeAgo,
    required this.description, required this.userColor,
    required this.mediaGradient, required this.aspectRatio,
    this.isVideo = false, required this.likes, required this.comments,
  });
}

const _kPosts = <_PostData>[
  _PostData(
    user: 'Arjun Kapoor', userInitials: 'AK', timeAgo: '2m ago',
    userColor: Color(0xFF2D3561),
    description: 'Golden hour at Manali. Sometimes you just need to step away from the noise and let the mountains do the talking. Pure bliss.',
    mediaGradient: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
    aspectRatio: 1.333, likes: 284, comments: 31,
  ),
  _PostData(
    user: 'Priya Sharma', userInitials: 'PS', timeAgo: '18m ago',
    userColor: Color(0xFF1B4332),
    description: 'Reel of the day! Caught the most insane sunset timelapse. Drop a fire if you want the full BTS.',
    mediaGradient: [Color(0xFF0d1b2a), Color(0xFF1b4332), Color(0xFF2d6a4f)],
    aspectRatio: 0.5625, isVideo: true, likes: 1420, comments: 87,
  ),
  _PostData(
    user: 'Rohan Verma', userInitials: 'RV', timeAgo: '45m ago',
    userColor: Color(0xFF3D0C11),
    description: 'Street food chronicles! Found this hidden gem near Chandni Chowk. The aloo chaat was absolutely unreal.',
    mediaGradient: [Color(0xFF3d0c11), Color(0xFF6b2737), Color(0xFFc9184a)],
    aspectRatio: 1.0, likes: 532, comments: 44,
  ),
  _PostData(
    user: 'Sneha Nair', userInitials: 'SN', timeAgo: '2h ago',
    userColor: Color(0xFF2C2C54),
    description: 'Late night coding sessions hit different with lo-fi. Building something exciting. Stay tuned. #buildinpublic #flutter',
    mediaGradient: [Color(0xFF0a0a0f), Color(0xFF1a1a3e), Color(0xFF2c2c54)],
    aspectRatio: 1.777, likes: 198, comments: 22,
  ),
  _PostData(
    user: 'Dev Malhotra', userInitials: 'DM', timeAgo: '3h ago',
    userColor: Color(0xFF1A1A2E),
    description: 'Sunrise from Triund peak. Trekked 9km in the dark just for this moment. Worth every step and every sip of cold chai at 4am.',
    mediaGradient: [Color(0xFF1a0533), Color(0xFF6a0572), Color(0xFFab47bc)],
    aspectRatio: 0.8, likes: 876, comments: 63,
  ),
];

// ═════════════════════════════════════════════════════
//  HOME SCREEN
// ═════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _navOpen   = false;
  int  _activeNav = 0;
  late AnimationController      _navCtrl;
  final List<Animation<double>> _itemScales    = [];
  final List<Animation<double>> _itemOpacities = [];

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 480));
    for (int i = 0; i < 5; i++) {
      final double start = (4 - i) * 0.08;
      final double end   = (start + 0.55).clamp(0.0, 1.0);
      _itemScales.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _navCtrl,
              curve: Interval(start, end, curve: Curves.easeOutBack))));
      _itemOpacities.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _navCtrl,
              curve: Interval(start, (start + 0.30).clamp(0.0, 1.0),
                  curve: Curves.easeOut))));
    }
  }

  @override
  void dispose() { _navCtrl.dispose(); super.dispose(); }

  void _toggleNav() {
    HapticFeedback.mediumImpact();
    setState(() => _navOpen = !_navOpen);
    _navOpen ? _navCtrl.forward(from: 0) : _navCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final topPad   = MediaQuery.of(context).padding.top;

    SystemChrome.setSystemUIOverlayStyle(isDark
        ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));

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
        _Orb(color: (isDark ? Colors.white : Colors.black).op(0.05),
            size: 300, top: 100, left: -50),
        _Orb(color: (isDark ? Colors.white : Colors.black).op(0.03),
            size: 250, bottom: 150, right: -30),
        Positioned.fill(child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
              color: (isDark ? Colors.black : Colors.white).op(0.1)),
        )),

        // ── Feed scrolls behind island — content visible under glass ──
        Positioned.fill(
          child: ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            // initial padding pushes content below the island,
            // but as user scrolls, content flows up behind the glass island
            padding: EdgeInsets.only(top: topPad + 56),
            children: [
              _StorySection(isDark: isDark),
              const SizedBox(height: 6),
              ..._kPosts.map((post) => Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                child: _PostCard(
                    key: ValueKey(post.user), post: post, isDark: isDark))),
              const SizedBox(height: 130),
            ],
          ),
        ),

        // ── Fixed overlays float on top of scrolling feed ──
        SafeArea(child: Stack(children: [

          // Island — glass, no bar
          Align(alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.only(top: 8),
              child: _TrandiaIsland(isDark: isDark))),

          // Message icon — compact
          Align(alignment: Alignment.topRight,
            child: Padding(padding: const EdgeInsets.only(top: 10, right: 14),
              child: GestureDetector(onTap: () {},
                child: SizedBox(width: 30, height: 30,
                  child: Center(child: CustomPaint(
                    size: const Size(_kIconSize, _kIconSize),
                    painter: _EnvelopeIconPainter(isDark: isDark))))))),

          // Navbar
          Positioned(
            bottom: 30 + _kBtnSize + _kNavGap, right: 20,
            child: AnimatedBuilder(animation: _navCtrl,
              builder: (_, __) => IgnorePointer(ignoring: !_navOpen,
                child: _StaggeredNavbar(
                  isDark: isDark, activeIndex: _activeNav,
                  itemScales: _itemScales, itemOpacities: _itemOpacities,
                  onTap: (i) => setState(() => _activeNav = i))))),

          // Infinity button
          Positioned(bottom: 30, right: 20,
            child: _InfinityBtn(
                isDark: isDark, isOpen: _navOpen, onTap: _toggleNav)),
        ])),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════
//  STORY SECTION
// ═════════════════════════════════════════════════════
class _StorySection extends StatelessWidget {
  final bool isDark;
  const _StorySection({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 110,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      physics: const BouncingScrollPhysics(),
      itemCount: _kStories.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(right: 14),
        child: _StoryBubble(story: _kStories[i], isDark: isDark)),
    ),
  );
}

class _StoryBubble extends StatelessWidget {
  final _StoryData story;
  final bool       isDark;
  const _StoryBubble({super.key, required this.story, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: SizedBox(width: 70,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 70, height: 70,
            child: CustomPaint(
              painter: _StoryRingPainter(
                  isDark: isDark, seen: story.seen, isOwn: story.isOwn),
              child: Padding(padding: const EdgeInsets.all(4.5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: story.avatarColor,
                    border: Border.all(
                      color: isDark ? Colors.black.op(0.60)
                                    : Colors.white.op(0.70),
                      width: 2)),
                  child: Center(child: story.isOwn
                      ? CustomPaint(size: const Size(18, 18),
                          painter: _PlusPainter(
                              color: isDark ? Colors.white
                                           : const Color(0xFF1A1A1A)))
                      : Text(story.initials, style: const TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w600))),
                )))),
          const SizedBox(height: 6),
          Text(story.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black)
                  .op(story.seen ? 0.38 : 0.80),
              fontSize: 10.5, fontWeight: FontWeight.w500)),
        ])),
    );
  }
}

class _StoryRingPainter extends CustomPainter {
  final bool isDark, seen, isOwn;
  const _StoryRingPainter(
      {required this.isDark, this.seen = false, this.isOwn = false});
  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final radius = size.width  / 2 - 1.5;
    if (isOwn) { _drawDashed(canvas, Offset(cx, cy), radius); return; }
    if (seen) {
      canvas.drawCircle(Offset(cx, cy), radius, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 1.8
        ..color = (isDark ? Colors.white : Colors.black).op(0.20));
      return;
    }
    canvas.drawCircle(Offset(cx, cy), radius, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.sweep(Offset(cx, cy),
        isDark
            ? const [Color(0xFFFFFFFF), Color(0xFFAAAAAA), Color(0xFF666666)]
            : const [Color(0xFF1A1A1A), Color(0xFF555555), Color(0xFF999999)],
        const [0.0, 0.5, 1.0], TileMode.clamp,
        -math.pi / 2, -math.pi / 2 + math.pi * 2));
  }
  void _drawDashed(Canvas canvas, Offset center, double radius) {
    const int n = 20;
    const double step = (2 * math.pi) / n;
    final Paint p = Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? Colors.white : Colors.black).op(0.45);
    for (int i = 0; i < n; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          i * step - math.pi / 2, step * 0.70, false, p);
    }
  }
  @override
  bool shouldRepaint(_StoryRingPainter o) =>
      o.isDark != isDark || o.seen != seen || o.isOwn != isOwn;
}

// ═════════════════════════════════════════════════════
//  POST CARD
// ═════════════════════════════════════════════════════
class _PostCard extends StatefulWidget {
  final _PostData post;
  final bool      isDark;
  const _PostCard({super.key, required this.post, required this.isDark});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _expanded  = false;
  bool _liked     = false;
  late int _likeCount;
  @override
  void initState() { super.initState(); _likeCount = widget.post.likes; }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() { _liked = !_liked; _likeCount += _liked ? 1 : -1; });
  }

  @override
  Widget build(BuildContext context) {
    final p    = widget.post;
    final dark = widget.isDark;
    final Color glass       = (dark ? Colors.white : Colors.black).op(0.07);
    final Color border      = (dark ? Colors.white : Colors.black).op(0.12);
    final Color textPrimary = (dark ? Colors.white : Colors.black).op(0.90);
    final Color textSub     = (dark ? Colors.white : Colors.black).op(0.45);
    // Instagram-style icon color
    final Color iconCol     = (dark ? Colors.white : Colors.black).op(0.80);
    final Color likedCol    = dark ? const Color(0xFFFF3040) : const Color(0xFFED4956);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 0.8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // User header
            Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(children: [
                Container(width: 30, height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: p.userColor,
                    border: Border.all(color: border, width: 0.8)),
                  child: Center(child: Text(p.userInitials,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w600)))),
                const SizedBox(width: 8),
                Text(p.user, style: TextStyle(
                    color: textPrimary, fontSize: 13,
                    fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(p.timeAgo, style: TextStyle(
                    color: textSub, fontSize: 11)),
              ])),

            // Media
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(aspectRatio: p.aspectRatio,
                  child: Stack(fit: StackFit.expand, children: [
                    Container(decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: p.mediaGradient))),
                    if (p.isVideo)
                      Center(child: Container(width: 48, height: 48,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.black.op(0.40),
                          border: Border.all(
                              color: Colors.white.op(0.60), width: 1.5)),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 26))),
                    Container(decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent,
                            Colors.black.op(0.18)]))),
                  ])))),

            // ── Instagram-style action icons ──────────────
            Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(children: [

                // Like
                GestureDetector(onTap: _toggleLike,
                  child: Row(children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: SizedBox(
                        key: ValueKey(_liked),
                        width: 24, height: 24,
                        child: CustomPaint(
                          painter: _IgHeartPainter(
                            color: _liked ? likedCol : iconCol,
                            filled: _liked)))),
                    const SizedBox(width: 5),
                    Text('$_likeCount', style: TextStyle(
                        color: textSub, fontSize: 12.5,
                        fontWeight: FontWeight.w500)),
                  ])),

                const SizedBox(width: 18),

                // Comment
                GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Row(children: [
                    SizedBox(width: 24, height: 24,
                      child: CustomPaint(
                          painter: _IgCommentPainter(color: iconCol))),
                    const SizedBox(width: 5),
                    Text('${p.comments}', style: TextStyle(
                        color: textSub, fontSize: 12.5,
                        fontWeight: FontWeight.w500)),
                  ])),

                const Spacer(),

                // Share / Send
                GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: SizedBox(width: 24, height: 24,
                    child: CustomPaint(
                        painter: _IgSharePainter(color: iconCol)))),
              ])),

            // Description
            Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: GestureDetector(
                onTap: () {
                  setState(() => _expanded = !_expanded);
                  HapticFeedback.selectionClick();
                },
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Text(p.description, style: TextStyle(
                          color: textPrimary.op(0.80),
                          fontSize: 12.5, height: 1.5))
                      : Row(crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: Text(p.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textPrimary.op(0.80),
                                  fontSize: 12.5, height: 1.5))),
                            const SizedBox(width: 4),
                            Text('more', style: TextStyle(color: textSub,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                ))),
          ]),
        ),
      ),
    );
  }
}

// ─── Instagram Heart ─────────────────────────────────
class _IgHeartPainter extends CustomPainter {
  final Color color;
  final bool  filled;
  const _IgHeartPainter({required this.color, this.filled = false});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width  / 2;
    final double cy = size.height / 2 + 1;
    final double s  = size.width  * 0.44;

    final path = Path();
    // Start at bottom tip
    path.moveTo(cx, cy + s * 0.75);
    // Left curve up
    path.cubicTo(
      cx - s * 0.15, cy + s * 0.40,
      cx - s,        cy - s * 0.15,
      cx - s * 0.55, cy - s * 0.60,
    );
    // Left top arc
    path.cubicTo(
      cx - s * 0.25, cy - s * 0.95,
      cx,            cy - s * 0.55,
      cx,            cy - s * 0.35,
    );
    // Right top arc (mirror)
    path.cubicTo(
      cx,            cy - s * 0.55,
      cx + s * 0.25, cy - s * 0.95,
      cx + s * 0.55, cy - s * 0.60,
    );
    // Right curve down
    path.cubicTo(
      cx + s,        cy - s * 0.15,
      cx + s * 0.15, cy + s * 0.40,
      cx,            cy + s * 0.75,
    );
    path.close();

    if (filled) {
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    } else {
      canvas.drawPath(path, Paint()
        ..color = color..style = PaintingStyle.stroke
        ..strokeWidth = 1.4..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(_IgHeartPainter o) =>
      o.color != color || o.filled != filled;
}

// ─── Instagram Comment bubble ─────────────────────────
class _IgCommentPainter extends CustomPainter {
  final Color color;
  const _IgCommentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w  = size.width;
    final double h  = size.height;
    final double cx = w / 2;
    final double cy = h / 2 - 1.0;

    final Paint p = Paint()
      ..color = color..style = PaintingStyle.stroke
      ..strokeWidth = 1.4..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Rounded bubble body
    const double bw = 10.5; // half width
    const double bh =  8.0; // half height
    const double r  =  4.5; // corner radius

    final path = Path()
      ..moveTo(cx - bw + r, cy - bh)
      ..lineTo(cx + bw - r, cy - bh)
      ..quadraticBezierTo(cx + bw, cy - bh, cx + bw, cy - bh + r)
      ..lineTo(cx + bw, cy + bh - r)
      ..quadraticBezierTo(cx + bw, cy + bh, cx + bw - r, cy + bh)
      // tail
      ..lineTo(cx - 1.5, cy + bh)
      ..quadraticBezierTo(cx - 3.5, cy + bh + 0.5, cx - 5.5, cy + bh + 5.5)
      ..quadraticBezierTo(cx - 5.5, cy + bh + 1.0, cx - bw + r + 1.5, cy + bh)
      ..lineTo(cx - bw + r, cy + bh)
      ..quadraticBezierTo(cx - bw, cy + bh, cx - bw, cy + bh - r)
      ..lineTo(cx - bw, cy - bh + r)
      ..quadraticBezierTo(cx - bw, cy - bh, cx - bw + r, cy - bh)
      ..close();

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_IgCommentPainter o) => o.color != color;
}

// ─── Instagram Share / Paper plane ────────────────────
class _IgSharePainter extends CustomPainter {
  final Color color;
  const _IgSharePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w  = size.width;
    final double h  = size.height;

    final Paint p = Paint()
      ..color = color..style = PaintingStyle.stroke
      ..strokeWidth = 1.4..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Paper plane: pointing upper-right, Instagram DM style
    // Main triangle outline
    final plane = Path()
      ..moveTo(w * 0.12, h * 0.50)          // left point
      ..lineTo(w * 0.88, h * 0.18)          // top-right tip
      ..lineTo(w * 0.88, h * 0.82)          // bottom-right
      ..close();
    canvas.drawPath(plane, p);

    // Fold line (inner crease from left → center)
    canvas.drawLine(
      Offset(w * 0.12, h * 0.50),
      Offset(w * 0.55, h * 0.50),
      p,
    );
    // Fold crease top half
    canvas.drawLine(
      Offset(w * 0.55, h * 0.50),
      Offset(w * 0.88, h * 0.18),
      p,
    );
  }

  @override
  bool shouldRepaint(_IgSharePainter o) => o.color != color;
}

// ═════════════════════════════════════════════════════
//  STAGGERED NAVBAR
// ═════════════════════════════════════════════════════
class _StaggeredNavbar extends StatelessWidget {
  final bool isDark;
  final int  activeIndex;
  final List<Animation<double>> itemScales, itemOpacities;
  final ValueChanged<int> onTap;
  const _StaggeredNavbar({
    super.key,
    required this.isDark, required this.activeIndex,
    required this.itemScales, required this.itemOpacities,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final double navH   = 5 * _kItemH + 12.0;
    final Color  glass  = (isDark ? Colors.white : Colors.black).op(0.09);
    final Color  border = (isDark ? Colors.white : Colors.black).op(0.16);
    return FadeTransition(
      opacity: itemOpacities.last,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kNavWidth / 2),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: _kNavWidth, height: navH,
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(_kNavWidth / 2),
              border: Border.all(color: border, width: 0.8),
              boxShadow: [BoxShadow(
                  color: Colors.black.op(isDark ? 0.35 : 0.10),
                  blurRadius: 20, offset: const Offset(0, 6))]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final bool active = activeIndex == i;
                  return ScaleTransition(scale: itemScales[i],
                    child: FadeTransition(opacity: itemOpacities[i],
                      child: GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); onTap(i); },
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(width: _kNavWidth, height: _kItemH,
                          child: Center(child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? (isDark ? Colors.white.op(0.18)
                                            : Colors.black.op(0.12))
                                  : Colors.transparent),
                            child: Center(child: CustomPaint(
                              size: const Size(24.0, 24.0),
                              painter: _NavIconPainter(
                                  index: i, isDark: isDark,
                                  active: active)))))))));
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════
//  ENVELOPE ICON
// ═════════════════════════════════════════════════════
class _EnvelopeIconPainter extends CustomPainter {
  final bool isDark;
  const _EnvelopeIconPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final Color  color = isDark ? Colors.white : const Color(0xFF2A2A2A);
    final double w = size.width;
    final double h = size.height;
    final Paint  p = Paint()
      ..color = color.op(0.90)..style = PaintingStyle.stroke
      ..strokeWidth = 1.5..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, 1.0, w - 1.0, h - 2.0),
        const Radius.circular(5.0)), p);
    canvas.drawPath(Path()
      ..moveTo(5.0, 1.0)
      ..quadraticBezierTo(w / 2, h * 0.56, w - 5.0, 1.0), p);
  }
  @override
  bool shouldRepaint(_EnvelopeIconPainter o) => o.isDark != isDark;
}

// ═════════════════════════════════════════════════════
//  NAV ICON PAINTERS
// ═════════════════════════════════════════════════════
class _NavIconPainter extends CustomPainter {
  final int  index;
  final bool isDark, active;
  const _NavIconPainter(
      {required this.index, required this.isDark, required this.active});
  @override
  void paint(Canvas canvas, Size size) {
    final Color  base   = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color  col    = active ? base : base.op(0.50);
    final double sw     = active ? 1.8 : 1.6;
    final Paint  stroke = Paint()..color = col..style = PaintingStyle.stroke
        ..strokeWidth = sw..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    final Paint  fill   = Paint()..color = col..style = PaintingStyle.fill;
    final double w = size.width; final double h = size.height;
    final double cx = w / 2;    final double cy = h / 2;
    switch (index) {
      case 0:
        canvas.drawPath(Path()
          ..moveTo(w * 0.05, h * 0.52)
          ..quadraticBezierTo(cx, h * 0.02, w * 0.95, h * 0.52),
          Paint()..color = col..style = PaintingStyle.stroke
              ..strokeWidth = sw + 0.2..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(w*0.12, h*0.50, w*0.76, h*0.46),
            const Radius.circular(3.0)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - w*0.13, h*0.64, w*0.26, h*0.32),
            const Radius.circular(2.5)), stroke);
        break;
      case 1:
        canvas.drawCircle(Offset(cx, cy), w / 2 - 1.0, stroke);
        canvas.drawPath(Path()
          ..moveTo(cx - 3.5, cy - 5.0)
          ..cubicTo(cx-3.5, cy-6.0, cx+6.5, cy-1.5, cx+6.5, cy)
          ..cubicTo(cx+6.5, cy+1.5, cx-3.5, cy+6.0, cx-3.5, cy+5.0)
          ..close(), fill);
        break;
      case 2:
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(0.8, 0.8, w - 1.6, h - 1.6),
            const Radius.circular(6.0)), stroke);
        canvas.drawLine(Offset(cx, cy - 5.0), Offset(cx, cy + 5.0), stroke);
        canvas.drawLine(Offset(cx - 5.0, cy), Offset(cx + 5.0, cy), stroke);
        break;
      case 3:
        final double r = w * 0.265; final double ox = cx - 2.8;
        final double oy = cy - 2.8;
        canvas.drawCircle(Offset(ox, oy), r, stroke);
        canvas.drawLine(Offset(ox + r * 0.72, oy + r * 0.72),
          Offset(w - 1.0, h - 1.0),
          Paint()..color = col..style = PaintingStyle.stroke
              ..strokeWidth = sw + 0.5..strokeCap = StrokeCap.round);
        break;
      case 4:
        canvas.drawCircle(Offset(cx, h * 0.30), h * 0.185, fill);
        canvas.drawPath(Path()
          ..moveTo(w * 0.06, h - 1.0)
          ..cubicTo(w*0.06, h*0.62, w*0.94, h*0.62, w*0.94, h - 1.0)
          ..close(), fill);
        break;
    }
  }
  @override
  bool shouldRepaint(_NavIconPainter o) =>
      o.index != index || o.isDark != isDark || o.active != active;
}

// ═════════════════════════════════════════════════════
//  INFINITY BUTTON
// ═════════════════════════════════════════════════════
class _InfinityBtn extends StatefulWidget {
  final bool isDark, isOpen;
  final VoidCallback onTap;
  const _InfinityBtn({super.key,
      required this.isDark, required this.isOpen, required this.onTap});
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
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final Color glass  = (widget.isDark ? Colors.white : Colors.black).op(0.09);
    final Color border = (widget.isDark ? Colors.white : Colors.black).op(0.18);
    final Color iconC  = widget.isDark ? Colors.white : const Color(0xFF1A1A1A);
    return AnimatedBuilder(animation: _ctrl,
      builder: (_, __) => Transform.scale(scale: _scale.value,
        child: GestureDetector(
          onTapDown:   (_) => _ctrl.forward(),
          onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
          onTapCancel: () => _ctrl.reverse(),
          child: ClipOval(child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(width: _kBtnSize, height: _kBtnSize,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: glass, border: Border.all(color: border, width: 0.9),
                boxShadow: [BoxShadow(color: Colors.black.op(0.22),
                    blurRadius: 12, offset: const Offset(0, 4))]),
              child: CustomPaint(painter: _InfinityPainter(color: iconC))))))));
  }
}

// ═════════════════════════════════════════════════════
//  INFINITY PAINTER
// ═════════════════════════════════════════════════════
class _InfinityPainter extends CustomPainter {
  final Color color;
  const _InfinityPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2; final double cy = size.height / 2;
    const double a = 13.0; const double b = 7.0;
    canvas.drawPath(Path()
      ..moveTo(cx, cy)..cubicTo(cx+a*0.5, cy-b, cx+a, cy-b, cx+a, cy)
      ..cubicTo(cx+a, cy+b, cx+a*0.5, cy+b, cx, cy)
      ..cubicTo(cx-a*0.5, cy-b, cx-a, cy-b, cx-a, cy)
      ..cubicTo(cx-a, cy+b, cx-a*0.5, cy+b, cx, cy),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round
          ..color = color.op(0.88));
  }
  @override bool shouldRepaint(_InfinityPainter o) => o.color != color;
}

// ═════════════════════════════════════════════════════
//  PLUS PAINTER
// ═════════════════════════════════════════════════════
class _PlusPainter extends CustomPainter {
  final Color color;
  const _PlusPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = color.op(0.85)..style = PaintingStyle.stroke
        ..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    final double cx = size.width / 2; final double cy = size.height / 2;
    canvas.drawLine(Offset(cx, cy - 5.5), Offset(cx, cy + 5.5), p);
    canvas.drawLine(Offset(cx - 5.5, cy), Offset(cx + 5.5, cy), p);
  }
  @override bool shouldRepaint(_PlusPainter o) => o.color != color;
}

// ═════════════════════════════════════════════════════
//  ORB
// ═════════════════════════════════════════════════════
class _Orb extends StatelessWidget {
  final Color color; final double size;
  final double? top, bottom, left, right;
  const _Orb({super.key, required this.color, required this.size,
      this.top, this.bottom, this.left, this.right});
  @override
  Widget build(BuildContext context) => Positioned(
    top: top, bottom: bottom, left: left, right: right,
    child: Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.op(0.0)]))));
}

// ═════════════════════════════════════════════════════
//  TRANDIA ISLAND — glass pill, text fills island perfectly
// ═════════════════════════════════════════════════════
class _TrandiaIsland extends StatelessWidget {
  final bool isDark;
  const _TrandiaIsland({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final Color glass  = (isDark ? Colors.white : Colors.black).op(0.10);
    final Color border = (isDark ? Colors.white : Colors.black).op(0.18);
    final Color text   = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          width: 148, height: 42,
          decoration: BoxDecoration(
            color: glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 0.8)),
          child: Center(
            child: Text('Trandia',
              style: TextStyle(
                color: text,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                decoration: TextDecoration.none,
              )),
          ),
        ),
      ),
    );
  }
}
