import 'dart:math' show log;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/glass_button.dart';
import '../main/main_scaffold.dart';
import 'presentation/providers/qr_library_providers.dart';
import '../qr_generator/domain/entities/qr_code_entity.dart';
import '../qr_generator/presentation/pages/url_qr_screen.dart';
import '../qr_generator/presentation/pages/text_qr_screen.dart';
import '../qr_generator/presentation/pages/personal_info_qr_screen.dart';
import '../qr_generator/presentation/pages/wifi_qr_screen.dart';
import '../qr_generator/presentation/pages/email_qr_screen.dart';
import '../qr_generator/presentation/pages/location_qr_screen.dart';
import 'presentation/pages/qr_code_details_screen.dart';
import '../auth/data/providers/supabase_auth_provider.dart';
import '../../l10n/app_localizations.dart';

class QRLibraryScreen extends ConsumerStatefulWidget {
  const QRLibraryScreen({super.key});

  @override
  ConsumerState<QRLibraryScreen> createState() => _QRLibraryScreenState();
}

class _QRLibraryScreenState extends ConsumerState<QRLibraryScreen> with TickerProviderStateMixin {
  int _selectedTab = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.qrLibrary,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.manageQRCodes,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search button
                      IconButton(
                        onPressed: () => _showSearchDialog(),
                        icon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2E2E),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tab selector
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(l10n.myQRs, 0),
                        _buildTabButton(l10n.favorites, 1),
                        _buildTabButton(l10n.recent, 2),
                      ],
                    ),
                  ),
                ],
              ).animate()
                .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                .slideY(begin: -0.15, duration: 300.ms, curve: Curves.easeOutQuart),
            ),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                children: [
                  _buildMyQRsTab(l10n),
                  _buildFavoritesTab(l10n),
                  _buildRecentTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(navigationIndexProvider.notifier).state = 1,
        backgroundColor: const Color(0xFF00FF88),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ).animate()
        .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOutCubic)
        .scale(begin: const Offset(0.7, 0.7), duration: 400.ms, delay: 200.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          transform: Matrix4.identity()..scale(isSelected ? 1.0 : 0.98),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyQRsTab(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final stats = ref.watch(qrLibraryStatsProvider);
                  return _buildStatsCard(l10n.totalQRs, '${stats['total']}', Icons.qr_code_rounded);
                },
              ),
              const SizedBox(width: 16),
              Consumer(
                builder: (context, ref, child) {
                  final stats = ref.watch(qrLibraryStatsProvider);
                  return _buildStatsCard(l10n.thisMonth, '${stats['thisMonth']}', Icons.calendar_month_rounded);
                },
              ),
            ],
          ).animate()
            .fadeIn(duration: 300.ms, delay: 100.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.15, duration: 300.ms, delay: 100.ms, curve: Curves.easeOutQuart),
          
          const SizedBox(height: 24),
          
          // QR Grid
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final userQRCodes = ref.watch(userQRCodesProvider);
                
                return userQRCodes.when(
                  data: (qrCodes) {
                    if (qrCodes.isEmpty) {
                      return _buildEmptyQRLibrary(l10n);
                    }
                    
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75, // Polaroid aspect ratio - taller cards
                      ),
                      itemCount: qrCodes.length,
                      itemBuilder: (context, index) {
                        final delay = (100 + (40.0 * log(index + 2))).toInt();
                        return _buildEntityQRCard(qrCodes[index], l10n).animate()
                          .fadeIn(
                            duration: 300.ms,
                            delay: delay.ms,
                            curve: Curves.easeOutCubic,
                          )
                          .slideY(
                            begin: 0.15,
                            duration: 300.ms,
                            delay: delay.ms,
                            curve: Curves.easeOutQuart,
                          )
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            duration: 300.ms,
                            delay: delay.ms,
                          );
                      },
                    );
                  },
                  loading: () => GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75, // Polaroid aspect ratio - taller cards
                    ),
                    itemCount: 6, // Placeholder count
                    itemBuilder: (context, index) {
                      final delay = (100 + (40.0 * log(index + 2))).toInt();
                      return _buildQRCardSkeleton().animate()
                        .fadeIn(
                          duration: 300.ms,
                          delay: delay.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.15,
                          duration: 300.ms,
                          delay: delay.ms,
                          curve: Curves.easeOutQuart,
                        );
                    },
                  ),
                  error: (error, _) => _buildEmptyQRLibrary(l10n),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final favoriteQRs = ref.watch(favoriteQRCodesProvider);

        if (favoriteQRs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon/Illustration - Standardized animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ).animate()
                  .scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 24),

                // Title - Standardized animation (200ms delay)
                Text(
                  l10n.noFavoritesYet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, duration: 400.ms, delay: 200.ms, curve: Curves.easeOutQuart),

                const SizedBox(height: 8),

                // Subtitle - Standardized animation (300ms delay)
                Text(
                  l10n.starFavoriteQRCodes,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                  .fadeIn(duration: 300.ms, delay: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.1, duration: 300.ms, delay: 300.ms, curve: Curves.easeOutQuart),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Polaroid aspect ratio - taller cards
            ),
            itemCount: favoriteQRs.length,
            itemBuilder: (context, index) {
              final delay = (100 + (40.0 * log(index + 2))).toInt();
              return _buildEntityQRCard(favoriteQRs[index], l10n).animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: delay.ms,
                  curve: Curves.easeOutCubic,
                )
                .slideY(
                  begin: 0.15,
                  duration: 300.ms,
                  delay: delay.ms,
                  curve: Curves.easeOutQuart,
                )
                .scale(
                  begin: const Offset(0.95, 0.95),
                  duration: 300.ms,
                  delay: delay.ms,
                );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentTab(AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final recentQRs = ref.watch(recentQRCodesProvider);

        if (recentQRs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon/Illustration - Standardized animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF1A73E8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ).animate()
                  .scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 24),

                // Title - Standardized animation (200ms delay)
                Text(
                  l10n.noRecentQRs,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, duration: 400.ms, delay: 200.ms, curve: Curves.easeOutQuart),

                const SizedBox(height: 8),

                // Subtitle - Standardized animation (300ms delay)
                Text(
                  l10n.recentQRCodesAppearHere,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                  .fadeIn(duration: 300.ms, delay: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.1, duration: 300.ms, delay: 300.ms, curve: Curves.easeOutQuart),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView.builder(
            itemCount: recentQRs.length,
            itemBuilder: (context, index) {
              final delay = (100 + (40.0 * log(index + 2))).toInt();
              return _buildRecentEntityQRCard(recentQRs[index], l10n).animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: delay.ms,
                  curve: Curves.easeOutCubic,
                )
                .slideX(
                  begin: 0.15,
                  duration: 300.ms,
                  delay: delay.ms,
                  curve: Curves.easeOutQuart,
                );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF00FF88),
              size: 24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  void _showSearchDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A73E8), Color(0xFF00FF88)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Search QR Codes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name, type, or content...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                  ),
                  onSubmitted: (value) {
                    Navigator.of(context).pop();
                    // TODO: Implement search functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Search functionality will be implemented soon'),
                        backgroundColor: const Color(0xFF2E2E2E),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryGlassButton(
                        text: l10n.cancel,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryGlassButton(
                        text: l10n.search,
                        icon: Icons.search_rounded,
                        onPressed: () {
                          Navigator.of(context).pop();
                          // TODO: Implement search functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Search functionality will be implemented soon'),
                              backgroundColor: const Color(0xFF2E2E2E),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyQRLibrary(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Illustration - Standardized animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF1A73E8)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.library_books_rounded,
              color: Colors.white,
              size: 40,
            ),
          ).animate()
            .scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 24),

          // Title - Standardized animation (200ms delay)
          Text(
            l10n.noQRCodesYet,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.15, duration: 400.ms, delay: 200.ms, curve: Curves.easeOutQuart),

          const SizedBox(height: 8),

          // Subtitle - Standardized animation (300ms delay)
          Text(
            l10n.createFirstQRCode,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(duration: 300.ms, delay: 300.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.1, duration: 300.ms, delay: 300.ms, curve: Curves.easeOutQuart),

          const SizedBox(height: 24),

          // Action Button - Standardized animation (400ms delay)
          PrimaryGlassButton(
            text: l10n.createQRCode,
            icon: Icons.add_rounded,
            onPressed: () => ref.read(navigationIndexProvider.notifier).state = 1,
          ).animate()
            .fadeIn(duration: 300.ms, delay: 400.ms, curve: Curves.easeOutCubic)
            .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, delay: 400.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildQRCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }


  IconData _getQRTypeIcon(String qrType) {
    switch (qrType.toLowerCase()) {
      case 'url': return Icons.link_rounded;
      case 'wifi': return Icons.wifi_rounded;
      case 'email': return Icons.email_rounded;
      case 'phone': return Icons.phone_rounded;
      case 'sms': return Icons.sms_rounded;
      case 'vcard': return Icons.person_rounded;
      case 'location': return Icons.location_on_rounded;
      case 'text': default: return Icons.text_fields_rounded;
    }
  }

  Color _getQRTypeColor(String qrType) {
    switch (qrType.toLowerCase()) {
      case 'url': return const Color(0xFF1A73E8);
      case 'wifi': return const Color(0xFF8B5CF6);
      case 'email': return const Color(0xFFF59E0B);
      case 'phone': return const Color(0xFF10B981);
      case 'sms': return const Color(0xFFEF4444);
      case 'vcard': return const Color(0xFF00FF88);
      case 'location': return const Color(0xFF10B981);
      case 'text': default: return const Color(0xFF6366F1);
    }
  }

  String _formatTimeAgo(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return l10n.daysAgoShort(difference.inDays);
    } else if (difference.inHours > 0) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return l10n.minutesAgo(difference.inMinutes);
    } else {
      return l10n.justNow;
    }
  }

  Widget _buildRecentEntityQRCard(QRCodeEntity qrEntity, AppLocalizations l10n) {
    final qrType = qrEntity.type.identifier;
    final title = qrEntity.name;
    final createdAt = qrEntity.createdAt;
    final timeAgo = _formatTimeAgo(createdAt, l10n);
    
    final iconData = _getQRTypeIcon(qrType);
    final color = _getQRTypeColor(qrType);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEntityQRDetails(qrEntity),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  iconData,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      qrEntity.displayData,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                timeAgo,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntityQRCard(QRCodeEntity qrEntity, AppLocalizations l10n) {
    final title = qrEntity.name;
    final createdAt = qrEntity.createdAt;
    final timeAgo = _formatTimeAgo(createdAt, l10n);
    final qrType = qrEntity.type.identifier;
    final iconData = _getQRTypeIcon(qrType);
    final color = _getQRTypeColor(qrType);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Polaroid Photo Section - Rectangular Icon Area
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _showEntityQRDetails(qrEntity),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: color,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          
          // Polaroid Caption Section - Title (Single Line)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 28,
            child: GestureDetector(
              onTap: () => _showEntityQRDetails(qrEntity),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          
          // Time info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                timeAgo,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ),
          ),
          
          // Action Buttons Section
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Favorite button
                GestureDetector(
                  onTap: () => _toggleFavorite(qrEntity),
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Icon(
                      qrEntity.isFavorite 
                        ? Icons.favorite_rounded 
                        : Icons.favorite_border_rounded,
                      color: qrEntity.isFavorite 
                        ? const Color(0xFFEF4444) 
                        : Colors.grey[400],
                      size: 18,
                    ),
                  ),
                ),
                
                // Share button
                GestureDetector(
                  onTap: () => _shareQRCode(qrEntity),
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.share_rounded,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                  ),
                ),
                
                // More actions menu
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                  ),
                  color: const Color(0xFF2E2E2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'preview',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(l10n.preview, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(l10n.edit, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(l10n.share, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: const Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 8),
                          Text(l10n.delete, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (String value) => _handleMenuAction(value, qrEntity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEntityQRDetails(QRCodeEntity qrEntity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRCodeDetailsScreen(qrEntity: qrEntity),
      ),
    );
  }

  void _toggleFavorite(QRCodeEntity qrEntity) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // First, ensure the controller has the latest data
      final user = ref.read(authStateProvider);
      if (user != null) {
        // Load user QR codes to ensure controller state is synced
        await ref.read(qrLibraryControllerProvider.notifier).loadUserQRCodes(user.id);
      }
      
      // Toggle favorite using the controller
      await ref.read(qrLibraryControllerProvider.notifier).toggleFavorite(qrEntity.id);
      
      // Refresh the user QR codes provider to get updated data
      ref.invalidate(userQRCodesProvider);
      
      // Show success feedback
      if (mounted) {
        final isFavorite = !qrEntity.isFavorite;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite 
                ? l10n.addedToFavorites(qrEntity.name) 
                : l10n.removedFromFavorites(qrEntity.name),
            ),
            backgroundColor: isFavorite 
              ? const Color(0xFF00FF88)
              : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('not found')) {
          errorMessage = l10n.error('QR code not found. It may have been deleted.');
          // Refresh the list to remove stale QR codes
          ref.invalidate(userQRCodesProvider);
        } else {
          errorMessage = l10n.failedToUpdateFavorite(qrEntity.name);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: l10n.retry,
              textColor: Colors.white,
              onPressed: () => _toggleFavorite(qrEntity),
            ),
          ),
        );
      }
    }
  }

  void _shareQRCode(QRCodeEntity qrEntity) {
    final l10n = AppLocalizations.of(context)!;
    // TODO: Implement QR code sharing with image generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.sharingQRCode(qrEntity.name)),
        backgroundColor: const Color(0xFF00FF88),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, QRCodeEntity qrEntity) {
    switch (action) {
      case 'preview':
        _showEntityQRDetails(qrEntity);
        break;
      case 'edit':
        _editQRCode(qrEntity);
        break;
      case 'share':
        _shareQRCode(qrEntity);
        break;
      case 'delete':
        _confirmDeleteQR(qrEntity);
        break;
    }
  }

  void _editQRCode(QRCodeEntity qrEntity) {
    // Import these screens at the top of the file
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _getEditScreenForQRType(qrEntity),
      ),
    ).then((updatedQR) {
      // Refresh the list when returning
      if (updatedQR != null && mounted) {
        ref.invalidate(userQRCodesProvider);
      }
    });
  }

  Widget _getEditScreenForQRType(QRCodeEntity qrEntity) {
    switch (qrEntity.type.identifier) {
      case 'url':
        return URLQRScreen(editingQRCode: qrEntity);
      case 'text':
        return TextQRScreen(editingQRCode: qrEntity);
      case 'vcard':
        return PersonalInfoQRScreen(editingQRCode: qrEntity);
      case 'wifi':
        return WiFiQRScreen(editingQRCode: qrEntity);
      case 'email':
        return EmailQRScreen(editingQRCode: qrEntity);
      case 'geo':  // ← Location QR identifier is 'geo', not 'location'
        return LocationQRScreen(editingQRCode: qrEntity);
      default:
        return _showComingSoonMessage(qrEntity.type.identifier);
    }
  }

  Widget _showComingSoonMessage(String typeName) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Color(0xFF00FF88),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Edit $typeName QR Codes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon! Currently only URL and Text QR codes can be edited.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SecondaryGlassButton(
              text: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              width: 120,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteQR(QRCodeEntity qrEntity) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.deleteQRCode,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deleteQRConfirmation(qrEntity.name),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryGlassButton(
                        text: l10n.cancel,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassButton(
                        text: l10n.delete,
                        icon: Icons.delete_rounded,
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _performDelete(qrEntity);
                        },
                        gradientColors: const [
                          Color(0xFFEF4444),
                          Color(0xFFDC2626),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performDelete(QRCodeEntity qrEntity) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(qrLibraryControllerProvider.notifier).deleteQRCode(qrEntity.id);
      
      // Refresh the user QR codes list
      ref.invalidate(userQRCodesProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deletedSuccessfully(qrEntity.name)),
            backgroundColor: const Color(0xFF00FF88),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToDeleteQRCode(e.toString())),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

}