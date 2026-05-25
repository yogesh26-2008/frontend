// lib/utils/error_dialog.dart
//
// A premium glassmorphic error dialog matching the app's login/signup theme.
// Displays in the center of the screen with a blurred backdrop and modern design.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class GlassErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget>? actions;

  const GlassErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Harmonious curated palettes to match the app's login/signup screen theme
    final fg = isDark ? const Color(0xFFF5F4FF) : const Color(0xFF0E1124);
    final muted = isDark ? const Color(0x99F5F4FF) : const Color(0x8C141628);
    
    final cardFill = isDark 
        ? const [Color(0x24FFFFFF), Color(0x0CFFFFFF)] 
        : const [Color(0xE0FFFFFF), Color(0xA0FFFFFF)];
    final cardBorder = isDark ? const Color(0x2EFFFFFF) : const Color(0xD9FFFFFF);
    final cardShadow = [
      BoxShadow(
        color: isDark ? const Color(0xCC000000) : const Color(0x33282050),
        blurRadius: 40,
        offset: const Offset(0, 20),
        spreadRadius: -10,
      )
    ];

    final btnFill = isDark ? const [Color(0xFFF2F2F7), Color(0xFFE6E6F5)] : const [Color(0xFF5A5A60), Color(0xFF3D3D42)];
    final btnFg = isDark ? const Color(0xFF0B0A18) : const Color(0xFFFFFFFF);
    final btnBorder = isDark ? const Color(0x66FFFFFF) : const Color(0x33FFFFFF);

    final finalTitle = title.isEmpty ? 'Error'.tr(context) : title;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: cardBorder, width: 1.5),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cardFill,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Warning premium icon
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0x1AEF4444) : const Color(0x14EF4444),
                          border: Border.all(
                            color: const Color(0x40EF4444),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Title
                    Text(
                      finalTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Message
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Actions
                    if (actions != null && actions!.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions!.map((a) => Expanded(child: a)).toList(),
                      )
                    else
                      // Default glass pill button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: btnBorder, width: 1),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: btnFill,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'OK'.tr(context),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: btnFg,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the premium glassmorphic error popup with blurred backdrop.
Future<T?> showErrorDialog<T>(
  BuildContext context, {
  String? title,
  required String message,
  List<Widget>? actions,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return GlassErrorDialog(
        title: title ?? '',
        message: message,
        actions: actions,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Premium micro-animation: smooth fade + scale-up bounce
      final curvedValue = Curves.easeInOutBack.transform(animation.value);
      return BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 5 * animation.value,
          sigmaY: 5 * animation.value,
        ),
        child: Transform.scale(
          scale: 0.85 + (curvedValue * 0.15),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
    },
  );
}
