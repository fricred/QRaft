import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_providers.dart';

/// Indicator showing QR code usage (e.g., "3/5 QR Codes")
/// Colors change based on remaining capacity
class QRLimitIndicator extends ConsumerWidget {
  final bool compact;

  const QRLimitIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCount = ref.watch(currentQRCountProvider);
    final remaining = ref.watch(remainingQRCodesProvider);
    final hasPro = ref.watch(hasProAccessProvider);
    final limits = ref.watch(planLimitsProvider);

    // Pro users have unlimited
    if (hasPro) {
      return _buildUnlimited(context);
    }

    final maxQR = limits.maxQRCodes;
    final color = _getStatusColor(remaining, maxQR);

    if (compact) {
      return _buildCompact(context, currentCount, maxQR, color);
    }

    return _buildFull(context, currentCount, maxQR, remaining, color);
  }

  Widget _buildUnlimited(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.all_inclusive,
            size: 16,
            color: Color(0xFF00FF88),
          ),
          const SizedBox(width: 6),
          Text(
            'Unlimited QR Codes',
            style: TextStyle(
              color: const Color(0xFF00FF88),
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    int current,
    int max,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$current/$max',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFull(
    BuildContext context,
    int current,
    int max,
    int remaining,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                'QR Codes',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$current/$max',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining > 0
                ? '$remaining remaining'
                : 'Limit reached',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int remaining, int max) {
    if (remaining <= 0) {
      return const Color(0xFFEF4444); // Red
    } else if (remaining <= 2) {
      return const Color(0xFFF59E0B); // Orange/Amber
    } else {
      return const Color(0xFF22C55E); // Green
    }
  }
}
