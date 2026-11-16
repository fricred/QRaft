import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/widgets/glass_button.dart';
import '../../shared/widgets/animated_favorite_button.dart';
import '../main/main_scaffold.dart';
import 'presentation/providers/qr_library_providers.dart';
import '../qr_generator/domain/entities/qr_code_entity.dart';
import '../qr_generator/presentation/controllers/qr_customization_controller.dart';
import '../qr_generator/presentation/pages/qr_canvas_editor_screen.dart';
import 'presentation/pages/qr_code_details_screen.dart';
import '../dynamic_qr/presentation/checkout_screen.dart';
import '../dynamic_qr/presentation/detail_screen.dart';
import '../dynamic_qr/presentation/manager_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../marketplace/presentation/providers/marketplace_providers.dart';
import '../../l10n/app_localizations.dart';

class QRLibraryScreen extends ConsumerStatefulWidget {
  const QRLibraryScreen({super.key});

  @override
  ConsumerState<QRLibraryScreen> createState() => _QRLibraryScreenState();
}

class _QRLibraryScreenState extends ConsumerState<QRLibraryScreen> {
  int _selectedTab = 0;
  final PageController _pageController = PageController();
  final Set<String> _processingFavorites = {};

  /// Cards that already played their entrance animation. Without this,
  /// every scroll-back re-runs the flutter_animate chain (new element =
  /// new controllers) and cards flicker on viewport re-entry.
  final Set<String> _animatedCardIds = {};

  /// Wraps [child] in a RepaintBoundary and plays the entrance animation
  /// only on first appearance. Delay is linear and capped (the old
  /// log-scale delays piled up to ~320ms deep in the grid).
  Widget _animateCardOnce({
    required String id,
    required int index,
    required Widget child,
    bool horizontal = false,
  }) {
    final card = RepaintBoundary(child: child);
    if (_animatedCardIds.contains(id)) return card;
    _animatedCardIds.add(id);
    final delay = (60 * (index % 6)).ms;
    final animated = card.animate(delay: delay);
    return horizontal
        ? animated
            .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
            .slideX(begin: 0.12, duration: 300.ms, curve: Curves.easeOutQuart)
        : animated
            .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.12, duration: 300.ms, curve: Curves.easeOutQuart);
  }

  // Search state
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Set<String> _selectedFilters = {'all'};
  Timer? _debounceTimer;

  // Filter chip definitions (labels resolved via _getFilterLabel)
  static const List<Map<String, dynamic>> _filterChipDefs = [
    {'id': 'all', 'icon': Icons.filter_list_rounded, 'color': Color(0xFF00FF88)},
    {'id': 'dynamic', 'icon': Icons.bolt_rounded, 'color': Color(0xFF00FF88)},
    {'id': 'url', 'icon': Icons.link_rounded, 'color': Color(0xFF3B82F6)},
    {'id': 'wifi', 'icon': Icons.wifi_rounded, 'color': Color(0xFF8B5CF6)},
    {'id': 'email', 'icon': Icons.email_rounded, 'color': Color(0xFFF59E0B)},
    {'id': 'vcard', 'icon': Icons.person_rounded, 'color': Color(0xFF00FF88)},
    {'id': 'geo', 'icon': Icons.location_on_rounded, 'color': Color(0xFFF97316)},
    {'id': 'vevent', 'icon': Icons.event_rounded, 'color': Color(0xFF06B6D4)},
    {'id': 'text', 'icon': Icons.text_fields_rounded, 'color': Color(0xFF94A3B8)},
  ];

  String _getFilterLabel(String id, AppLocalizations l10n) {
    switch (id) {
      case 'all': return l10n.filterAll;
      case 'dynamic': return l10n.localeName.startsWith('es') ? 'Dinámicos' : 'Dynamic';
      case 'url': return l10n.filterUrl;
      case 'wifi': return l10n.filterWifi;
      case 'email': return l10n.filterEmail;
      case 'vcard': return l10n.filterVcard;
      case 'geo': return l10n.filterLocation;
      case 'vevent': return l10n.filterEvent;
      case 'text': return l10n.filterText;
      default: return id;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

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
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: _isSearchExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: Column(
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
                          secondChild: Row(
                            children: [
                              // Back button when search is expanded
                              GestureDetector(
                                onTap: _toggleSearch,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E2E2E),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: _buildExpandableSearchBar(l10n)),
                            ],
                          ),
                        ),
                      ),
                      // Search button (only visible when not expanded)
                      if (!_isSearchExpanded)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isSearchExpanded ? 0.0 : 1.0,
                          child: IconButton(
                            onPressed: _toggleSearch,
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
                        ),
                    ],
                  ),

                  // Filter chips (appear when search is expanded)
                  if (_isSearchExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildFilterChips(l10n),
                    ),

                  const SizedBox(height: 24),
                  
                  // Tab selector with glassmorphism
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                              const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
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
                  // Keep-alive: without it PageView disposes off-screen tabs
                  // and every swipe re-fetches + re-animates from scratch.
                  _KeepAlivePage(child: _buildMyQRsTab(l10n)),
                  _KeepAlivePage(child: _buildFavoritesTab(l10n)),
                  _KeepAlivePage(child: _buildRecentTab(l10n)),
                ],
              ),
            ),
          ],
        ),
      ),
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
          transform: Matrix4.diagonal3Values(isSelected ? 1.0 : 0.98, isSelected ? 1.0 : 0.98, 1.0),
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

                    // Apply search and filter
                    final filteredCodes = _getFilteredQRCodes(qrCodes);

                    if (filteredCodes.isEmpty && (_searchQuery.isNotEmpty || !_selectedFilters.contains('all'))) {
                      return _buildNoResultsState(l10n);
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75, // Polaroid aspect ratio - taller cards
                      ),
                      itemCount: filteredCodes.length,
                      itemBuilder: (context, index) => _animateCardOnce(
                        id: filteredCodes[index].id,
                        index: index,
                        child: _buildEntityQRCard(filteredCodes[index], l10n),
                      ),
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
                    itemBuilder: (context, index) =>
                        _buildQRCardSkeleton().animate(delay: (60 * index).ms)
                            .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic),
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
            itemBuilder: (context, index) => _animateCardOnce(
              id: 'fav_${favoriteQRs[index].id}',
              index: index,
              child: _buildEntityQRCard(favoriteQRs[index], l10n),
            ),
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
            itemBuilder: (context, index) => _animateCardOnce(
              id: 'recent_${recentQRs[index].id}',
              index: index,
              horizontal: true,
              child: _buildRecentEntityQRCard(recentQRs[index], l10n),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon) {
    // Solid surface instead of BackdropFilter: the blur read-back is
    // GPU-expensive and visually indistinguishable on dark-on-dark.
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF88).withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
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
        ),
      ),
    );
  }

  // ============ SEARCH FUNCTIONALITY ============

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.toLowerCase().trim();
        });
      }
    });
  }

  void _toggleSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _searchQuery = '';
        _selectedFilters = {'all'};
        _searchFocusNode.unfocus();
      }
    });
  }

  void _clearSearch() {
    HapticFeedback.selectionClick();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _searchFocusNode.requestFocus();
  }

  void _toggleFilter(String filterId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (filterId == 'all') {
        _selectedFilters = {'all'};
      } else {
        _selectedFilters.remove('all');
        if (_selectedFilters.contains(filterId)) {
          _selectedFilters.remove(filterId);
          if (_selectedFilters.isEmpty) {
            _selectedFilters = {'all'};
          }
        } else {
          _selectedFilters.add(filterId);
        }
      }
    });
  }

  bool _matchesFilters(QRCodeEntity qr) {
    // Check text query
    if (_searchQuery.isNotEmpty) {
      final nameMatch = qr.name.toLowerCase().contains(_searchQuery);
      final dataMatch = qr.displayData.toLowerCase().contains(_searchQuery);
      if (!nameMatch && !dataMatch) return false;
    }

    // Check type filters
    if (_selectedFilters.contains('all')) return true;
    if (_selectedFilters.contains('dynamic') && qr.isDynamic) return true;
    return _selectedFilters.contains(qr.type.identifier.toLowerCase());
  }

  List<QRCodeEntity> _getFilteredQRCodes(List<QRCodeEntity> qrCodes) {
    if (_searchQuery.isEmpty && _selectedFilters.contains('all')) {
      return qrCodes;
    }
    return qrCodes.where(_matchesFilters).toList();
  }

  Widget _buildExpandableSearchBar(AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: _isSearchExpanded ? 48 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isSearchExpanded ? 1.0 : 0.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2E2E2E).withValues(alpha: 0.8),
                    const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF00FF88),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      cursorColor: const Color(0xFF00FF88),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.searchByNameTypeContent,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ),
                    ).animate()
                      .fadeIn(duration: 150.ms)
                      .scale(begin: const Offset(0.8, 0.8), duration: 150.ms),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: _isSearchExpanded ? 44 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isSearchExpanded ? 1.0 : 0.0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_filterChipDefs.length, (index) {
              final chip = _filterChipDefs[index];
              final chipId = chip['id'] as String;
              final isSelected = _selectedFilters.contains(chipId);
              final chipColor = chip['color'] as Color;
              final chipLabel = _getFilterLabel(chipId, l10n);

              return Padding(
                padding: EdgeInsets.only(right: index < _filterChipDefs.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => _toggleFilter(chipId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? chipColor.withValues(alpha: 0.2)
                          : const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? chipColor.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: chipColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          chip['icon'] as IconData,
                          size: 14,
                          color: isSelected ? chipColor : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chipLabel,
                          style: TextStyle(
                            color: isSelected ? chipColor : Colors.grey[400],
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (index * 30).ms)
                  .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic)
                  .slideX(begin: 0.2, duration: 200.ms, curve: Curves.easeOutCubic),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with shake animation
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: Colors.white,
              size: 32,
            ),
          ).animate()
            .shake(duration: 400.ms, hz: 2)
            .then()
            .shimmer(duration: 600.ms, color: Colors.white.withValues(alpha: 0.2)),

          const SizedBox(height: 16),

          Text(
            l10n.noQRCodesFound,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          const SizedBox(height: 8),

          Text(
            l10n.tryDifferentSearchTerm,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () {
              _clearSearch();
              setState(() => _selectedFilters = {'all'});
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00FF88),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, size: 18),
                const SizedBox(width: 6),
                Text(l10n.clearFilters),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
        ],
      ),
    );
  }

  /// Highlights matching text in search results
  List<TextSpan> _highlightMatches(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: const TextStyle(color: Colors.white))];
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: const TextStyle(color: Colors.white),
          ));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: const TextStyle(color: Colors.white),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          color: Color(0xFF00FF88),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: const TextStyle(color: Colors.white))]
        : spans;
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
      case 'vcard':
      case 'personal_info':
        return Icons.person_rounded;
      case 'location':
      case 'geo':
        return Icons.location_on_rounded;
      case 'text': default: return Icons.text_fields_rounded;
    }
  }

  Color _getQRTypeColor(String qrType) {
    switch (qrType.toLowerCase()) {
      case 'url': return const Color(0xFF3B82F6);      // Bright Blue
      case 'wifi': return const Color(0xFF8B5CF6);     // Purple
      case 'email': return const Color(0xFFF59E0B);    // Amber
      case 'phone': return const Color(0xFF22D3EE);    // Cyan
      case 'sms': return const Color(0xFFEC4899);      // Pink
      case 'vcard':
      case 'personal_info':
        return const Color(0xFF00FF88);                // Neon Green
      case 'location':
      case 'geo':
        return const Color(0xFFF97316);                // Orange
      case 'text': default: return const Color(0xFF94A3B8);  // Slate
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        // Solid surface — per-row BackdropFilter caused scroll jank.
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        // Solid surface — per-card BackdropFilter in a scrolling grid was the
        // top jank source flagged in the performance review.
        child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
        children: [
          // Polaroid Photo Section - Rectangular Icon Area
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _showEntityQRDetails(qrEntity),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _showQrContextMenu(qrEntity);
              },
              child: Hero(
                tag: 'qr-icon-${qrEntity.id}',
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
                    child: Icon(iconData, color: color, size: 36),
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
                child: _searchQuery.isNotEmpty
                    ? RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          children: _highlightMatches(title, _searchQuery),
                        ),
                      )
                    : Text(
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
          
          // Time info + scan-count badge (when the QR has a live redirect)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 20,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if ((qrEntity.scanCount ?? 0) > 0)
                  _ScanCountBadge(
                    count: qrEntity.scanCount!,
                    lastScannedAt: qrEntity.lastScannedAt,
                  ),
              ],
            ),
          ),

          // Dynamic-QR chip: visible only when redirect is linked (isDynamic).
          // Surfaced here so users learn "edit destination" without digging
          // into the popup menu — the key engagement investment loop.
          if (qrEntity.isDynamic)
            GestureDetector(
              onTap: () => _editRedirectDestination(qrEntity),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFF1A73E8),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        qrEntity.slug ?? '',
                        style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                // Favorite button with animated feedback
                AnimatedFavoriteButton(
                  isFavorite: qrEntity.isFavorite,
                  isProcessing: _processingFavorites.contains(qrEntity.id),
                  onToggle: () => _toggleFavorite(qrEntity),
                  size: 18,
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
                    // Dynamic QRs: what the printed code shows is managed in its detail.
                    if (qrEntity.isDynamic)
                      PopupMenuItem<String>(
                        value: 'editRedirect',
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz_rounded, color: Color(0xFF3B82F6), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              l10n.editRedirectDestination,
                              style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 14),
                            ),
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
                      value: 'engrave',
                      child: Row(
                        children: [
                          const Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF00FF88), size: 16),
                          const SizedBox(width: 8),
                          const Text('Engrabar', style: TextStyle(color: Color(0xFF00FF88), fontSize: 14)),
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
          ),
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

    // Start processing animation
    setState(() => _processingFavorites.add(qrEntity.id));

    try {
      // Toggle directly — the previous pre-load (full loadUserQRCodes before
      // every toggle) doubled the Supabase round-trips per tap for no benefit.
      await ref.read(qrLibraryControllerProvider.notifier).toggleFavorite(qrEntity.id);

      // Refresh the user QR codes provider to get updated data
      ref.invalidate(userQRCodesProvider);

      // Success feedback is now handled by AnimatedFavoriteButton animation
      // No snackbar needed - the particle burst confirms success
    } catch (e) {
      // Show error feedback (only on failure)
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
    } finally {
      // Stop processing animation
      if (mounted) {
        setState(() => _processingFavorites.remove(qrEntity.id));
      }
    }
  }

  Future<void> _shareQRCode(QRCodeEntity qrEntity) async {
    if (_blockedDynamic(qrEntity)) return;
    // Render QR data to a PNG via QrPainter offscreen canvas, then share.
    try {
      const int size = 900; // 3x the display size for print quality

      final QrPainter painter = QrPainter(
        data: qrEntity.data,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: ui.Color(0xFF000000),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: ui.Color(0xFF000000),
        ),
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      );

      // White background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        Paint()..color = const ui.Color(0xFFFFFFFF),
      );
      painter.paint(canvas, const Size(size / 1.0, size / 1.0));

      final ui.Image image = await recorder.endRecording().toImage(size, size);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showShareError('Failed to encode QR image.');
        return;
      }

      final sanitizedName =
          qrEntity.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName =
          'qraft_${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final tmpFile = File('${Directory.systemTemp.path}/$fileName');
      await tmpFile.writeAsBytes(byteData.buffer.asUint8List());

      // B8: include the scanqraft.app short link when the QR is dynamic.
      // Every share distributes the link — each scan on it feeds the owner's
      // scan counter (the engagement reward loop).
      final shareText = qrEntity.isDynamic
          ? 'QR: ${qrEntity.name}\nhttps://scanqraft.app/${qrEntity.slug}'
          : 'QR: ${qrEntity.name}';

      await SharePlus.instance.share(
        ShareParams(files: [XFile(tmpFile.path)], text: shareText),
      );
    } catch (e) {
      _showShareError('Failed to share QR: $e');
    }
  }

  void _showShareError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Long-press bottom sheet (lazy — only created when triggered).
  /// Replaces the per-card PopupMenuButton subtree for long-press, so
  /// all menus share one sheet definition instead of allocating N trees.
  void _showQrContextMenu(QRCodeEntity qrEntity) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                qrEntity.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            _ContextTile(
              icon: Icons.visibility_rounded,
              label: l10n.preview,
              onTap: () { Navigator.pop(context); _showEntityQRDetails(qrEntity); },
            ),
            _ContextTile(
              icon: Icons.edit_rounded,
              label: l10n.edit,
              onTap: () { Navigator.pop(context); _editQRCode(qrEntity); },
            ),
            if (qrEntity.isDynamic)
              _ContextTile(
                icon: Icons.swap_horiz_rounded,
                label: l10n.editRedirectDestination,
                color: const Color(0xFF1A73E8),
                onTap: () { Navigator.pop(context); _editRedirectDestination(qrEntity); },
              ),
            if (!qrEntity.isDynamic)
              _ContextTile(
                icon: Icons.bolt_rounded,
                label: l10n.localeName.startsWith('es')
                    ? 'Crear versión dinámica · US\$9.99'
                    : 'Create dynamic version · US\$9.99',
                color: const Color(0xFF00FF88),
                onTap: () { Navigator.pop(context); _createDynamicVersion(qrEntity); },
              ),
            _ContextTile(
              icon: Icons.share_rounded,
              label: l10n.share,
              onTap: () { Navigator.pop(context); _shareQRCode(qrEntity); },
            ),
            _ContextTile(
              icon: Icons.precision_manufacturing_rounded,
              label: 'Grabar en material',
              color: const Color(0xFF00FF88),
              onTap: () { Navigator.pop(context); _engraveQRCode(qrEntity); },
            ),
            _ContextTile(
              icon: Icons.delete_rounded,
              label: l10n.delete,
              color: const Color(0xFFEF4444),
              onTap: () { Navigator.pop(context); _confirmDeleteQR(qrEntity); },
            ),
            const SizedBox(height: 8),
          ],
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
      case 'editRedirect':
        _editRedirectDestination(qrEntity);
        break;
      case 'share':
        _shareQRCode(qrEntity);
        break;
      case 'engrave':
        _engraveQRCode(qrEntity);
        break;
      case 'delete':
        _confirmDeleteQR(qrEntity);
        break;
    }
  }

  /// Sets [selectedQrForMarketplaceProvider] to the given QR's id, then
  /// navigates to [MarketplaceScreen] so the user can pick a material/variant
  /// and see a live MaterialPreviewWidget for this QR code.
  /// A dynamic code that isn't live (unpaid, deleted, blocked) must not be printed,
  /// engraved or shared: its link would show "not active" / "no longer available".
  bool _blockedDynamic(QRCodeEntity qrEntity) {
    final s = qrEntity.dynamicStatus;
    if (qrEntity.isPrintable) return false;
    final es = Localizations.localeOf(context).languageCode == 'es';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s == 'pending_payment'
          ? (es ? 'Este código se activa cuando se confirme el pago. Aún no lo compartas ni lo imprimas.'
                : "This code turns on once the payment is confirmed. Don't share or print it yet.")
          : (es ? 'Este código ya no está activo.' : 'This code is no longer active.')),
    ));
    return true;
  }

  void _engraveQRCode(QRCodeEntity qrEntity) {
    if (_blockedDynamic(qrEntity)) return;
    ref.read(selectedQrForMarketplaceProvider.notifier).state = qrEntity.id;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MarketplaceScreen(),
      ),
    );
  }

  /// Dynamic QR → its detail (change what it shows, pause, scans…).
  void _editRedirectDestination(QRCodeEntity qrEntity) {
    final id = qrEntity.redirectId;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => id != null ? DynamicQrDetailScreen(redirectId: id) : const DynamicQrManagerScreen(),
        ))
        .then((_) {
      if (mounted) ref.invalidate(userQRCodesProvider);
    });
  }

  /// Same name, design and content as [qrEntity], as a new paid dynamic code. The printed
  /// pattern changes (it encodes scanqraft.app/<slug>), so copies already printed of the
  /// static QR stay static.
  Future<void> _createDynamicVersion(QRCodeEntity qrEntity) async {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: Text(es ? 'Crear versión dinámica' : 'Create dynamic version', style: const TextStyle(color: Colors.white)),
        content: Text(
          es
              ? 'Conserva tu diseño y contenido, y podrás cambiar lo que muestra sin reimprimir. Ojo: el dibujo del código cambia, así que las copias ya impresas de este QR seguirán siendo estáticas.'
              : "Keeps your design and content, and you can change what it shows without reprinting. Note: the code's pattern changes, so copies of this QR you already printed stay static.",
          style: const TextStyle(color: Color(0xFFB4BCC6), height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(es ? 'Cancelar' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00FF88), foregroundColor: const Color(0xFF04140D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(es ? 'Continuar' : 'Continue'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DynamicQrCheckoutScreen(
        name: qrEntity.name,
        type: qrEntity.type,
        payload: qrEntity.data,
        display: qrEntity.displayData,
        customization: qrEntity.customization,
      ),
    ));
    if (mounted) ref.invalidate(userQRCodesProvider);
  }

  void _editQRCode(QRCodeEntity qrEntity) {
    // A dynamic QR's printed data is its link: edit it from its detail screen.
    if (qrEntity.isDynamic) return _editRedirectDestination(qrEntity);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QRCanvasEditorScreen(
          qrType: qrEntity.type,
          template: kQrTemplates.first,
          editingQR: qrEntity,
        ),
      ),
    ).then((updatedQR) {
      if (updatedQR != null && mounted) {
        ref.invalidate(userQRCodesProvider);
      }
    });
  }

  void _confirmDeleteQR(QRCodeEntity qrEntity) {
    // A dynamic QR is deleted from its detail screen (revokes the printed code, with a
    // stronger warning); the library row can't be deleted on its own.
    if (qrEntity.isDynamic) return _editRedirectDestination(qrEntity);
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
/// Keeps a PageView page alive across swipes so tab content isn't disposed
/// and rebuilt (with re-fetches and replayed animations) on every tab change.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Neon scan-count badge shown on library cards for QRs with a live
/// scanqraft.app redirect ("12 · 3h"). The count is the variable reward
/// that turns the library from an archive into a feed.
class _ScanCountBadge extends StatelessWidget {
  final int count;
  final DateTime? lastScannedAt;

  const _ScanCountBadge({required this.count, this.lastScannedAt});

  String _compactAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final ago = lastScannedAt != null ? ' · ${_compactAgo(lastScannedAt!)}' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: Color(0xFF00FF88),
            size: 11,
          ),
          const SizedBox(width: 2),
          Text(
            '$count$ago',
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single action row inside [_showQrContextMenu]'s bottom sheet.
/// Created lazily (only when the sheet is opened), so N cards in the
/// grid no longer each allocate a PopupMenuButton widget tree at build.
class _ContextTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ContextTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c, fontSize: 14)),
      onTap: onTap,
    );
  }
}
