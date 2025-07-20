import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/main_navigation.dart';
import '../dashboard/dashboard_screen.dart';
import '../qr_generator/qr_generator_screen.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../qr_library/qr_library_screen.dart';
import '../marketplace/marketplace_screen.dart';

// Provider for the current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    
    // List of screens corresponding to navigation items
    // 0: Dashboard, 1: Generate, 2: Scanner (Center), 3: Library, 4: Marketplace
    final screens = [
      const DashboardScreen(),   // Dashboard - User overview and stats
      const QRGeneratorScreen(), // Generate - QR creation tools
      const QRScannerScreen(),   // Scanner (Center focal) - Main scanning feature
      const QRLibraryScreen(),   // Library - QR collection management
      const MarketplaceScreen(), // Marketplace - Laser engraving marketplace
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: MainNavigation(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}