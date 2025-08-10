import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/glass_button.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with TickerProviderStateMixin {
  int _selectedCategory = 0;
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
                              'Marketplace',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Laser engrave your QR codes',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cart button
                      IconButton(
                        onPressed: () => _showCartDialog(),
                        icon: const Icon(
                          Icons.shopping_cart_rounded,
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
                  
                  // Featured promotion banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'XTool F1 Ultra Laser',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Professional precision engraving',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.precision_manufacturing_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .slideX(begin: 0.3, duration: 800.ms, delay: 200.ms),
                  
                  const SizedBox(height: 24),
                  
                  // Category tabs
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
                        _buildCategoryTab('All', 0),
                        _buildCategoryTab('Wood', 1),
                        _buildCategoryTab('Metal', 2),
                        _buildCategoryTab('Acrylic', 3),
                      ],
                    ),
                  ),
                ],
              ).animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: -0.3, duration: 800.ms),
            ),
            
            // Products grid
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedCategory = index;
                  });
                },
                children: [
                  _buildProductsGrid(_getAllProducts()),
                  _buildProductsGrid(_getWoodProducts()),
                  _buildProductsGrid(_getMetalProducts()),
                  _buildProductsGrid(_getAcrylicProducts()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String text, int index) {
    final isSelected = _selectedCategory == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = index;
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

  Widget _buildProductsGrid(List<Map<String, dynamic>> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductCard(products[index], index).animate()
            .fadeIn(duration: 600.ms, delay: (index * 100).ms)
            .slideY(begin: 0.3, duration: 600.ms, delay: (index * 100).ms);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
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
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showProductDetails(product),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image placeholder
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: product['gradient'] as LinearGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    product['icon'] as IconData,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Product title
                Text(
                  product['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Material
                Text(
                  product['material'] as String,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                
                const Spacer(),
                
                // Price and add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['price'] as String,
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
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

  List<Map<String, dynamic>> _getAllProducts() {
    return [
      ..._getWoodProducts(),
      ..._getMetalProducts(),
      ..._getAcrylicProducts(),
    ];
  }

  List<Map<String, dynamic>> _getWoodProducts() {
    return [
      {
        'name': 'Wood Keychain',
        'material': 'Oak Wood',
        'price': '\$12.99',
        'icon': Icons.key_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF8B4513), Color(0xFFD2691E)]),
      },
      {
        'name': 'Wood Coaster',
        'material': 'Walnut Wood',
        'price': '\$8.99',
        'icon': Icons.circle_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF654321), Color(0xFF8B4513)]),
      },
      {
        'name': 'Wood Plaque',
        'material': 'Pine Wood',
        'price': '\$24.99',
        'icon': Icons.rectangle_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFFDEB887), Color(0xFFD2691E)]),
      },
    ];
  }

  List<Map<String, dynamic>> _getMetalProducts() {
    return [
      {
        'name': 'Metal Tag',
        'material': 'Stainless Steel',
        'price': '\$15.99',
        'icon': Icons.badge_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF708090), Color(0xFF2F4F4F)]),
      },
      {
        'name': 'Metal Plate',
        'material': 'Aluminum',
        'price': '\$19.99',
        'icon': Icons.rectangle_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFFC0C0C0), Color(0xFF708090)]),
      },
    ];
  }

  List<Map<String, dynamic>> _getAcrylicProducts() {
    return [
      {
        'name': 'Acrylic Stand',
        'material': 'Clear Acrylic',
        'price': '\$9.99',
        'icon': Icons.phone_android_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF87CEEB), Color(0xFF4682B4)]),
      },
      {
        'name': 'Acrylic Sign',
        'material': 'Colored Acrylic',
        'price': '\$16.99',
        'icon': Icons.signpost_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF00CED1), Color(0xFF4682B4)]),
      },
    ];
  }

  void _showCartDialog() {
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
                      colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shopping Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your cart is empty',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add products to see them here',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryGlassButton(
                  text: 'Continue Shopping',
                  icon: Icons.shopping_bag_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
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
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: product['gradient'] as LinearGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    product['icon'] as IconData,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  product['name'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['material'] as String,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Features:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: const Color(0xFF00FF88), size: 16),
                          const SizedBox(width: 8),
                          Text('Precision laser engraving', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: const Color(0xFF00FF88), size: 16),
                          const SizedBox(width: 8),
                          Text('High-quality ${product['material']}', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: const Color(0xFF00FF88), size: 16),
                          const SizedBox(width: 8),
                          Text('Custom QR code design', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price: ${product['price']}',
                      style: TextStyle(
                        color: const Color(0xFF00FF88),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'In Stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryGlassButton(
                        text: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryGlassButton(
                        text: 'Add to Cart',
                        icon: Icons.add_shopping_cart_rounded,
                        onPressed: () {
                          Navigator.of(context).pop();
                          _addToCart(product);
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

  void _addToCart(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: product['gradient'] as LinearGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                product['icon'] as IconData,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${product['name']} added to cart!'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E2E2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: const Color(0xFF00FF88),
          onPressed: () => _showCartDialog(),
        ),
      ),
    );
  }
}