import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';
import 'package:url_launcher/url_launcher.dart';

/// Canonical support-email launcher used by every "Contact Support"
/// affordance in the app.
///
/// Tries `mailto:` via `url_launcher`. If that fails (no mail client
/// installed, web sandbox, etc.), copies the address to the clipboard
/// and surfaces a TanderToast so the user can paste it elsewhere.
const String _supportEmail = 'support@tander.ph';

Future<void> launchSupportEmail(
  BuildContext context, {
  required String subject,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: _supportEmail,
    queryParameters: {'subject': subject},
  );
  bool launched = false;
  try {
    launched = await launchUrl(uri);
  } catch (_) {
    launched = false;
  }
  if (launched || !context.mounted) return;
  await Clipboard.setData(const ClipboardData(text: _supportEmail));
  if (!context.mounted) return;
  TanderToastOverlay.show(
    context,
    const TanderToastData(
      message: 'Support email copied to clipboard',
      variant: TanderToastVariant.success,
    ),
  );
}
