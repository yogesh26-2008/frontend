// edit_profile_screen.dart
// Edit profile screen — same matte glass monochrome theme as the rest of the app.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'glass_common.dart';

class EditProfileScreen extends StatefulWidget {
  final bool dark;
  const EditProfileScreen({super.key, required this.dark});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController    = TextEditingController(text: 'Sarah Dietrich');
  final _handleController  = TextEditingController(text: 'sarah.d');
  final _pronounsController = TextEditingController(text: 'she/her');
  final _bioController     = TextEditingController(
    text: 'Designer & art director.\nCurrently leading visual identity at Studio Atelier — type, motion & quiet things.',
  );
  final _titleController   = TextEditingController(text: 'Designer · Studio Atelier');
  final _websiteController = TextEditingController(text: 'atelier.studio/sarah');

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _pronounsController.dispose();
    _bioController.dispose();
    _titleController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final fg   = GlassTokens.fg(dark);
    final sub  = GlassTokens.sub(dark);

    return Scaffold(
      backgroundColor: dark ? GlassTokens.bgDark : GlassTokens.bgLight,
      body: Stack(
        children: [
          // Backdrop blobs
          GlassBackdrop(dark: dark),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: GlassHeader(
                    dark: dark,
                    padding: const EdgeInsets.only(left: 7, right: 8),
                    child: Row(
                      children: [
                        GlassCircleButton(
                          dark: dark,
                          icon: Icons.arrow_back_ios_new_rounded,
                          iconSize: 16,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Edit Profile',
                          style: manrope(size: 17, weight: FontWeight.w800, color: fg),
                        ),
                        const Spacer(),
                        // Save button
                        _SaveButton(dark: dark, onTap: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Scrollable body ───────────────────────────────
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                    children: [
                      // Avatar section
                      _AvatarSection(dark: dark, fg: fg, sub: sub),

                      const SizedBox(height: 20),

                      // BASIC INFO
                      _SectionLabel('BASIC INFO', sub: sub),
                      const SizedBox(height: 8),
                      GlassSurface(
                        dark: dark,
                        radius: 24,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _FieldRow(
                              dark: dark,
                              label: 'Name',
                              controller: _nameController,
                              icon: Icons.person_outline_rounded,
                            ),
                            _Divider(dark: dark),
                            _FieldRow(
                              dark: dark,
                              label: 'Username',
                              controller: _handleController,
                              icon: Icons.alternate_email_rounded,
                              prefix: '@',
                            ),
                            _Divider(dark: dark),
                            _FieldRow(
                              dark: dark,
                              label: 'Pronouns',
                              controller: _pronounsController,
                              icon: Icons.tag_rounded,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ABOUT
                      _SectionLabel('ABOUT', sub: sub),
                      const SizedBox(height: 8),
                      GlassSurface(
                        dark: dark,
                        radius: 24,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _MultilineFieldRow(
                              dark: dark,
                              label: 'Bio',
                              controller: _bioController,
                              icon: Icons.notes_rounded,
                              maxLines: 4,
                              maxLength: 160,
                            ),
                            _Divider(dark: dark),
                            _FieldRow(
                              dark: dark,
                              label: 'Title',
                              controller: _titleController,
                              icon: Icons.work_outline_rounded,
                            ),
                            _Divider(dark: dark),
                            _FieldRow(
                              dark: dark,
                              label: 'Website',
                              controller: _websiteController,
                              icon: Icons.link_rounded,
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // DANGER ZONE — delete account
                      _DangerCard(dark: dark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save button pill
// ─────────────────────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;
  const _SaveButton({required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: dark ? Colors.white : const Color(0xFF0A0A0A),
        ),
        alignment: Alignment.center,
        child: Text(
          'Save',
          style: manrope(
            size: 13,
            weight: FontWeight.w800,
            color: dark ? const Color(0xFF0A0A0A) : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar section
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarSection extends StatelessWidget {
  final bool dark;
  final Color fg;
  final Color sub;
  const _AvatarSection({required this.dark, required this.fg, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Avatar circle
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark ? const Color(0xFF0A0A0C) : const Color(0xFFFAFAFA),
                  boxShadow: [
                    BoxShadow(
                      color: dark
                          ? Colors.black.withOpacity(0.7)
                          : const Color(0xFF14161E).withOpacity(0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                      spreadRadius: -14,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: monoAvatar(dark, 0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'S',
                    style: manrope(
                      size: 36,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1.1,
                    ),
                  ),
                ),
              ),
              // Camera badge
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark ? Colors.white : const Color(0xFF0A0A0A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(dark ? 0.4 : 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 15,
                  color: dark ? const Color(0xFF0A0A0A) : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Change photo',
            style: manrope(
              size: 13,
              weight: FontWeight.w700,
              color: sub,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color sub;
  const _SectionLabel(this.text, {required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
      child: Text(
        text,
        style: manrope(size: 11, weight: FontWeight.w800, color: sub, letterSpacing: 0.9),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single-line field row
// ─────────────────────────────────────────────────────────────────────────────
class _FieldRow extends StatelessWidget {
  final bool dark;
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? prefix;
  final TextInputType keyboardType;

  const _FieldRow({
    required this.dark,
    required this.label,
    required this.controller,
    required this.icon,
    this.prefix,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final fg  = GlassTokens.fg(dark);
    final sub = GlassTokens.sub(dark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark
                  ? Colors.white.withOpacity(0.09)
                  : Colors.black.withOpacity(0.06),
            ),
            child: Icon(icon, size: 19, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: manrope(size: 11, weight: FontWeight.w700, color: sub),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (prefix != null)
                      Text(
                        prefix!,
                        style: manrope(size: 14.5, weight: FontWeight.w600, color: sub),
                      ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        style: manrope(size: 14.5, weight: FontWeight.w600, color: fg),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        cursorColor: GlassTokens.fg(dark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Multi-line field row (bio)
// ─────────────────────────────────────────────────────────────────────────────
class _MultilineFieldRow extends StatelessWidget {
  final bool dark;
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final int maxLength;

  const _MultilineFieldRow({
    required this.dark,
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 4,
    this.maxLength = 160,
  });

  @override
  Widget build(BuildContext context) {
    final fg  = GlassTokens.fg(dark);
    final sub = GlassTokens.sub(dark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark
                  ? Colors.white.withOpacity(0.09)
                  : Colors.black.withOpacity(0.06),
            ),
            child: Icon(icon, size: 19, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: manrope(size: 11, weight: FontWeight.w700, color: sub),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  style: manrope(size: 14.5, weight: FontWeight.w600, color: fg),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterStyle: manrope(size: 11, weight: FontWeight.w600, color: sub),
                  ),
                  cursorColor: GlassTokens.fg(dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtle hairline divider between rows
// ─────────────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final bool dark;
  const _Divider({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Container(
        height: 1,
        color: dark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.05),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Danger zone card
// ─────────────────────────────────────────────────────────────────────────────
class _DangerCard extends StatelessWidget {
  final bool dark;
  const _DangerCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      dark: dark,
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(dark ? 0.15 : 0.10),
            ),
            child: Icon(Icons.delete_outline_rounded, size: 19, color: Colors.red.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete account',
                  style: manrope(size: 14.5, weight: FontWeight.w800, color: Colors.red.shade400),
                ),
                const SizedBox(height: 3),
                Text(
                  'Permanently remove your account and data',
                  style: manrope(size: 12, weight: FontWeight.w500, color: Colors.red.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.red.shade300, size: 24),
        ],
      ),
    );
  }
}
