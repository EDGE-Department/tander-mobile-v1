import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Preview step showing the captured ID photo with action buttons.
///
/// Shows the captured ID as background with an animated bottom sheet.
class IdPreviewView extends StatefulWidget {
  final String idPhotoPath;
  final bool isVerifying;
  final VoidCallback onRetake;
  final VoidCallback onContinue;

  const IdPreviewView({
    super.key,
    required this.idPhotoPath,
    required this.isVerifying,
    required this.onRetake,
    required this.onContinue,
  });

  @override
  State<IdPreviewView> createState() => _IdPreviewViewState();
}

class _IdPreviewViewState extends State<IdPreviewView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isLandscape) {
      return _buildLandscapeLayout(safePadding);
    }
    return _buildPortraitLayout(safePadding);
  }

  Widget _buildPortraitLayout(EdgeInsets safePadding) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, safePadding.top + 16, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.idPhotoPath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SlideTransition(
            position: _slideAnim,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 40,
                    offset: Offset(0, -12),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(24, 20, 24, safePadding.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E6EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: _retakeButton()),
                      const SizedBox(width: 16),
                      Expanded(child: _continueButton()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(EdgeInsets safePadding) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          // ID photo on the left
          Expanded(
            flex: 3,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  safePadding.left + 16,
                  safePadding.top + 16,
                  8,
                  safePadding.bottom + 16,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.idPhotoPath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          // Action buttons on the right
          SlideTransition(
            position: _slideAnim,
            child: Container(
              width: 200,
              margin: EdgeInsets.only(right: safePadding.right),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 40,
                    offset: Offset(-12, 0),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                safePadding.top + 24,
                24,
                safePadding.bottom + 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E6EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  _continueButton(),
                  const SizedBox(height: 16),
                  _retakeButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retakeButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: widget.isVerifying ? null : widget.onRetake,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF4F5F7),
          foregroundColor: const Color(0xFF141A28),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Retake',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _continueButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: widget.isVerifying
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onContinue();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8266),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x4DFF8266),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: widget.isVerifying
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Looks Good',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
