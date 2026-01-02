import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Represents a purchasable product from RevenueCat
class PurchaseProduct extends Equatable {
  final String id;
  final String title;
  final String description;
  final String priceString;
  final double price;
  final String currencyCode;
  final ProductType type;
  final String? introPrice;
  final int? trialDays;
  final Package? package;

  const PurchaseProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.priceString,
    required this.price,
    required this.currencyCode,
    required this.type,
    this.introPrice,
    this.trialDays,
    this.package,
  });

  /// Create from RevenueCat Package
  factory PurchaseProduct.fromPackage(Package package) {
    final product = package.storeProduct;
    final intro = product.introductoryPrice;

    int? trialDays;
    if (intro != null && intro.price == 0) {
      // Free trial
      trialDays = _calculateTrialDays(intro);
    }

    return PurchaseProduct(
      id: product.identifier,
      title: product.title,
      description: product.description,
      priceString: product.priceString,
      price: product.price,
      currencyCode: product.currencyCode,
      type: _mapProductType(package.packageType),
      introPrice: intro?.priceString,
      trialDays: trialDays,
      package: package,
    );
  }

  /// Whether this is a subscription product
  bool get isSubscription =>
      type == ProductType.monthly || type == ProductType.annual;

  /// Whether this is a lifetime/one-time purchase
  bool get isLifetime => type == ProductType.lifetime;

  /// Whether this product has a free trial
  bool get hasFreeTrial => trialDays != null && trialDays! > 0;

  /// Get period text for display (e.g., "/month", "/year")
  String get periodText {
    switch (type) {
      case ProductType.monthly:
        return '/month';
      case ProductType.annual:
        return '/year';
      case ProductType.lifetime:
        return '';
    }
  }

  /// Calculate savings percentage compared to monthly
  int? calculateSavingsPercent(PurchaseProduct? monthlyProduct) {
    if (monthlyProduct == null || type != ProductType.annual) return null;

    final monthlyYearlyCost = monthlyProduct.price * 12;
    if (monthlyYearlyCost <= 0) return null;

    final savings = ((monthlyYearlyCost - price) / monthlyYearlyCost * 100).round();
    return savings > 0 ? savings : null;
  }

  static ProductType _mapProductType(PackageType packageType) {
    switch (packageType) {
      case PackageType.monthly:
        return ProductType.monthly;
      case PackageType.annual:
        return ProductType.annual;
      case PackageType.lifetime:
        return ProductType.lifetime;
      default:
        return ProductType.lifetime; // Treat unknown as one-time
    }
  }

  static int? _calculateTrialDays(IntroductoryPrice intro) {
    final unit = intro.periodUnit;
    final count = intro.periodNumberOfUnits;

    switch (unit) {
      case PeriodUnit.day:
        return count;
      case PeriodUnit.week:
        return count * 7;
      case PeriodUnit.month:
        return count * 30;
      case PeriodUnit.year:
        return count * 365;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        priceString,
        price,
        currencyCode,
        type,
        introPrice,
        trialDays,
      ];
}

/// Types of products available
enum ProductType {
  monthly,
  annual,
  lifetime,
}
