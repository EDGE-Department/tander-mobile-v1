import 'package:flutter/material.dart';

/// Warm amber warning banner for food safety notices.
class SafetyNoticeBarWidget extends StatelessWidget {
  const SafetyNoticeBarWidget({required this.notices, super.key});

  final List<String> notices;

  @override
  Widget build(BuildContext context) {
    if (notices.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
        ),
        border: Border.all(color: const Color(0x29C77D1A)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x14C77D1A), blurRadius: 12),
        ],
      ),
      child: Stack(
        children: <Widget>[
          // Left accent bar
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFF59E0B), Color(0xFFE67E22)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header
                Row(
                  children: <Widget>[
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: <Color>[
                            const Color(0xFFFBBF24).withAlpha(56),
                            const Color(0xFFF59E0B).withAlpha(31),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFA06415)),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Safety Notice',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF7C2D12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Notice list
                ...notices.map((notice) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: <Color>[Color(0xFFF59E0B), Color(0xFFD97706)]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(notice, style: const TextStyle(fontSize: 14, color: Color(0xFF78350F), height: 1.55)),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
