/// Help & FAQ bottom sheet with expandable accordion and contact support.
///
/// FAQ items expand/collapse on tap. A contact support button opens an
/// email compose action. App version is displayed at the bottom.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_bottom_sheet.dart';

// ── FAQ data ────────────────────────────────────────────────────────────

class _FaqItem {
  const _FaqItem({required this.id, required this.question, required this.answer});
  final String id;
  final String question;
  final String answer;
}

const List<_FaqItem> _faqItems = [
  _FaqItem(
    id: 'how-connections-work',
    question: 'How do connections work?',
    answer:
        'When you express interest in someone and they express interest back, '
        'you become connected. You can then message, call, and build a '
        'friendship at your own pace. There is no pressure \u2014 you are '
        'always in control.',
  ),
  _FaqItem(
    id: 'profile-verification',
    question: 'Why should I verify my profile?',
    answer:
        'Verified profiles have a trust badge that helps others feel safe '
        'connecting with you. Verification requires a government-issued ID '
        'and is a one-time process. Your ID is never stored or shared.',
  ),
  _FaqItem(
    id: 'block-report',
    question: 'How do I block or report someone?',
    answer:
        'Visit any profile and tap the three-dot menu in the top right. '
        'You can block or report from there. Blocked people cannot see your '
        'profile or contact you. Reports are reviewed by our safety team '
        'within 24 hours.',
  ),
  _FaqItem(
    id: 'tandy-ai',
    question: 'What is Tandy?',
    answer:
        'Tandy is your personal care companion \u2014 a friendly AI that '
        'listens, guides you through breathing exercises, meditation sessions, '
        'and gentle wellness check-ins. Tandy is not a therapist and cannot '
        'provide medical advice.',
  ),
  _FaqItem(
    id: 'delete-messages',
    question: "Can I delete messages I've sent?",
    answer:
        'You can delete a message for yourself by long-pressing it and '
        'selecting Delete. This removes it from your view. To delete for '
        'everyone, select Delete for everyone within 10 minutes of sending.',
  ),
  _FaqItem(
    id: 'data-privacy',
    question: 'How is my data used?',
    answer:
        'Your personal data is never sold to third parties. We use it only '
        'to operate and improve Tander. You can download or delete your data '
        'at any time from Settings.',
  ),
];

const String _supportEmail = 'support@tander.app';
const String _appVersion = '1.0.0';

// ── Public entry point ──────────────────────────────────────────────────

/// Shows the help & FAQ sheet as a modal bottom sheet.
Future<void> showHelpSheet(BuildContext context) async {
  await TanderBottomSheet.show(
    context: context,
    title: 'Help & FAQ',
    child: const HelpSheetContent(),
  );
}

// ── Sheet content ───────────────────────────────────────────────────────

/// Content widget for the help bottom sheet.
///
/// Uses [StatefulWidget] to manage accordion expansion state.
class HelpSheetContent extends StatefulWidget {
  const HelpSheetContent({super.key});

  @override
  State<HelpSheetContent> createState() => _HelpSheetContentState();
}

class _HelpSheetContentState extends State<HelpSheetContent> {
  String? _expandedId;

  void _toggleItem(String itemId) {
    setState(() {
      _expandedId = _expandedId == itemId ? null : itemId;
    });
  }

  Future<void> _openEmailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Tander App Support Request'},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      AppLogger.error(
        'Could not launch email client',
        operation: 'HelpSheet',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _IntroCard(),
          const SizedBox(height: AppSpacing.md),

          _SectionLabel(label: 'Frequently asked questions'),
          const SizedBox(height: AppSpacing.sm),
          _FaqAccordion(
            expandedId: _expandedId,
            onToggle: _toggleItem,
          ),
          const SizedBox(height: AppSpacing.lg),

          _SectionLabel(label: 'Still need help?'),
          const SizedBox(height: AppSpacing.sm),
          _ContactSupportCard(onTap: _openEmailSupport),
          const SizedBox(height: AppSpacing.lg),

          Center(
            child: Text(
              'Tander v$_appVersion',
              style: AppTypography.caption,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ── Intro card ──────────────────────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.borderLg,
      ),
      child: Text(
        'Find answers to common questions below, or reach out to our '
        'support team if you need more help.',
        style: AppTypography.body.copyWith(color: AppColors.textBody),
      ),
    );
  }
}

// ── FAQ accordion ───────────────────────────────────────────────────────

class _FaqAccordion extends StatelessWidget {
  const _FaqAccordion({required this.expandedId, required this.onToggle});

  final String? expandedId;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int index = 0; index < _faqItems.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.border),
            _FaqTile(
              faqItem: _faqItems[index],
              isExpanded: expandedId == _faqItems[index].id,
              onTap: () => onToggle(_faqItems[index].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.faqItem,
    required this.isExpanded,
    required this.onTap,
  });

  final _FaqItem faqItem;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints:
                const BoxConstraints(minHeight: AppSpacing.touchComfortable),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    faqItem.question,
                    style: AppTypography.label,
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: AppDurations.fast,
                  curve: AppCurves.premiumEase,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: isExpanded
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: Text(
              faqItem.answer,
              style: AppTypography.body.copyWith(height: 1.6),
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: AppDurations.base,
          sizeCurve: AppCurves.premiumEase,
        ),
      ],
    );
  }
}

// ── Contact support card ────────────────────────────────────────────────

class _ContactSupportCard extends StatelessWidget {
  const _ContactSupportCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Container(
          constraints:
              const BoxConstraints(minHeight: AppSpacing.touchComfortable),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadius.borderLg,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryHover],
                  ),
                  borderRadius: AppRadius.borderMd,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.chat_bubble, size: 20,
                    color: AppColors.textInverse),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact support', style: AppTypography.label),
                    Text(
                      'We typically respond within 24 hours',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xxs),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
