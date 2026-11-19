import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';

class MainNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  // Optional stable Maestro keys for each tab (Phase 1 plan 06).
  // Source of truth: lib/features/main/main_scaffold.dart -> MainScaffoldKeys.
  final Key? dashboardTabKey;
  final Key? generateTabKey;
  final Key? scannerTabKey;
  final Key? libraryTabKey;
  final Key? marketplaceTabKey;
  // Phase 10 plan 02: Orders tab key.
  final Key? ordersTabKey;

  const MainNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.dashboardTabKey,
    this.generateTabKey,
    this.scannerTabKey,
    this.libraryTabKey,
    this.marketplaceTabKey,
    this.ordersTabKey,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 80,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: l10n.dashboardTitle,
                  isCenter: false,
                  itemKey: widget.dashboardTabKey,
                  semanticIdentifier: 'main_scaffold_dashboard_tab',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.qr_code_scanner_rounded,
                  label: l10n.scanner,
                  isCenter: false,
                  itemKey: widget.scannerTabKey,
                  semanticIdentifier: 'main_scaffold_scanner_tab',
                ),
                const SizedBox(width: 60), // Space for center button
                _buildNavItem(
                  index: 3,
                  icon: Icons.library_books_rounded,
                  label: l10n.libraryNav,
                  isCenter: false,
                  itemKey: widget.libraryTabKey,
                  semanticIdentifier: 'main_scaffold_library_tab',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.shopping_bag_rounded,
                  label: l10n.marketplaceNav,
                  isCenter: false,
                  itemKey: widget.marketplaceTabKey,
                  semanticIdentifier: 'main_scaffold_marketplace_tab',
                ),
              ],
            ),
          ),
          
          // Center focal button
          Positioned(
            left: 0,
            right: 0,
            top: -16,
            bottom: 32,
            child: Center(
              child: _buildCenterButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isCenter,
    Key? itemKey,
    String? semanticIdentifier,
  }) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      // QRAFT-17: unselected labels are faded to 0 (screen readers skip them), so the
      // item carries its own accessible name and selected state.
      child: Semantics(
        identifier: semanticIdentifier,
        button: true,
        label: label,
        selected: isSelected,
        excludeSemantics: true,
        // excludeSemantics drops the GestureDetector's action: give the node its own tap.
        onTap: () => widget.onTap(index),
        child: GestureDetector(
        key: itemKey,
        onTap: () {
          widget.onTap(index);
          if (!isSelected) {
            _animationController.forward(from: 0);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                icon,
                size: 24,
                color: isSelected 
                    ? const Color(0xFF00FF88)
                    : Colors.grey[500],
              ).animate(
                target: isSelected ? 1.0 : 0.0,
              ).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 200.ms,
              ),
              
              const SizedBox(height: 4),
              
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? const Color(0xFF00FF88)
                      : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ).animate(
                target: isSelected ? 1.0 : 0.0,
              ).fadeIn(
                duration: 200.ms,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = widget.currentIndex == 1; // Generate is center

    return Semantics(
      identifier: 'main_scaffold_generate_tab',
      button: true,
      label: AppLocalizations.of(context)!.generateQRTitle,
      selected: isSelected,
      excludeSemantics: true,
      onTap: () => widget.onTap(1),
      child: GestureDetector(
      key: widget.generateTabKey,
      onTap: () {
        widget.onTap(1); // Generate index
        _animationController.forward(from: 0);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected 
                ? [const Color(0xFF00FF88), const Color(0xFF00CC6A)]
                : [const Color(0xFF00FF88), const Color(0xFF1A73E8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF88).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: const Color(0xFF00FF88).withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 32,
        ),
      ).animate(
        target: isSelected ? 1.0 : 0.0,
      ).scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.08, 1.08),
        duration: 200.ms,
      ).shimmer(
        duration: isSelected ? 1000.ms : 0.ms,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    ),
    );
  }
}