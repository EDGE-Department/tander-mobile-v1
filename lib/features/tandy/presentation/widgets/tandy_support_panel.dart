import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Professional support panel — crisis resources, community support,
/// and a psychiatrist directory teaser (coming soon).
class TandySupportPanel extends StatelessWidget {
  const TandySupportPanel({
    required this.onClose,
    required this.onOpenPsychiatrist,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onOpenPsychiatrist;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            _PanelHeader(onClose: onClose),
            const Divider(height: 1, color: AppColors.borderLight),

            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: <Widget>[
                  const SizedBox(height: 20),
                  _HeroCard(),
                  const SizedBox(height: 26),
                  const _SectionLabel(
                    text: 'Crisis Support',
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 10),
                  const _ComingSoonCard(
                    label: 'National Center for Mental Health',
                    sub: 'Free crisis hotline \u00B7 24/7',
                    color: AppColors.danger,
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 10),
                  const _ComingSoonCard(
                    label: 'Hopeline Philippines',
                    sub: 'Mental health helpline \u00B7 24/7',
                    color: kTandyPurple,
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(
                    text: 'Community Support',
                    color: kTandyOrange,
                  ),
                  const SizedBox(height: 10),
                  const _ComingSoonCard(
                    label: 'Community Resources',
                    sub: 'Free counselling & mental health support',
                    color: kTandyOrange,
                    icon: Icons.favorite,
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(
                    text: 'Professional Care',
                    color: kTandyPurple,
                  ),
                  const SizedBox(height: 10),
                  _PsychiatristTeaser(onTap: onOpenPsychiatrist),
                  const SizedBox(height: 22),
                  _Disclaimer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: const Color(0xFFFEF0E0),
              border: Border.all(color: kTandyOrange.withAlpha(34)),
            ),
            child: const Icon(
              Icons.favorite_outline,
              size: 18,
              color: kTandyOrange,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Professional Support',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textStrong,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Verified resources',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 16),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFFFFF9F3),
            Color(0xFFFFF2E0),
            Color(0xFFFFEAD0),
          ],
        ),
        border: Border.all(color: kTandyOrange.withAlpha(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFF6B137), kTandyOrange],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: kTandyOrange.withAlpha(87),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "You're not alone",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                        color: Color(0xFF7A3B00),
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tandy is here with you',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F9D94),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "Whatever you're feeling right now — it's okay to reach out. A licensed professional can provide deeper care. Reaching out is one of the bravest things you can do.",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B5500),
              height: 1.75,
            ),
          ),
          const SizedBox(height: 16),
          // Crisis hotlines - Coming Soon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white.withAlpha(200),
              border: Border.all(color: kTandyOrange.withAlpha(40)),
            ),
            child: Row(
              children: <Widget>[
                Opacity(
                  opacity: 0.6,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFFF6B137), kTandyOrange],
                      ),
                    ),
                    child: const Icon(
                      Icons.phone,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'CRISIS HOTLINES',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA06020),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: kTandyOrange.withAlpha(20),
                    border: Border.all(color: kTandyOrange.withAlpha(40)),
                  ),
                  child: const Text(
                    'COMING SOON',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: kTandyOrange,
                      letterSpacing: 0.5,
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1.5, color: color.withAlpha(24))),
      ],
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.label,
    required this.sub,
    required this.color,
    required this.icon,
  });
  final String label;
  final String sub;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.75,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(41)),
          color: Colors.white,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: color.withAlpha(128),
              ),
            ),
            const SizedBox(width: 14),
            Opacity(
              opacity: 0.6,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: color.withAlpha(18),
                  border: Border.all(color: color.withAlpha(34)),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: color.withAlpha(20),
                border: Border.all(color: color.withAlpha(40)),
              ),
              child: Text(
                'COMING SOON',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PsychiatristTeaser extends StatelessWidget {
  const _PsychiatristTeaser({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFFF8F6FF),
              Color(0xFFEDE9FE),
              Color(0xFFE5E0FF),
            ],
          ),
          border: Border.all(color: kTandyPurple.withAlpha(34)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: <Color>[kTandyPurple, Color(0xFF6D28D9)],
                ),
              ),
              child: const Icon(Icons.person, size: 25, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Flexible(
                        child: Text(
                          'Find a Psychiatrist',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF3B1A7A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: kTandyPurple.withAlpha(20),
                          border: Border.all(color: kTandyPurple.withAlpha(40)),
                        ),
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: kTandyPurple,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Browse licensed Filipino psychiatrists specializing in senior wellness',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B5A9E),
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: kTandyPurple.withAlpha(140),
            ),
          ],
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: kTandyTeal.withAlpha(10),
        border: Border.all(color: kTandyTeal.withAlpha(41)),
      ),
      child: const Text.rich(
        TextSpan(
          text:
              'Tandy is a supportive companion, not a substitute for professional medical advice. ',
          children: <TextSpan>[
            TextSpan(
              text: 'In crisis, call 1553 immediately.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D6060),
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Color(0xFF4D8080), height: 1.75),
      ),
    );
  }
}
