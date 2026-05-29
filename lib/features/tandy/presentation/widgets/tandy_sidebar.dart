import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Desktop sidebar for the Tandy hub — avatar hero, wellness nav items,
/// status badge, and clear conversation button.
class TandySidebar extends StatelessWidget {
  const TandySidebar({
    required this.messageCount,
    required this.statusLabel,
    required this.onChatTap,
    required this.onBreatheTap,
    required this.onMeditateTap,
    required this.onSupportTap,
    required this.onClearTap,
    super.key,
  });

  final int messageCount;
  final String statusLabel;
  final VoidCallback onChatTap;
  final VoidCallback onBreatheTap;
  final VoidCallback onMeditateTap;
  final VoidCallback onSupportTap;
  final VoidCallback onClearTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.white, Color(0xFFFDFBF9)],
        ),
        border: Border(right: BorderSide(color: Color(0xFFEDE8E0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Avatar hero
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.5, -0.5),
                end: Alignment(0.5, 1),
                colors: <Color>[Color(0xFFFFF9F2), Color(0xFFFEF2E0)],
              ),
              border: Border(bottom: BorderSide(color: Color(0x1AE67E22))),
            ),
            child: Column(
              children: <Widget>[
                Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: <Color>[Colors.white, Color(0xFFFFF6E8)],
                        ),
                        border: Border.all(
                          color: kTandyOrange.withAlpha(51),
                          width: 2,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: kTandyOrange.withAlpha(41),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/icons/tandy_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        border: Border.all(
                          color: const Color(0xFFFEF2E0),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tandy',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFF7C3910),
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'YOUR WELLNESS COMPANION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB87840),
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: <Widget>[
                // Chat CTA
                _SidebarChatButton(
                  messageCount: messageCount,
                  onTap: onChatTap,
                ),
                const SizedBox(height: 12),
                // Wellness header
                Row(
                  children: <Widget>[
                    Container(
                      width: 20,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: <Color>[kTandyTeal, kTandyTeal.withAlpha(77)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'WELLNESS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: Color(0xFF9A9080),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SidebarFeature(
                  icon: Icons.spa,
                  label: 'Breathe',
                  sub: 'Calm your mind \u00B7 4 min',
                  color: kTandyTeal,
                  onTap: onBreatheTap,
                ),
                const SizedBox(height: 6),
                _SidebarFeature(
                  icon: Icons.self_improvement,
                  label: 'Meditate',
                  sub: 'Find stillness \u00B7 5-10 min',
                  color: kTandyPurple,
                  onTap: onMeditateTap,
                ),
                const SizedBox(height: 6),
                _SidebarFeature(
                  icon: Icons.person_outline,
                  label: 'Support',
                  sub: 'Mental health help',
                  color: kTandyBlue,
                  onTap: onSupportTap,
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEDE8E0))),
              color: Color(0x99FAF8F5),
            ),
            child: Column(
              children: <Widget>[
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: kTandyTeal.withAlpha(12),
                    border: Border.all(color: kTandyTeal.withAlpha(41)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kTandyTeal,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: kTandyTeal.withAlpha(144),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF0B7D73),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: kTandyTeal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Clear button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onClearTap,
                    icon: const Icon(Icons.delete_outline, size: 12),
                    label: const Text(
                      'Clear conversation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB0A090),
                      side: const BorderSide(color: Color(0xFFEDE8E0)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

class _SidebarChatButton extends StatelessWidget {
  const _SidebarChatButton({required this.messageCount, required this.onTap});
  final int messageCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kTandyOrange.withAlpha(77), width: 2),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFFFF5E8), Color(0xFFFEF0E0)],
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFF9BB3C), kTandyOrange],
                  ),
                ),
                child: const Icon(Icons.near_me, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3910),
                      ),
                    ),
                    Text(
                      'Talk with Tandy now',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB87840)),
                    ),
                  ],
                ),
              ),
              if (messageCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: kTandyOrange,
                  ),
                  child: Text(
                    '$messageCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _SidebarFeature extends StatelessWidget {
  const _SidebarFeature({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: color.withAlpha(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(36)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color,
                ),
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF8C8070),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 13, color: color.withAlpha(115)),
            ],
          ),
        ),
      ),
    );
  }
}
