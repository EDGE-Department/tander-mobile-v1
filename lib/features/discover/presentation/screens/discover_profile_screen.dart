/// Full profile screen for a discovery candidate.
///
/// Reached by tapping "View full profile" on the swipe card or the
/// info action button. Photo carousel hero is in
/// `discover_profile_hero.dart`.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/discover/presentation/notifiers/discover_notifier.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_profile_hero.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_badge.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';

class DiscoverProfileScreen extends ConsumerStatefulWidget {
  const DiscoverProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<DiscoverProfileScreen> createState() =>
      _DiscoverProfileScreenState();
}

class _DiscoverProfileScreenState
    extends ConsumerState<DiscoverProfileScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoPage = 0;
  bool _isSending = false;
  bool _isPassing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _allPhotos(DiscoveryCandidate candidate) {
    return [
      if (candidate.profilePhotoUrl != null &&
          candidate.profilePhotoUrl!.isNotEmpty)
        candidate.profilePhotoUrl!,
      ...candidate.additionalPhotos,
    ];
  }

  Future<void> _handleConnect() async {
    setState(() => _isSending = true);
    await ref.read(discoverNotifierProvider.notifier).likeCurrentProfile();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handlePass() async {
    setState(() => _isPassing = true);
    await ref.read(discoverNotifierProvider.notifier).passCurrentProfile();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(
      discoverProfileProvider(int.parse(widget.userId)),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: profileAsync.when(
        loading: _buildLoadingState,
        error: (error, _) => _buildErrorState(),
        data: _buildProfileContent,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Expanded(flex: 3, child: SkeletonCard(variant: SkeletonVariant.fullCard)),
            SizedBox(height: AppSpacing.lg),
            SkeletonCard(variant: SkeletonVariant.title),
            SizedBox(height: AppSpacing.sm),
            SkeletonCard(variant: SkeletonVariant.text),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load this profile.',
              style: AppTypography.body.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.md),
            TanderButton(
              label: 'Back to Discover',
              variant: TanderButtonVariant.ghost,
              size: TanderButtonSize.compact,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(DiscoveryCandidate candidate) {
    final allPhotos = _allPhotos(candidate);
    final displayLocation = [candidate.city, candidate.country]
        .where((part) => part != null && part!.isNotEmpty)
        .join(', ');

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DiscoverProfileHero(
                  candidate: candidate,
                  allPhotos: allPhotos,
                  pageController: _pageController,
                  currentPhotoPage: _currentPhotoPage,
                  onPageChanged: (index) {
                    setState(() => _currentPhotoPage = index);
                  },
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                sliver: SliverList.list(
                  children: [
                    _buildBadgeRow(candidate),
                    const SizedBox(height: AppSpacing.md),
                    if (candidate.bio != null &&
                        candidate.bio!.isNotEmpty) ...[
                      _buildSection(
                        label: 'About',
                        child: Text(
                          candidate.bio!,
                          style: AppTypography.body.copyWith(height: 1.6),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (displayLocation.isNotEmpty) ...[
                      _buildSection(
                        label: 'Location',
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsFill.mapPin, size: 16, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.xs),
                            Text(displayLocation, style: AppTypography.body),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (candidate.interests.isNotEmpty) ...[
                      _buildSection(
                        label: 'Interests',
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: candidate.interests.map(_buildInterestChip).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (candidate.additionalPhotos.isNotEmpty)
                      _buildSection(
                        label: 'More Photos',
                        child: _buildPhotoGrid(candidate.additionalPhotos),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildActionBar(candidate),
      ],
    );
  }

  Widget _buildBadgeRow(DiscoveryCandidate candidate) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (candidate.isOnline)
          const TanderBadge(label: 'Online', variant: TanderBadgeVariant.success),
        if (candidate.hasExistingConnection)
          const TanderBadge(label: 'Connection requested', variant: TanderBadgeVariant.info),
      ],
    );
  }

  Widget _buildSection({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }

  Widget _buildInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(interest, style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPhotoGrid(List<String> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
      ),
      itemCount: photos.length.clamp(0, 6),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: AppRadius.borderMd,
          child: CachedNetworkImage(
            imageUrl: photos[index],
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.subtle),
            errorWidget: (_, _, _) => Container(
              color: AppColors.subtle,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBar(DiscoveryCandidate candidate) {
    final bool isDisabled = _isSending || _isPassing;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: isDisabled ? null : _handlePass,
              child: Opacity(
                opacity: isDisabled ? 0.5 : 1.0,
                child: Container(
                  width: AppSpacing.touchComfortable,
                  height: AppSpacing.touchComfortable,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(PhosphorIconsBold.x, size: 24, color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TanderButton(
                label: _isSending ? 'Sending...' : 'Connect',
                icon: PhosphorIconsBold.userPlus,
                isLoading: _isSending,
                isDisabled: isDisabled,
                onPressed: _handleConnect,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
