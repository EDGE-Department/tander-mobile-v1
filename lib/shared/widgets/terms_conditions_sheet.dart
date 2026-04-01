import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Full-screen bottom sheet with Terms & Conditions content.
///
/// Teal gradient header, scrollable legal text.
/// Philippine law (RA 10173) compliant for senior citizens 60+.
class TermsConditionsSheet extends StatelessWidget {
  const TermsConditionsSheet({super.key});

  /// Show as a modal bottom sheet.
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TermsConditionsSheet(),
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
                        title: 'Eligibility and User Acceptance',
                        body:
                            'Tander is designed exclusively for Filipino senior citizens aged 60 years and above. '
                            'By registering, you confirm that you meet this age requirement. Verification through a valid '
                            'Senior Citizen ID or government-issued identification is required during registration.',
                      ),
                      _Section(
                        number: '2',
                        title: 'Purpose of the Platform',
                        body:
                            'Tander is a social connection platform designed to reduce isolation and promote meaningful '
                            'companionship, emotional wellbeing, and community among Filipino seniors. It is NOT a dating app '
                            'and is NOT a replacement for professional medical, psychological, or psychiatric care.',
                      ),
                      _Section(
                        number: '3',
                        title: 'Account Registration and Security',
                        body:
                            'You are responsible for maintaining the confidentiality of your account credentials. You agree '
                            'to provide accurate and truthful information during registration. Tander reserves the right to '
                            'suspend or terminate accounts that provide false information.',
                      ),
                      _Section(
                        number: '4',
                        title: 'Acceptable Use and Community Conduct',
                        body:
                            'Tander enforces a zero-tolerance policy for abuse, exploitation, harassment, hate speech, '
                            'or any form of misconduct. Users must treat all members with dignity and respect. Any violations '
                            'may result in immediate account suspension or permanent termination.',
                      ),
                      _Section(
                        number: '5',
                        title: 'Communication, Chat, and Video Features',
                        body:
                            'Tander provides messaging and video call features for social connection. These features are '
                            'monitored for safety. Users must not share explicit, harmful, or misleading content. Tander '
                            'reserves the right to review and moderate communications to ensure community safety.',
                      ),
                      _Section(
                        number: '6',
                        title: 'Tandy — Digital Companion & Support',
                        body:
                            'Tandy is an AI-powered digital companion designed to provide guidance, motivation, and emotional '
                            'support. Tandy does NOT provide medical, psychological, diagnostic, or treatment advice and must '
                            'NOT be relied upon as a substitute for professional medical care. Always consult a licensed '
                            'healthcare professional for medical concerns.',
                      ),
                      _Section(
                        number: '7',
                        title: 'Wellness & Third-Party Redirection',
                        body:
                            'Tander may recommend or redirect users to third-party wellness services, mental health resources, '
                            'or community programs. Tander is NOT liable for the quality, accuracy, or outcomes of any '
                            'third-party services accessed through the platform.',
                      ),
                      _Section(
                        number: '8',
                        title: 'Privacy and Data Protection',
                        body:
                            'Your personal data is collected and processed in accordance with our Data Privacy Policy and '
                            'Republic Act No. 10173 (Data Privacy Act of 2012). We are committed to protecting your personal '
                            'information and will never sell or commercially exploit your data.',
                      ),
                      _Section(
                        number: '9',
                        title: 'Safety Disclaimer',
                        body:
                            'While Tander implements safety measures including ID verification and moderation, users are '
                            'responsible for exercising their own judgment when interacting with others. Tander is not liable '
                            'for the conduct, actions, or representations of any user on the platform.',
                      ),
                      _Section(
                        number: '10',
                        title: 'Intellectual Property',
                        body:
                            'All content, designs, logos, and features of Tander are the intellectual property of Tander '
                            'and its licensors. Users may not copy, modify, distribute, or create derivative works without '
                            'prior written consent.',
                      ),
                      _Section(
                        number: '11',
                        title: 'Account Suspension and Termination',
                        body:
                            'Tander reserves the right to suspend or terminate any account that violates these Terms, '
                            'engages in prohibited conduct, or poses a risk to the safety of other users. Suspended accounts '
                            'may appeal through the Help Center.',
                      ),
                      _Section(
                        number: '12',
                        title: 'Limitation of Liability',
                        body:
                            'Tander is provided "as is" without warranties of any kind. To the maximum extent permitted by '
                            'law, Tander shall not be liable for any indirect, incidental, special, or consequential damages '
                            'arising from the use of the platform.',
                      ),
                      _Section(
                        number: '13',
                        title: 'Modification to Terms',
                        body:
                            'Tander reserves the right to update or modify these Terms at any time. Users will be notified '
                            'of significant changes. Continued use of the platform after changes constitutes acceptance of '
                            'the updated Terms.',
                      ),
                      _Section(
                        number: '14',
                        title: 'Governing Law',
                        body:
                            'These Terms are governed by and construed in accordance with the laws of the Republic of the '
                            'Philippines. Any disputes arising from these Terms shall be resolved in the appropriate courts '
                            'of the Philippines.',
                      ),
                      _Section(
                        number: '15',
                        title: 'Contact and Support',
                        body:
                            'For questions, concerns, or support regarding these Terms, please contact us through the '
                            'in-app Help Center or reach out to Tandy, your digital companion, for assistance.',
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryHover],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const PhosphorIcon(PhosphorIconsDuotone.fileText,
              color: Colors.white, size: 24),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Terms & Conditions',
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
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Text(
        'By creating an account or using the Tander App, you acknowledge that you have read, '
        'understood, and agreed to these Terms and Conditions.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryHover,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
