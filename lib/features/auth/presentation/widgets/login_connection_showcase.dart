import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated "NEW CONNECTION" showcase card + rotating testimonials.
///
/// Replicates the web's glass-morphic connection-matching animation
/// that cycles through random Filipino senior profile pairs with a
/// progress bar shimmer, followed by a testimonial carousel.
class ConnectionShowcase extends StatelessWidget {
  const ConnectionShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ConnectionCard(),
        SizedBox(height: 16),
        _TestimonialCard(),
      ],
    );
  }
}

// ── Data ────────────────────────────────────────────────────────────

class _ProfileData {
  const _ProfileData(this.name, this.age, this.city, this.gradientColors);
  final String name;
  final int age;
  final String city;
  final List<Color> gradientColors;
}

const _profiles = <_ProfileData>[
  _ProfileData('Maricel', 64, 'QC', [Color(0xFFF97316), Color(0xFFFB923C)]),
  _ProfileData('Roberto', 68, 'Makati', [Color(0xFF14B8A6), Color(0xFF2DD4BF)]),
  _ProfileData('Ligaya', 62, 'Pasig', [Color(0xFFA855F7), Color(0xFFC084FC)]),
  _ProfileData('Ernesto', 71, 'Manila', [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
  _ProfileData('Perla', 65, 'Cavite', [Color(0xFFEC4899), Color(0xFFF472B6)]),
  _ProfileData('Domingo', 69, 'Taguig', [Color(0xFF22C55E), Color(0xFF4ADE80)]),
  _ProfileData('Celia', 63, 'Paranaque', [Color(0xFFEAB308), Color(0xFFFACC15)]),
  _ProfileData('Vicente', 72, 'Batangas', [Color(0xFF06B6D4), Color(0xFF22D3EE)]),
];

const _testimonials = <({String quote, String author, String location})>[
  (
    quote: 'I found a true companion here. We share meals, stories, '
        'and morning walks every day.',
    author: 'Maricel C.',
    location: 'Quezon City',
  ),
  (
    quote: 'Tander gave me a second chance at friendship. '
        'I feel young again at 71.',
    author: 'Ernesto V.',
    location: 'Manila',
  ),
  (
    quote: 'My children were happy when I joined. '
        'Now I have lunch dates every week!',
    author: 'Perla R.',
    location: 'Cavite',
  ),
];

// ── Connection Card ─────────────────────────────────────────────────

class _ConnectionCard extends StatefulWidget {
  const _ConnectionCard();

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;
  final _random = math.Random();
  int _leftIndex = 0;
  int _rightIndex = 1;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _pickRandomPair();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _startCycle();
  }

  void _pickRandomPair() {
    _leftIndex = _random.nextInt(_profiles.length);
    _rightIndex = (_leftIndex + 1 + _random.nextInt(_profiles.length - 1)) %
        _profiles.length;
  }

  void _startCycle() {
    _controller.forward().then((_) {
      if (!mounted) return;
      setState(() => _isConnected = true);
      Future<void>.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        setState(() {
          _isConnected = false;
          _pickRandomPair();
        });
        _controller.reset();
        _startCycle();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildAvatarRow(),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (_, _) => _ShimmerProgressBar(
              progress: _progressAnimation.value,
              isComplete: _isConnected,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected ? '\u2713 connected' : 'matching...',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isConnected
                  ? const Color(0xFF34D399)
                  : Colors.white.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'NEW CONNECTION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
            color: Colors.white.withValues(alpha: 0.60),
          ),
        ),
        const Spacer(),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF34D399),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'just now',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProfileAvatar(profile: _profiles[_leftIndex]),
        const SizedBox(width: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isConnected
              ? const Icon(
                  Icons.check_circle,
                  key: ValueKey('check'),
                  size: 18,
                  color: Color(0xFF34D399),
                )
              : const Icon(
                  Icons.favorite,
                  key: ValueKey('heart'),
                  size: 18,
                  color: Color(0xFFFCA5A5),
                ),
        ),
        const SizedBox(width: 16),
        _ProfileAvatar(profile: _profiles[_rightIndex]),
      ],
    );
  }
}

// ── Profile Avatar ──────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});
  final _ProfileData profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: profile.gradientColors,
            ),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          '${profile.name}, ${profile.age}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.80),
          ),
        ),
        Text(
          profile.city,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

// ── Shimmer Progress Bar ────────────────────────────────────────────

class _ShimmerProgressBar extends StatelessWidget {
  const _ShimmerProgressBar({
    required this.progress,
    required this.isComplete,
  });
  final double progress;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            Container(color: Colors.white.withValues(alpha: 0.10)),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isComplete
                        ? const [Color(0xFF34D399), Color(0xFF34D399)]
                        : const [Color(0xFFF97316), Color(0xFF14B8A6)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Testimonial Card ────────────────────────────────────────────────

class _TestimonialCard extends StatefulWidget {
  const _TestimonialCard();

  @override
  State<_TestimonialCard> createState() => _TestimonialCardState();
}

class _TestimonialCardState extends State<_TestimonialCard> {
  int _currentIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _rotationTimer = Timer.periodic(
      const Duration(milliseconds: 7600),
      (_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = (_currentIndex + 1) % _testimonials.length;
        });
      },
    );
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testimonial = _testimonials[_currentIndex];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Column(
          key: ValueKey(_currentIndex),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (_) => const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '"${testimonial.quote}"',
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${testimonial.author}, ${testimonial.location}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Member since 2024',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
