import 'package:flutter/material.dart';

/// Split-panel activity cards for breathing and meditation.
class TandyQuickActions extends StatelessWidget {
  const TandyQuickActions({
    required this.onBreathingTap,
    required this.onMeditationTap,
    super.key,
  });

  final VoidCallback onBreathingTap;
  final VoidCallback onMeditationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _ActionCard(
          icon: Icons.spa,
          title: 'Breathing',
          subtitle: 'Calm exercises for anxious moments',
          durationLabel: '5 min',
          panelGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0ECFB8), Color(0xFF0B7D73)],
          ),
          glowColor: const Color(0x470ECFB8),
          onTap: onBreathingTap,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.self_improvement,
          title: 'Meditation',
          subtitle: 'Find peace and quiet the mind',
          durationLabel: '10 min',
          panelGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFA855F7), Color(0xFFDB2777)],
          ),
          glowColor: const Color(0x47A855F7),
          onTap: onMeditationTap,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.panelGradient,
    required this.glowColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String durationLabel;
  final LinearGradient panelGradient;
  final Color glowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E1DC)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: <Widget>[
              Container(
                width: 72,
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(gradient: panelGradient),
                child: Center(child: Icon(icon, size: 32, color: Colors.white)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$subtitle · $durationLabel',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7B7068),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
