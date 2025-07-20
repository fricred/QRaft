import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/glass_button.dart';

class QRLibraryScreen extends StatefulWidget {
  const QRLibraryScreen({super.key});

  @override
  State<QRLibraryScreen> createState() => _QRLibraryScreenState();
}

class _QRLibraryScreenState extends State<QRLibraryScreen> with TickerProviderStateMixin {
  int _selectedTab = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
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
                              'QR Library',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your QR codes',
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
                        onPressed: () => _showComingSoonDialog('Search'),
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
                        _buildTabButton('My QRs', 0),
                        _buildTabButton('Favorites', 1),
                        _buildTabButton('Recent', 2),
                      ],
                    ),
                  ),
                ],
              ).animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: -0.3, duration: 800.ms),
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
                  _buildMyQRsTab(),
                  _buildFavoritesTab(),
                  _buildRecentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showComingSoonDialog('Create QR'),
        backgroundColor: const Color(0xFF00FF88),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ).animate()
        .fadeIn(duration: 800.ms, delay: 600.ms)
        .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, delay: 600.ms),
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
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isSelected 
                ? const LinearGradient(
                    colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
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

  Widget _buildMyQRsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              _buildStatsCard('Total QRs', '12', Icons.qr_code_rounded),
              const SizedBox(width: 16),
              _buildStatsCard('This Month', '3', Icons.calendar_month_rounded),
            ],
          ).animate()
            .fadeIn(duration: 800.ms, delay: 200.ms)
            .slideY(begin: 0.3, duration: 800.ms, delay: 200.ms),
          
          const SizedBox(height: 24),
          
          // QR Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: 6, // Demo items
              itemBuilder: (context, index) {
                return _buildQRCard(index).animate()
                  .fadeIn(duration: 600.ms, delay: (300 + index * 100).ms)
                  .slideY(begin: 0.3, duration: 600.ms, delay: (300 + index * 100).ms);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          ),
          const SizedBox(height: 24),
          Text(
            'No Favorites Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Star your favorite QR codes to see them here',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate()
        .fadeIn(duration: 800.ms)
        .scale(begin: const Offset(0.9, 0.9), duration: 600.ms),
    );
  }

  Widget _buildRecentTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ListView.builder(
        itemCount: 5, // Demo items
        itemBuilder: (context, index) {
          return _buildRecentQRCard(index).animate()
            .fadeIn(duration: 600.ms, delay: (index * 100).ms)
            .slideX(begin: 0.3, duration: 600.ms, delay: (index * 100).ms);
        },
      ),
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

  Widget _buildQRCard(int index) {
    final qrTypes = [
      {'title': 'Personal Info', 'icon': Icons.person_rounded, 'color': Color(0xFF00FF88)},
      {'title': 'Website URL', 'icon': Icons.link_rounded, 'color': Color(0xFF1A73E8)},
      {'title': 'WiFi Network', 'icon': Icons.wifi_rounded, 'color': Color(0xFF8B5CF6)},
      {'title': 'Text Message', 'icon': Icons.text_fields_rounded, 'color': Color(0xFFEF4444)},
      {'title': 'Email Contact', 'icon': Icons.email_rounded, 'color': Color(0xFFF59E0B)},
      {'title': 'Location', 'icon': Icons.location_on_rounded, 'color': Color(0xFF10B981)},
    ];
    
    final qr = qrTypes[index % qrTypes.length];
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showComingSoonDialog('QR Details'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // QR Code placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (qr['color'] as Color).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    qr['icon'] as IconData,
                    color: qr['color'] as Color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  qr['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '2 days ago',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                    Icon(
                      Icons.share_rounded,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                    Icon(
                      Icons.more_vert_rounded,
                      color: Colors.grey[400],
                      size: 18,
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

  Widget _buildRecentQRCard(int index) {
    final qrTypes = [
      {'title': 'Personal vCard', 'subtitle': 'Contact information', 'icon': Icons.person_rounded},
      {'title': 'Company Website', 'subtitle': 'https://example.com', 'icon': Icons.link_rounded},
      {'title': 'WiFi Password', 'subtitle': 'Home network', 'icon': Icons.wifi_rounded},
      {'title': 'Business Email', 'subtitle': 'contact@example.com', 'icon': Icons.email_rounded},
      {'title': 'Event Location', 'subtitle': 'Conference center', 'icon': Icons.location_on_rounded},
    ];
    
    final qr = qrTypes[index % qrTypes.length];
    
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              qr['icon'] as IconData,
              color: const Color(0xFF00FF88),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qr['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  qr['subtitle'] as String,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${index + 1}h ago',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
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
                      colors: [Color(0xFF8B5CF6), Color(0xFF1A73E8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.library_books_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming Soon!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$feature functionality is under development and will be available soon.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryGlassButton(
                  text: 'Got it',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}