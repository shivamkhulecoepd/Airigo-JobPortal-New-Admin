// ============================================================
// widgets/shimmer_card.dart
// Skeleton loading card used during data fetch
// ============================================================

import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerJobCard extends StatelessWidget {
  const ShimmerJobCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : AppColors.shimmerBase;
    final highlightColor = isDark
        ? const Color(0xFF334155)
        : AppColors.shimmerHighlight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(height: 10, width: 80),
                      SizedBox(height: 6),
                      _ShimmerBox(height: 16, width: 180),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const _ShimmerBox(height: 24, width: 24), // Save button placeholder
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                _ShimmerBox(height: 12, width: 12), // Location icon
                SizedBox(width: 4),
                _ShimmerBox(height: 12, width: 120), // Location text
                Spacer(),
                _ShimmerBox(height: 18, width: 60), // Job type badge
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(height: 16, width: 100), // CTC placeholder
                _ShimmerBox(height: 28, width: 90), // Apply button placeholder
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                _ShimmerBox(height: 20, width: 50),
                SizedBox(width: 8),
                _ShimmerBox(height: 20, width: 70),
                SizedBox(width: 8),
                _ShimmerBox(height: 20, width: 60),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                _ShimmerBox(height: 10, width: 40), // Time ago
                SizedBox(width: 8),
                _ShimmerBox(height: 10, width: 80), // Applicants
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  const _ShimmerBox({required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Generic shimmer list for any loading state
class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, __) => const ShimmerJobCard(),
    );
  }
}

class ShimmerCompanyCard extends StatelessWidget {
  const ShimmerCompanyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : AppColors.shimmerBase;
    final highlightColor =
        isDark ? const Color(0xFF334155) : AppColors.shimmerHighlight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            // Company Logo Placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            // Company Details Placeholder
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(height: 16, width: 150),
                  SizedBox(height: 8),
                  _ShimmerBox(height: 12, width: 100),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      _ShimmerBox(height: 10, width: 10),
                      SizedBox(width: 4),
                      _ShimmerBox(height: 10, width: 80),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Open Positions Badge Placeholder
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerCompanyList extends StatelessWidget {
  final int count;
  const ShimmerCompanyList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, __) => const ShimmerCompanyCard(),
    );
  }
}

