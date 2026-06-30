// THROWAWAY dev preview for the bottom nav redesign (Phase 1 verification).
// Not part of the app; delete after on-device verification.
//
// Run: flutter run -t lib/dev/nav_preview.dart -d <android-device>
import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';

void main() => runApp(const _NavPreviewApp());

class _NavPreviewApp extends StatefulWidget {
  const _NavPreviewApp();

  @override
  State<_NavPreviewApp> createState() => _NavPreviewAppState();
}

class _NavPreviewAppState extends State<_NavPreviewApp> {
  int _activeIndex = 2;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF5B7BA6),
        body: const Center(
          child: Text(
            'Tablet preview (full width)',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        bottomNavigationBar: BottomNavBarView(
          activeIndex: _activeIndex,
          reduceMotion: false,
          badgeFor: (id) => id == 'messages' ? 3 : 0,
          onTap: (i) => setState(() => _activeIndex = i),
        ),
      ),
    );
  }
}
