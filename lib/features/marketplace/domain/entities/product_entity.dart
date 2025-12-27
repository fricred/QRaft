import 'package:flutter/material.dart';

/// Product entity representing a marketplace item.
/// Replaces the informal [Map] with a type-safe model.
class ProductEntity {
  final String id;
  final String name;
  final String material;
  final String materialCategory; // wood, metal, acrylic, leather, glass, stone
  final double price;
  final String currency;
  final IconData icon;
  final LinearGradient gradient;
  final bool inStock;
  final int stockQuantity;
  final String description;
  final List<String> features;
  final List<String> availableSizes;
  final List<ProductFinish> availableFinishes;
  final List<String> galleryImages;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.material,
    required this.materialCategory,
    required this.price,
    this.currency = '\$',
    required this.icon,
    required this.gradient,
    this.inStock = true,
    this.stockQuantity = 10,
    this.description = '',
    this.features = const [],
    this.availableSizes = const ['S', 'M', 'L'],
    this.availableFinishes = const [],
    this.galleryImages = const [],
  });

  /// Formatted price string
  String get formattedPrice => '$currency${price.toStringAsFixed(2)}';

  /// Create from Map (for backwards compatibility with existing data)
  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    // Parse price from string like "$12.99"
    final priceStr = map['price'] as String? ?? '\$0.00';
    final priceValue = double.tryParse(priceStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

    // Determine material category from material name
    final material = map['material'] as String? ?? '';
    String category = 'other';
    if (material.toLowerCase().contains('wood') ||
        material.toLowerCase().contains('oak') ||
        material.toLowerCase().contains('walnut') ||
        material.toLowerCase().contains('pine')) {
      category = 'wood';
    } else if (material.toLowerCase().contains('steel') ||
               material.toLowerCase().contains('aluminum') ||
               material.toLowerCase().contains('metal')) {
      category = 'metal';
    } else if (material.toLowerCase().contains('acrylic')) {
      category = 'acrylic';
    } else if (material.toLowerCase().contains('leather')) {
      category = 'leather';
    } else if (material.toLowerCase().contains('glass')) {
      category = 'glass';
    } else if (material.toLowerCase().contains('stone')) {
      category = 'stone';
    }

    return ProductEntity(
      id: map['id'] as String? ?? UniqueKey().toString(),
      name: map['name'] as String? ?? 'Unknown Product',
      material: material,
      materialCategory: category,
      price: priceValue,
      icon: map['icon'] as IconData? ?? Icons.shopping_bag_rounded,
      gradient: map['gradient'] as LinearGradient? ??
          const LinearGradient(colors: [Color(0xFF2E2E2E), Color(0xFF1A1A1A)]),
      inStock: map['inStock'] as bool? ?? true,
      stockQuantity: map['stockQuantity'] as int? ?? 10,
      description: map['description'] as String? ?? 'High-quality laser-engraved product with your custom QR code.',
      features: (map['features'] as List<dynamic>?)?.cast<String>() ?? [
        'Precision laser engraving',
        'Custom QR code design',
        'Durable and long-lasting',
      ],
      availableSizes: (map['availableSizes'] as List<dynamic>?)?.cast<String>() ?? ['S', 'M', 'L'],
      availableFinishes: (map['availableFinishes'] as List<dynamic>?)
          ?.map((f) => ProductFinish.fromMap(f as Map<String, dynamic>))
          .toList() ?? ProductFinish.defaultFinishes,
      galleryImages: (map['galleryImages'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'material': material,
      'materialCategory': materialCategory,
      'price': formattedPrice,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'description': description,
      'features': features,
      'availableSizes': availableSizes,
    };
  }

  /// Copy with modified fields
  ProductEntity copyWith({
    String? id,
    String? name,
    String? material,
    String? materialCategory,
    double? price,
    String? currency,
    IconData? icon,
    LinearGradient? gradient,
    bool? inStock,
    int? stockQuantity,
    String? description,
    List<String>? features,
    List<String>? availableSizes,
    List<ProductFinish>? availableFinishes,
    List<String>? galleryImages,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      material: material ?? this.material,
      materialCategory: materialCategory ?? this.materialCategory,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      gradient: gradient ?? this.gradient,
      inStock: inStock ?? this.inStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      description: description ?? this.description,
      features: features ?? this.features,
      availableSizes: availableSizes ?? this.availableSizes,
      availableFinishes: availableFinishes ?? this.availableFinishes,
      galleryImages: galleryImages ?? this.galleryImages,
    );
  }
}

/// Product finish option
class ProductFinish {
  final String id;
  final String name;
  final Color color;
  final double priceModifier;

  const ProductFinish({
    required this.id,
    required this.name,
    required this.color,
    this.priceModifier = 0.0,
  });

  factory ProductFinish.fromMap(Map<String, dynamic> map) {
    return ProductFinish(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      color: Color(map['color'] as int? ?? 0xFFFFFFFF),
      priceModifier: (map['priceModifier'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static List<ProductFinish> get defaultFinishes => const [
    ProductFinish(
      id: 'matte',
      name: 'Matte',
      color: Color(0xFF404040),
      priceModifier: 0.0,
    ),
    ProductFinish(
      id: 'glossy',
      name: 'Glossy',
      color: Color(0xFF808080),
      priceModifier: 2.0,
    ),
    ProductFinish(
      id: 'satin',
      name: 'Satin',
      color: Color(0xFFA0A0A0),
      priceModifier: 1.5,
    ),
  ];
}

/// Material category gradients for visual display
class MaterialGradients {
  static const LinearGradient wood = LinearGradient(
    colors: [Color(0xFF8B4513), Color(0xFFD2691E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient metal = LinearGradient(
    colors: [Color(0xFF708090), Color(0xFF2F4F4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient acrylic = LinearGradient(
    colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient leather = LinearGradient(
    colors: [Color(0xFF8B4513), Color(0xFF5D3A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glass = LinearGradient(
    colors: [Color(0xFFE0E7EE), Color(0xFFB8C6D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient stone = LinearGradient(
    colors: [Color(0xFF696969), Color(0xFF2F4F4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient forCategory(String category) {
    switch (category.toLowerCase()) {
      case 'wood':
        return wood;
      case 'metal':
        return metal;
      case 'acrylic':
        return acrylic;
      case 'leather':
        return leather;
      case 'glass':
        return glass;
      case 'stone':
        return stone;
      default:
        return const LinearGradient(
          colors: [Color(0xFF2E2E2E), Color(0xFF1A1A1A)],
        );
    }
  }
}
