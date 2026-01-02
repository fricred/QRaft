import 'package:purchases_flutter/purchases_flutter.dart';

/// Types of purchase errors
enum PurchaseErrorType {
  /// User cancelled the purchase
  cancelled,

  /// Product not available in the store
  productNotAvailable,

  /// Network error during purchase
  network,

  /// Purchase is pending (e.g., parental approval)
  pending,

  /// Invalid purchase or receipt
  invalid,

  /// Store error (App Store / Play Store)
  store,

  /// User is not allowed to make payments
  notAllowed,

  /// Unknown error
  unknown,
}

/// Represents a purchase error with user-friendly messaging
class PurchaseError {
  final PurchaseErrorType type;
  final String message;
  final String? debugMessage;

  const PurchaseError({
    required this.type,
    required this.message,
    this.debugMessage,
  });

  /// Create from RevenueCat error
  factory PurchaseError.fromPurchasesError(PurchasesErrorCode code, [String? message]) {
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return const PurchaseError(
          type: PurchaseErrorType.cancelled,
          message: 'Purchase was cancelled',
        );

      case PurchasesErrorCode.productNotAvailableForPurchaseError:
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return PurchaseError(
          type: PurchaseErrorType.productNotAvailable,
          message: 'This product is not available',
          debugMessage: message,
        );

      case PurchasesErrorCode.networkError:
        return const PurchaseError(
          type: PurchaseErrorType.network,
          message: 'Network error. Please check your connection and try again.',
        );

      case PurchasesErrorCode.receiptAlreadyInUseError:
      case PurchasesErrorCode.invalidReceiptError:
      case PurchasesErrorCode.missingReceiptFileError:
        return PurchaseError(
          type: PurchaseErrorType.invalid,
          message: 'There was an issue with your purchase. Please try again.',
          debugMessage: message,
        );

      case PurchasesErrorCode.storeProblemError:
        return PurchaseError(
          type: PurchaseErrorType.store,
          message: 'Store error. Please try again later.',
          debugMessage: message,
        );

      case PurchasesErrorCode.purchaseNotAllowedError:
        return const PurchaseError(
          type: PurchaseErrorType.notAllowed,
          message: 'Purchases are not allowed on this device',
        );

      default:
        return PurchaseError(
          type: PurchaseErrorType.unknown,
          message: 'An unexpected error occurred. Please try again.',
          debugMessage: message ?? code.toString(),
        );
    }
  }

  /// Create cancelled error
  factory PurchaseError.cancelled() => const PurchaseError(
        type: PurchaseErrorType.cancelled,
        message: 'Purchase was cancelled',
      );

  /// Create network error
  factory PurchaseError.network() => const PurchaseError(
        type: PurchaseErrorType.network,
        message: 'Network error. Please check your connection.',
      );

  /// Whether this error should be shown to the user
  /// (cancelled errors are usually silent)
  bool get shouldShowToUser => type != PurchaseErrorType.cancelled;

  @override
  String toString() => 'PurchaseError($type): $message';
}
