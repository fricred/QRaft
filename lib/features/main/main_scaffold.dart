import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../shared/widgets/main_navigation.dart';
import '../dashboard/dashboard_screen.dart';
import '../qr_generator/qr_generator_screen.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../qr_library/qr_library_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../orders/presentation/pages/orders_list_screen.dart';
import '../notifications/presentation/providers/notification_providers.dart';
import '../notifications/presentation/widgets/fcm_overlay_handler.dart';

// Provider for the current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Stable Maestro Keys for bottom-nav tabs.
///
/// Source of truth lives in this file (per Phase 1 plan 06 must_haves)
/// because the tabs are conceptually owned by the scaffold; the keys are
/// passed down to [MainNavigation] which actually renders the icons. This
/// keeps `main_scaffold_*` selectors greppable from `main_scaffold.dart`
/// while the literal `Key()` placement stays in the navigation widget.
///
/// Phase 1 plan 07 Maestro flows MUST target these ids verbatim
/// (see `.maestro/CONVENTIONS.md`).
class MainScaffoldKeys {
  static const dashboardTab = Key('main_scaffold_dashboard_tab');
  static const generateTab = Key('main_scaffold_generate_tab');
  static const scannerTab = Key('main_scaffold_scanner_tab');
  static const libraryTab = Key('main_scaffold_library_tab');
  static const marketplaceTab = Key('main_scaffold_marketplace_tab');
  // Phase 10 plan 02: Orders tab (index 5).
  static const ordersTab = Key('main_scaffold_orders_tab');
}

// ---------------------------------------------------------------------------
// MainScaffold
//
// Converted to ConsumerStatefulWidget (Phase 10 plan 03) so that:
//   1. notificationHandlerProvider is read once in initState to wire the
//      FCM onMessageOpenedApp listener (background-tap → OrderDetailScreen).
//   2. checkInitialFcmMessage() is called once in initState to handle the
//      killed-app cold-launch tap path.
//   3. FcmOverlayHandler wraps the scaffold body to show local notification
//      banners when FCM messages arrive in the foreground.
// ---------------------------------------------------------------------------

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void initState() {
    super.initState();
    // Wire FCM background-tap listener (onMessageOpenedApp).
    // The provider is a side-effect provider; reading it activates it.
    ref.read(notificationHandlerProvider);
    // Check if the app was cold-launched by a killed-app notification tap.
    checkInitialFcmMessage();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);

    // List of screens corresponding to navigation items
    // 0: Dashboard, 1: Generate, 2: Scanner (Center), 3: Library,
    // 4: Marketplace, 5: Orders
    final screens = [
      const DashboardScreen(),    // Dashboard - User overview and stats
      const QRGeneratorScreen(),  // Generate - QR creation tools
      const QRScannerScreen(),    // Scanner (Center focal) - Main scanning feature
      const QRLibraryScreen(),    // Library - QR collection management
      const MarketplaceScreen(),  // Marketplace - Laser engraving marketplace
      const OrdersListScreen(),   // Orders - User order tracking (Phase 10-02)
    ];

    return Scaffold(
      key: const Key('main_scaffold_root'),
      backgroundColor: const Color(0xFF1A1A1A),
      body: FcmOverlayHandler(
        child: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: MainNavigation(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        // Stable Maestro keys per Phase 1 plan 06; consumed by MainNavigation's
        // _buildNavItem / _buildCenterButton.
        dashboardTabKey: MainScaffoldKeys.dashboardTab,
        generateTabKey: MainScaffoldKeys.generateTab,
        scannerTabKey: MainScaffoldKeys.scannerTab,
        libraryTabKey: MainScaffoldKeys.libraryTab,
        marketplaceTabKey: MainScaffoldKeys.marketplaceTab,
        // Phase 10 plan 02: Orders tab key (index 5).
        ordersTabKey: MainScaffoldKeys.ordersTab,
      ),
    );
  }
}
