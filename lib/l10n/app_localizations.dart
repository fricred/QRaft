import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'QRaft'**
  String get appName;

  /// Welcome screen main title
  ///
  /// In en, this message translates to:
  /// **'Welcome to QRaft!'**
  String get welcomeTitle;

  /// Welcome screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Your complete solution for custom QR codes'**
  String get welcomeSubtitle;

  /// Feature card title for QR creation
  ///
  /// In en, this message translates to:
  /// **'Create Custom QR'**
  String get featureCreateTitle;

  /// Feature card description for QR creation
  ///
  /// In en, this message translates to:
  /// **'Design and customize your own QR codes for any purpose.'**
  String get featureCreateDescription;

  /// Feature card title for sharing
  ///
  /// In en, this message translates to:
  /// **'Share Easily'**
  String get featureShareTitle;

  /// Feature card description for sharing
  ///
  /// In en, this message translates to:
  /// **'Send your QR codes to your contacts or publish them on your social networks.'**
  String get featureShareDescription;

  /// Feature card title for engraving
  ///
  /// In en, this message translates to:
  /// **'Engrave on Materials'**
  String get featureEngraveTitle;

  /// Feature card description for engraving
  ///
  /// In en, this message translates to:
  /// **'Get your QR codes engraved on wood, metal and other quality materials.'**
  String get featureEngraveDescription;

  /// Primary button text to start using the app
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Text for users who already have an account
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccount;

  /// Title for main features section
  ///
  /// In en, this message translates to:
  /// **'Main Features'**
  String get mainFeatures;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue creating amazing QR codes'**
  String get signInToContinue;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Text for users who don't have an account
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// Sign up screen title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Sign up screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Join QRaft and start creating amazing QR codes'**
  String get joinQRaft;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Full name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// Password creation field hint
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPassword;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordHint;

  /// Terms and conditions agreement text
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions and Privacy Policy'**
  String get agreeToTerms;

  /// Text for users who already have an account in sign up screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccountSignIn;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Password minimum length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// Name minimum length validation error
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinLength;

  /// Password minimum length validation error for sign up
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLengthSignUp;

  /// Password uppercase validation error
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordMustContainUppercase;

  /// Password lowercase validation error
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordMustContainLowercase;

  /// Password number validation error
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordMustContainNumber;

  /// Confirm password validation error
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// Password match validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Terms agreement validation error
  ///
  /// In en, this message translates to:
  /// **'Please agree to Terms & Conditions'**
  String get pleaseAgreeToTerms;

  /// Login attempt message
  ///
  /// In en, this message translates to:
  /// **'Login attempt: {email}'**
  String loginAttempt(String email);

  /// Account creation success message
  ///
  /// In en, this message translates to:
  /// **'Account created for: {name}'**
  String accountCreated(String name);

  /// Forgot password placeholder message
  ///
  /// In en, this message translates to:
  /// **'Forgot password functionality coming soon'**
  String get forgotPasswordComingSoon;

  /// Success message after successful login
  ///
  /// In en, this message translates to:
  /// **'Login successful! Welcome back.'**
  String get loginSuccessful;

  /// Reset password dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Reset password dialog subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive reset link'**
  String get resetPasswordSubtitle;

  /// Placeholder text for email field in reset password dialog
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmailForReset;

  /// Send reset link button text
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendResetLink;

  /// Email sent success title
  ///
  /// In en, this message translates to:
  /// **'Email Sent!'**
  String get emailSent;

  /// Email sent success message
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to {email}. Please check your email and follow the instructions to reset your password.'**
  String checkEmailForReset(String email);

  /// Done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Profile screen title and navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Default display name for users without a name
  ///
  /// In en, this message translates to:
  /// **'Anonymous User'**
  String get anonymousUser;

  /// Default text when user has no email
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// Title for profile photo change modal
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changeProfilePhoto;

  /// Subtitle for profile photo change modal
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to update your profile photo'**
  String get choosePhotoSource;

  /// Loading message while uploading profile photo
  ///
  /// In en, this message translates to:
  /// **'Updating profile photo...'**
  String get updatingProfilePhoto;

  /// Success message after profile photo update
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated successfully!'**
  String get profilePhotoUpdatedSuccess;

  /// Error message when profile photo update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile photo. Please try again.'**
  String get profilePhotoUpdateFailed;

  /// Generic error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// User join date text
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedDate(String date);

  /// Fallback text for unknown values
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Date format for days ago
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// Date format for months ago
  ///
  /// In en, this message translates to:
  /// **'{months} month{plural} ago'**
  String monthsAgo(int months, String plural);

  /// Date format for years ago
  ///
  /// In en, this message translates to:
  /// **'{years} year{plural} ago'**
  String yearsAgo(int years, String plural);

  /// Section title for personal information
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Label for display name field
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Label for phone number field
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Label for bio field
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Label for location field
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Label for website field
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Label for company field
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// Label for job title field
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// Hint text for input fields
  ///
  /// In en, this message translates to:
  /// **'Enter {field}'**
  String enterField(String field);

  /// Text shown when a field has no value
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// Section title for user statistics
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Label for QR codes statistic
  ///
  /// In en, this message translates to:
  /// **'QR Codes'**
  String get qrCodes;

  /// Label for scans statistic
  ///
  /// In en, this message translates to:
  /// **'Scans'**
  String get scans;

  /// Label for orders statistic
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// Label for days active statistic
  ///
  /// In en, this message translates to:
  /// **'Days Active'**
  String get daysActive;

  /// Section title for quick actions
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Label for my QR codes action
  ///
  /// In en, this message translates to:
  /// **'My QR Codes'**
  String get myQRCodes;

  /// Label for scan history action
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get scanHistory;

  /// Label for my orders action
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// Label for share profile action
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfile;

  /// Title for export data action
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Description for export data action
  ///
  /// In en, this message translates to:
  /// **'Download your QR codes and data'**
  String get exportDataDescription;

  /// Title for backup and sync action
  ///
  /// In en, this message translates to:
  /// **'Backup & Sync'**
  String get backupSync;

  /// Description for backup and sync action
  ///
  /// In en, this message translates to:
  /// **'Backup your data to cloud'**
  String get backupSyncDescription;

  /// Title for privacy and security action
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// Description for privacy and security action
  ///
  /// In en, this message translates to:
  /// **'Manage your privacy settings'**
  String get privacySecurityDescription;

  /// Title for features that are not yet available
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Message for features that are coming soon
  ///
  /// In en, this message translates to:
  /// **'{feature} will be available in a future update.'**
  String featureComingSoon(String feature);

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Loading text while saving data
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Error message when updating a field fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update {field}: {error}'**
  String failedToUpdate(String field, String error);

  /// Sign out button text
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Notifications setting label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Push notifications setting description
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// Privacy setting label
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Data and privacy setting description
  ///
  /// In en, this message translates to:
  /// **'Data and privacy settings'**
  String get dataPrivacySettings;

  /// Help and support setting label
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// Help and support setting description
  ///
  /// In en, this message translates to:
  /// **'Get help and contact support'**
  String get helpSupportDescription;

  /// Sign out confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account?'**
  String get signOutConfirm;

  /// Loading text while signing out
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get signingOut;

  /// Error message when sign out fails
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out. Please try again.'**
  String get signOutFailed;

  /// Default title for image source selector
  ///
  /// In en, this message translates to:
  /// **'Select Photo Source'**
  String get selectPhotoSource;

  /// Default subtitle for image source selector
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to add your photo'**
  String get choosePhotoMethod;

  /// Camera option in image source selector
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Camera option description
  ///
  /// In en, this message translates to:
  /// **'Take a new photo'**
  String get takeNewPhoto;

  /// Gallery option in image source selector
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Gallery option description
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get chooseFromPhotos;

  /// Error message when profile loading fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {error}'**
  String failedToLoadProfile(String error);

  /// Error message when profile update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String failedToUpdateProfile(String error);

  /// Error message when profile photo update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile photo: {error}'**
  String failedToUpdateProfilePhoto(String error);

  /// Error message when camera permission is denied
  ///
  /// In en, this message translates to:
  /// **'QRaft needs access to your camera to take photos for your profile picture. Please allow camera permission in your device settings.'**
  String get cameraPermissionDenied;

  /// Error message when gallery permission is denied
  ///
  /// In en, this message translates to:
  /// **'QRaft needs access to your photo library to select images for your profile picture. Please allow storage permission in your device settings.'**
  String get galleryPermissionDenied;

  /// Message when user cancels image selection
  ///
  /// In en, this message translates to:
  /// **'Image selection was cancelled.'**
  String get imageSelectionCancelled;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Title for crop image screen
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// Crop button text
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Rotate left button text
  ///
  /// In en, this message translates to:
  /// **'Rotate Left'**
  String get rotateLeft;

  /// Rotate right button text
  ///
  /// In en, this message translates to:
  /// **'Rotate Right'**
  String get rotateRight;

  /// Instruction text for cropping
  ///
  /// In en, this message translates to:
  /// **'Adjust the crop area by dragging the corners'**
  String get cropInstruction;

  /// Error message when image cropping fails
  ///
  /// In en, this message translates to:
  /// **'Failed to crop image. Please try again.'**
  String get cropFailed;

  /// Loading text while processing image
  ///
  /// In en, this message translates to:
  /// **'Processing image...'**
  String get processingImage;

  /// QR Scanner screen title
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get qrScanner;

  /// Instruction text for QR scanner
  ///
  /// In en, this message translates to:
  /// **'Point camera at QR code to scan'**
  String get pointCameraAtQR;

  /// Copy button text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Clear all button text
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Clear all history dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear All History'**
  String get clearAllHistory;

  /// Clear all history confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all scan history? This action cannot be undone.'**
  String get clearAllHistoryConfirm;

  /// Empty state title when no scans exist
  ///
  /// In en, this message translates to:
  /// **'No Scans Yet'**
  String get noScansYet;

  /// Empty state subtitle when no scans exist
  ///
  /// In en, this message translates to:
  /// **'Start scanning QR codes to see your history here'**
  String get startScanningToSeeHistory;

  /// Button text to start scanning
  ///
  /// In en, this message translates to:
  /// **'Start Scanning'**
  String get startScanning;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
