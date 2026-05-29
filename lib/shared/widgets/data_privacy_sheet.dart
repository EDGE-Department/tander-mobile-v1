import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';

/// Full-screen bottom sheet with Data Privacy Policy content.
///
/// Orange gradient header, scrollable legal text.
/// RA 10173 (Data Privacy Act of 2012) compliant for Philippine users.
class DataPrivacySheet extends StatelessWidget {
  const DataPrivacySheet({super.key});

  /// Show as a modal bottom sheet.
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DataPrivacySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xCCFFFFFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _Header(onClose: () => Navigator.pop(context)),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: const [
                      _Section(
                        number: '1',
                        title: 'Collection of Personal Data',
                        body:
                            'We collect the following personal information during registration and use of the platform:\n\n'
                            '\u2022 Full name and contact details\n'
                            '\u2022 Username and account credentials\n'
                            '\u2022 Date of birth and marital status\n'
                            '\u2022 Government-issued ID (for age verification)\n'
                            '\u2022 Senior Citizen ID or OSCA ID (for 60+ verification)\n'
                            '\u2022 Profile photos and optional personal descriptions\n'
                            '\u2022 Device information and usage analytics\n'
                            '\u2022 Location data (with your consent)',
                      ),
                      _Section(
                        number: '2',
                        title: 'Use and Processing',
                        body:
                            'Your personal data is processed for the following purposes:\n\n'
                            '\u2022 Providing and improving our services\n'
                            '\u2022 Verifying your identity and age eligibility\n'
                            '\u2022 Facilitating meaningful connections with other users\n'
                            '\u2022 Ensuring platform safety and fraud prevention\n'
                            '\u2022 Complying with legal and regulatory requirements\n'
                            '\u2022 Communicating important account and service updates',
                      ),
                      _Section(
                        number: '3',
                        title: 'Data Sharing and Disclosure',
                        body:
                            'Tander does not sell, trade, or commercially exploit your personal data. '
                            'Your information may only be shared with:\n\n'
                            '\u2022 Authorized service partners necessary for platform operation\n'
                            '\u2022 Government authorities when required by law or court order\n'
                            '\u2022 Emergency services when there is an immediate threat to safety\n\n'
                            'All third-party partners are bound by strict data protection agreements.\n'
                            'Provided, that prior consent is obtained from the data subject.',
                      ),
                      _Section(
                        number: '4',
                        title: 'Data Security Measures',
                        body:
                            'We implement comprehensive security measures to protect your data:\n\n'
                            '\u2022 End-to-end encryption for sensitive data transmission\n'
                            '\u2022 Role-based access controls for internal systems\n'
                            '\u2022 Regular security monitoring and vulnerability assessments\n'
                            '\u2022 Periodic security audits by independent assessors\n'
                            '\u2022 Secure cloud infrastructure with industry-standard protections',
                      ),
                      _Section(
                        number: '5',
                        title: 'Data Retention',
                        body:
                            'Personal data is retained only for as long as necessary to fulfill the purposes for which '
                            'it was collected. When data is no longer required, it will be securely deleted or anonymized. '
                            'Account data may be retained for a limited period after account deletion to comply with legal '
                            'obligations and resolve disputes.',
                      ),
                      _Section(
                        number: '6',
                        title: 'Data Subject Rights',
                        body:
                            'Under Republic Act No. 10173 (Data Privacy Act of 2012), you have the following rights:\n\n'
                            '\u2022 Right to be informed about how your data is collected and used\n'
                            '\u2022 Right to access your personal data held by Tander\n'
                            '\u2022 Right to correct any inaccurate or incomplete data\n'
                            '\u2022 Right to object to the processing of your data\n'
                            '\u2022 Right to request deletion of your data or withdraw consent\n'
                            '\u2022 Right to file a complaint with the National Privacy Commission (NPC)\n\n'
                            'To exercise these rights, please contact our Data Protection Officer.',
                      ),
                      _Section(
                        number: '7',
                        title: 'User Consent and Acceptance',
                        body:
                            'By creating an account on Tander, you confirm that you have read, understood, and agreed '
                            'to this Data Privacy Policy. You consent to the collection, use, and processing of your '
                            'personal data as described herein. You may withdraw your consent at any time by contacting '
                            'our support team or deleting your account.',
                      ),
                      _Section(
                        number: '8',
                        title: 'Updates to Policy',
                        body:
                            'Tander reserves the right to update or modify this Data Privacy Policy at any time. '
                            'Users will be notified of significant changes through in-app notifications or email. '
                            'Continued use of the platform after policy updates constitutes acceptance of the revised terms.',
                      ),
                      _Section(
                        number: '9',
                        title: 'Contact Information',
                        body:
                            'For questions or concerns regarding this Data Privacy Policy or the handling of your '
                            'personal data, please contact our Data Protection Officer:\n\n'
                            'Email: edge@cvmfinance.com\n\n'
                            'You may also reach us through the in-app Help Center or contact Tandy for assistance.',
                      ),
                      SizedBox(height: 16),
                      _AcknowledgementBox(),
                    ],
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

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryHover],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const PhosphorIcon(
            PhosphorIconsDuotone.shield,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Data Privacy Policy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(PhosphorIconsBold.x, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _Section({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcknowledgementBox extends StatelessWidget {
  const _AcknowledgementBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'By creating an account on Tander, you confirm that you have read, understood, and agreed '
        'to this Data Privacy Policy and consent to the collection, use, and processing of your personal data.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryHover,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
