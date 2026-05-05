import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tander_flutter_v3/core/config/env_config.dart';

/// Resolves a backend photo URL into something [Image.network] can fetch.
///
/// The backend returns signed photo URLs as paths (e.g.
/// `/photos/{userId}/{file}?exp=...&sig=...`). Web resolves these against the
/// page origin; Flutter has no implicit origin, so we prepend the API base.
/// Absolute URLs (http/https/data) and blank/null inputs pass through unchanged.
///
/// On Android emulator, localhost URLs are rewritten to 10.0.2.2 so they reach
/// the host machine.
String? resolvePhotoUrl(String? url) {
  if (url == null || url.isEmpty) return url;

  // Handle absolute URLs
  if (url.startsWith('http://') || url.startsWith('https://')) {
    // Android emulator: rewrite localhost to 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) {
      return url
          .replaceFirst('http://localhost:', 'http://10.0.2.2:')
          .replaceFirst('http://127.0.0.1:', 'http://10.0.2.2:');
    }
    return url;
  }

  if (url.startsWith('data:')) return url;
  if (url.startsWith('/')) return '${EnvConfig.apiBaseUrl}$url';
  return url;
}
