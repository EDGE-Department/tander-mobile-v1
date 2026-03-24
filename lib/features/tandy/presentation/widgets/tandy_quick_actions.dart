import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

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
            border: Border.all(color: const Color(0xFFE5E1DC).withAlpha(153)),
            boxShadow: <BoxShadow>[
              BoxShadow(color: glowColor, blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: <Widget>[
              // Colored panel
              Container(
                width: 72,
                constraints: const BoxConstraints(minHeight: 84),
                decoration: BoxDecoration(gradient: panelGradient),
                child: Center(
                  child: Icon(icon, size: 30, color: Colors.white),
                ),
              ),

              // Content panel
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x0D000000),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0x14000000)),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.access_time, size: 9, color: Color(0xFF9CA3AF)),
                                const SizedBox(width: 3),
                                Text(durationLabel, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Text('Begin session', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTandyTeal)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 11, color: kTandyTeal),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
