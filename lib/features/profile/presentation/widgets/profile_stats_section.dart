import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../data/providers/profile_stats_providers.dart';

class ProfileStatsSection extends ConsumerWidget {
  final UserProfileEntity? profile;

  const ProfileStatsSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrCodes = ref.watch(userQRCodesProvider);
    final scanHistory = ref.watch(userScanHistoryProvider);
    final orders = ref.watch(userOrdersProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.qr_code_rounded,
                  title: 'QR Codes',
                  value: qrCodes.when(
                    data: (codes) => codes.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  color: const Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scans',
                  value: scanHistory.when(
                    data: (scans) => scans.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  color: const Color(0xFF00FF88),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.shopping_bag_rounded,
                  title: 'Orders',
                  value: orders.when(
                    data: (orderList) => orderList.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Days Active',
                  value: _calculateDaysActive(),
                  color: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _calculateDaysActive() {
    if (profile?.createdAt == null) return '0';
    
    final now = DateTime.now();
    final difference = now.difference(profile!.createdAt);
    return difference.inDays.toString();
  }
}