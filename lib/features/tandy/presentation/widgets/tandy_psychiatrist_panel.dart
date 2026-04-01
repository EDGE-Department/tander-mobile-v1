import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Psychiatrist directory panel — "Coming Soon" placeholder with sample cards.
/// Matches web tandy-psychiatrist-panel.tsx.
class TandyPsychiatristPanel extends StatelessWidget {
  const TandyPsychiatristPanel({
    required this.onClose,
    required this.onBack,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: AppColors.borderLight),
            Expanded(
              child: Stack(
                children: [
                  // Sample doctor cards (blurred/faded behind overlay)
                  Opacity(
                    opacity: 0.25,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: _sampleDoctors.map((doc) => _DoctorCard(doctor: doc)).toList(),
                    ),
                  ),
                  // Coming Soon overlay
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 40, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kTandyPurple.withAlpha(20),
                            ),
                            child: Icon(Icons.lock_outline, size: 28, color: kTandyPurple),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Coming Soon',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textStrong),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'These profiles show sample data to preview the directory. Full appointment booking with licensed psychiatrists is on its way.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.6),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: onBack,
                              style: FilledButton.styleFrom(
                                backgroundColor: kTandyPurple,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Go Back', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 16),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: kTandyPurple.withAlpha(20)),
            child: Icon(Icons.person_search, size: 18, color: kTandyPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Find a Psychiatrist', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textStrong), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Licensed \u00B7 DOH verified', style: TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
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

// ── Sample doctor data ────────────────────────────────────────────────────

class _SampleDoctor {
  const _SampleDoctor({required this.name, required this.specialty, required this.hospital, required this.rating, required this.experience, required this.fee});
  final String name, specialty, hospital;
  final double rating;
  final int experience;
  final String fee;
}

const List<_SampleDoctor> _sampleDoctors = [
  _SampleDoctor(name: 'Dr. Maria Santos-Cruz', specialty: 'Geriatric Psychiatry', hospital: 'St. Luke\'s Medical Center', rating: 4.9, experience: 18, fee: '₱2,500/hr'),
  _SampleDoctor(name: 'Dr. Jose Reyes', specialty: 'Anxiety & Depression', hospital: 'Philippine General Hospital', rating: 4.8, experience: 12, fee: '₱2,000/hr'),
  _SampleDoctor(name: 'Dr. Ana Dela Cruz', specialty: 'Sleep Disorders', hospital: 'Makati Medical Center', rating: 4.7, experience: 15, fee: '₱2,800/hr'),
  _SampleDoctor(name: 'Dr. Roberto Lim', specialty: 'Cognitive Behavioral', hospital: 'The Medical City', rating: 4.8, experience: 20, fee: '₱3,000/hr'),
  _SampleDoctor(name: 'Dr. Carmen Villanueva', specialty: 'Senior Wellness', hospital: 'Cardinal Santos Medical', rating: 4.9, experience: 22, fee: '₱2,500/hr'),
  _SampleDoctor(name: 'Dr. Miguel Aquino', specialty: 'Grief & Loss', hospital: 'Asian Hospital', rating: 4.6, experience: 10, fee: '₱2,200/hr'),
];

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});
  final _SampleDoctor doctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: kTandyPurple.withAlpha(25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: kTandyPurple.withAlpha(20)),
            child: Icon(Icons.person, size: 24, color: kTandyPurple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textStrong)),
                Text(doctor.specialty, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.star, size: 12, color: Colors.amber.shade600),
                  Text(' ${doctor.rating}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade700)),
                  const SizedBox(width: 8),
                  Text('${doctor.experience} yrs', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Text(doctor.fee, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTandyPurple)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
