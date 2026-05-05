import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/notifiers/tandy_notifier.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Sponsor type -> accent color lookup.
Color _typeColor(String sponsorType) {
  return switch (sponsorType.toLowerCase()) {
    'health' => kTandyTeal,
    'financial' => const Color(0xFF16A34A),
    'insurance' => kTandyPurple,
    'retail' => kTandyOrange,
    'food' => const Color(0xFFF59E0B),
    _ => kTandyTeal,
  };
}

/// Expandable sponsor card for Tandy chat — verified badge, products,
/// phone and website CTAs.
class SponsorCardWidget extends ConsumerStatefulWidget {
  const SponsorCardWidget({
    required this.sponsorData,
    required this.title,
    required this.isExpanded,
    super.key,
  });

  final SponsorBlockData sponsorData;
  final String title;
  final bool isExpanded;

  @override
  ConsumerState<SponsorCardWidget> createState() => _SponsorCardWidgetState();
}

class _SponsorCardWidgetState extends ConsumerState<SponsorCardWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final sponsorData = widget.sponsorData;
    final color = _typeColor(sponsorData.sponsorType);
    final firstLetter = sponsorData.sponsorName.isNotEmpty
        ? sponsorData.sponsorName[0].toUpperCase()
        : 'S';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3DA)),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  // Logo placeholder
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withAlpha(18),
                      border: Border.all(color: color.withAlpha(77), width: 2.5),
                    ),
                    child: Center(
                      child: Text(firstLetter, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(sponsorData.sponsorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2D2A26)), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.verified, size: 16, color: kTandyTeal),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: color.withAlpha(18)),
                          child: Text(sponsorData.sponsorType.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF9B8F80)),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ExpandedContent(sponsorData: sponsorData, color: color),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _ExpandedContent extends ConsumerWidget {
  const _ExpandedContent({required this.sponsorData, required this.color});
  final SponsorBlockData sponsorData;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Divider(color: Color(0xFFF0EDE7)),
          if (sponsorData.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(sponsorData.message!, style: const TextStyle(fontSize: 15, color: Color(0xFF57534E), height: 1.6)),
            ),
          ...sponsorData.products.map((product) => _ProductRow(product: product, color: color)),
          if (sponsorData.websiteUrl != null || sponsorData.phoneNumber != null) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF0EDE7)),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                if (sponsorData.websiteUrl != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        _pingClick(ref);
                        _launchUrl(sponsorData.websiteUrl!);
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Visit Website'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        fixedSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                if (sponsorData.websiteUrl != null && sponsorData.phoneNumber != null) const SizedBox(width: 10),
                if (sponsorData.phoneNumber != null)
                  SizedBox(
                    width: 56, height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        _pingClick(ref);
                        _launchUrl('tel:${sponsorData.phoneNumber}');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color.withAlpha(77)),
                        foregroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.phone, size: 18),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            sponsorData.disclaimer
                ?? 'Ad \u00B7 This is a paid partnership. Tander does not endorse these products.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xFFC4BBB0)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Fire-and-forget click ping. Skipped on legacy/admin-pushed cards that
  /// don't carry an impression id. Takes [ref] so it works from a
  /// ConsumerWidget (StatelessWidget has no implicit ref).
  void _pingClick(WidgetRef ref) {
    final impressionId = sponsorData.impressionId;
    if (impressionId == null) return;
    ref.read(tandyNotifierProvider.notifier)
        .recordSponsorClick(impressionId: impressionId);
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.color});
  final SponsorProduct product;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0EDE7)),
      ),
      child: Row(
        children: <Widget>[
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(102), border: Border.all(color: color.withAlpha(153)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D2A26))),
                if (product.description != null)
                  Text(product.description!, style: const TextStyle(fontSize: 12, color: Color(0xFF9B8F80))),
              ],
            ),
          ),
          if (product.price != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: color.withAlpha(16)),
              child: Text('\u20B1${product.price!.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ),
        ],
      ),
    );
  }
}
