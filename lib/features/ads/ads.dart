/// QRaft Ads Module
///
/// Provides non-intrusive advertising for free tier users.
/// Includes banner ads, rewarded ads, and native ad components.
library;

// Constants
export 'constants/ad_unit_ids.dart';

// Domain
export 'domain/entities/ad_config.dart';

// Data
export 'data/services/admob_service.dart';

// Providers
export 'presentation/providers/ad_providers.dart';

// Widgets
export 'presentation/widgets/banner_ad_widget.dart';
export 'presentation/widgets/rewarded_ad_button.dart';
export 'presentation/widgets/native_ad_widget.dart';
