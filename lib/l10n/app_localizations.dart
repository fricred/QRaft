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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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

  /// Welcome message with user name in dashboard
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String welcomeBackUser(String name);

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

  /// Title for permission denied dialog with permission type
  ///
  /// In en, this message translates to:
  /// **'{permissionType} Permission'**
  String permissionDeniedTitle(String permissionType);

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

  /// QR Generation screen title
  ///
  /// In en, this message translates to:
  /// **'Create QR Code'**
  String get createQRCode;

  /// QR Generation subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose the type of QR code you want to create'**
  String get chooseQRType;

  /// Website URL form title
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get qrFormWebsiteUrl;

  /// Website URL form subtitle
  ///
  /// In en, this message translates to:
  /// **'Create a QR code that opens a website'**
  String get qrFormWebsiteSubtitle;

  /// URL field label in QR form
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get urlFieldLabel;

  /// URL field placeholder
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get urlFieldPlaceholder;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// URL validation error - empty field
  ///
  /// In en, this message translates to:
  /// **'Please enter a URL'**
  String get urlValidationEmpty;

  /// URL validation error - contains spaces
  ///
  /// In en, this message translates to:
  /// **'URL cannot contain spaces'**
  String get urlValidationSpaces;

  /// URL validation error - invalid format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get urlValidationInvalid;

  /// URL validation error - invalid domain
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid domain'**
  String get urlValidationDomain;

  /// QR Customization screen title
  ///
  /// In en, this message translates to:
  /// **'Customize Your QR'**
  String get customizeQR;

  /// QR Customization subtitle
  ///
  /// In en, this message translates to:
  /// **'Make your QR code unique'**
  String get customizeQRSubtitle;

  /// Foreground color section title
  ///
  /// In en, this message translates to:
  /// **'Foreground Color'**
  String get foregroundColor;

  /// Background color section title
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// Eye color section title
  ///
  /// In en, this message translates to:
  /// **'Eye Color'**
  String get eyeColor;

  /// QR size section title
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get qrSize;

  /// Template selection title
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// Logo section title
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// Add logo button text
  ///
  /// In en, this message translates to:
  /// **'Add Logo'**
  String get addLogo;

  /// Remove logo button text
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get removeLogo;

  /// Preview button text
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Generate QR button text
  ///
  /// In en, this message translates to:
  /// **'Generate QR'**
  String get generateQR;

  /// Message shown when form fields are incomplete
  ///
  /// In en, this message translates to:
  /// **'Complete all fields correctly to continue'**
  String get qrFormCompleteFields;

  /// Step 1 title for QR form
  ///
  /// In en, this message translates to:
  /// **'Enter information'**
  String get qrFormStepEnterInfo;

  /// Step 2 title for QR form
  ///
  /// In en, this message translates to:
  /// **'Customize appearance'**
  String get qrFormStepCustomize;

  /// Step 3 title for QR form
  ///
  /// In en, this message translates to:
  /// **'Preview & save'**
  String get qrFormStepPreviewSave;

  /// Continue button text in QR form
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get qrFormButtonContinue;

  /// Preview button text in QR form
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get qrFormButtonPreview;

  /// Save button text in QR form
  ///
  /// In en, this message translates to:
  /// **'Save QR Code'**
  String get qrFormButtonSave;

  /// QR Generator screen main title
  ///
  /// In en, this message translates to:
  /// **'Generate QR'**
  String get generateQRTitle;

  /// QR Generator screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Create QR codes for various purposes'**
  String get generateQRSubtitle;

  /// Template library section title
  ///
  /// In en, this message translates to:
  /// **'Template Library'**
  String get templateLibrary;

  /// Template library section description
  ///
  /// In en, this message translates to:
  /// **'Browse pre-designed QR templates'**
  String get templateLibraryDescription;

  /// Personal info QR type name
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get qrTypePersonalInfo;

  /// Personal info QR type description
  ///
  /// In en, this message translates to:
  /// **'Contact details\nvCard format'**
  String get qrTypePersonalInfoDesc;

  /// Website URL QR type name
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get qrTypeWebsiteUrl;

  /// Website URL QR type description
  ///
  /// In en, this message translates to:
  /// **'Links to websites\nand web pages'**
  String get qrTypeWebsiteUrlDesc;

  /// WiFi QR type name
  ///
  /// In en, this message translates to:
  /// **'WiFi Network'**
  String get qrTypeWifi;

  /// WiFi QR type description
  ///
  /// In en, this message translates to:
  /// **'Share WiFi\ncredentials easily'**
  String get qrTypeWifiDesc;

  /// Text QR type name
  ///
  /// In en, this message translates to:
  /// **'Text Message'**
  String get qrTypeText;

  /// Text QR type description
  ///
  /// In en, this message translates to:
  /// **'Plain text content\nfor any purpose'**
  String get qrTypeTextDesc;

  /// Email QR type name
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get qrTypeEmail;

  /// Email QR type description
  ///
  /// In en, this message translates to:
  /// **'Send email with\npre-filled content'**
  String get qrTypeEmailDesc;

  /// Location QR type name
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get qrTypeLocation;

  /// Location QR type description
  ///
  /// In en, this message translates to:
  /// **'GPS coordinates\nand map points'**
  String get qrTypeLocationDesc;

  /// Style section colors title
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get styleColors;

  /// Button text to go back to QR type selection
  ///
  /// In en, this message translates to:
  /// **'Back to QR Types'**
  String get backToQRTypes;

  /// Title for planned features section
  ///
  /// In en, this message translates to:
  /// **'Planned Features'**
  String get plannedFeatures;

  /// Text indicating feature will be available in next update
  ///
  /// In en, this message translates to:
  /// **'Expected in next major update'**
  String get expectedInNextUpdate;

  /// Label showing QR code size
  ///
  /// In en, this message translates to:
  /// **'QR Code Size: {size}px'**
  String qrCodeSizeLabel(int size);

  /// Text shown when logo is added
  ///
  /// In en, this message translates to:
  /// **'Logo Added'**
  String get logoAdded;

  /// Text shown when no logo is present
  ///
  /// In en, this message translates to:
  /// **'No Logo'**
  String get noLogo;

  /// Description for logo functionality
  ///
  /// In en, this message translates to:
  /// **'Add a logo to personalize your QR'**
  String get logoDescription;

  /// Description when logo is already added
  ///
  /// In en, this message translates to:
  /// **'Tap to change or remove'**
  String get logoAddedDescription;

  /// Button text to change logo
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLogo;

  /// Success message when logo is updated
  ///
  /// In en, this message translates to:
  /// **'Logo updated successfully!'**
  String get logoUpdateSuccess;

  /// Button text to view QR code at full size
  ///
  /// In en, this message translates to:
  /// **'View Full Size'**
  String get viewFullSize;

  /// Personal info form title
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfoFormTitle;

  /// Personal info form subtitle
  ///
  /// In en, this message translates to:
  /// **'Create a vCard with your contact information'**
  String get personalInfoFormSubtitle;

  /// QR code name field label
  ///
  /// In en, this message translates to:
  /// **'QR Code Name *'**
  String get qrCodeNameLabel;

  /// QR code name field hint
  ///
  /// In en, this message translates to:
  /// **'My Contact Card'**
  String get qrCodeNameHint;

  /// First name field label
  ///
  /// In en, this message translates to:
  /// **'First Name *'**
  String get firstName;

  /// First name field hint
  ///
  /// In en, this message translates to:
  /// **'John'**
  String get firstNameHint;

  /// Last name field label
  ///
  /// In en, this message translates to:
  /// **'Last Name *'**
  String get lastName;

  /// Last name field hint
  ///
  /// In en, this message translates to:
  /// **'Doe'**
  String get lastNameHint;

  /// Organization field label
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// Organization field hint
  ///
  /// In en, this message translates to:
  /// **'Acme Corporation'**
  String get organizationHint;

  /// Phone field hint
  ///
  /// In en, this message translates to:
  /// **'(555) 123-4567'**
  String get phoneHint;

  /// Email field hint
  ///
  /// In en, this message translates to:
  /// **'john@example.com'**
  String get emailHint;

  /// Website field hint
  ///
  /// In en, this message translates to:
  /// **'https://johndoe.com'**
  String get websiteHint;

  /// Address field label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Address field hint
  ///
  /// In en, this message translates to:
  /// **'123 Main St, City, State 12345'**
  String get addressHint;

  /// Note field label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Note field hint
  ///
  /// In en, this message translates to:
  /// **'Additional information...'**
  String get noteHint;

  /// Message for required fields validation
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields (*)'**
  String get requiredFieldsMessage;

  /// Hint text for country search in phone input
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// Email form title
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailFormTitle;

  /// Email form subtitle
  ///
  /// In en, this message translates to:
  /// **'Create QR code for sending pre-filled email'**
  String get emailFormSubtitle;

  /// Email QR name field hint
  ///
  /// In en, this message translates to:
  /// **'Email QR'**
  String get emailQrNameHint;

  /// Email recipient field label
  ///
  /// In en, this message translates to:
  /// **'Email Address *'**
  String get emailRecipientLabel;

  /// Email recipient field hint
  ///
  /// In en, this message translates to:
  /// **'recipient@example.com'**
  String get emailRecipientHint;

  /// Email subject field label
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get emailSubjectLabel;

  /// Email subject field hint
  ///
  /// In en, this message translates to:
  /// **'Email subject...'**
  String get emailSubjectHint;

  /// Email body field label
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get emailBodyLabel;

  /// Email body field hint
  ///
  /// In en, this message translates to:
  /// **'Type your message here...'**
  String get emailBodyHint;

  /// WiFi form section title
  ///
  /// In en, this message translates to:
  /// **'WiFi Network Details'**
  String get wifiNetworkDetails;

  /// WiFi form description text
  ///
  /// In en, this message translates to:
  /// **'Enter WiFi network details to create a QR code for easy sharing'**
  String get wifiFormDescription;

  /// WiFi network name field label
  ///
  /// In en, this message translates to:
  /// **'Network Name (SSID) *'**
  String get networkNameLabel;

  /// WiFi network name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter WiFi network name'**
  String get networkNameHint;

  /// WiFi password field label
  ///
  /// In en, this message translates to:
  /// **'Password *'**
  String get wifiPasswordLabel;

  /// WiFi password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter WiFi password'**
  String get wifiPasswordHint;

  /// WiFi security type section title
  ///
  /// In en, this message translates to:
  /// **'Security Type'**
  String get securityType;

  /// WPA security type option
  ///
  /// In en, this message translates to:
  /// **'WPA/WPA2 (Recommended)'**
  String get securityWpaRecommended;

  /// WEP security type option
  ///
  /// In en, this message translates to:
  /// **'WEP (Legacy)'**
  String get securityWepLegacy;

  /// Open network security type option
  ///
  /// In en, this message translates to:
  /// **'Open Network (No Password)'**
  String get securityOpenNetwork;

  /// Hidden network toggle label
  ///
  /// In en, this message translates to:
  /// **'Hidden Network'**
  String get hiddenNetwork;

  /// Hidden network toggle description
  ///
  /// In en, this message translates to:
  /// **'Network name is not broadcasted publicly'**
  String get hiddenNetworkDescription;

  /// Network name validation error
  ///
  /// In en, this message translates to:
  /// **'Network name is required'**
  String get networkNameRequired;

  /// Network name length validation error
  ///
  /// In en, this message translates to:
  /// **'Network name must be 32 characters or less'**
  String get networkNameTooLong;

  /// Password validation error for secured networks
  ///
  /// In en, this message translates to:
  /// **'Password is required for secured networks'**
  String get passwordRequiredForSecuredNetworks;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be 63 characters or less'**
  String get passwordTooLong;

  /// QR code size slider title
  ///
  /// In en, this message translates to:
  /// **'QR Code Size'**
  String get qrCodeSizeTitle;

  /// Small size label
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// Medium size label
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// Large size label
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// Title when logo is added
  ///
  /// In en, this message translates to:
  /// **'Logo Added'**
  String get logoAddedTitle;

  /// Title when no logo is present
  ///
  /// In en, this message translates to:
  /// **'No Logo'**
  String get noLogoTitle;

  /// Description for added logo
  ///
  /// In en, this message translates to:
  /// **'Your logo will appear in the center of the QR code'**
  String get logoWillAppearInCenter;

  /// Description to encourage logo addition
  ///
  /// In en, this message translates to:
  /// **'Add a logo to personalize your QR code'**
  String get addLogoToPersonalize;

  /// Remove button text
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Change button text
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Preview placeholder text when form is incomplete
  ///
  /// In en, this message translates to:
  /// **'Complete form\nto see preview'**
  String get completeFormToSeePreview;

  /// Success message when logo is updated
  ///
  /// In en, this message translates to:
  /// **'Logo updated successfully!'**
  String get logoUpdatedSuccessfully;

  /// Error message when image picker fails
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failedToPickImage(String error);

  /// Location form section title
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get locationFormTitle;

  /// Location form description text
  ///
  /// In en, this message translates to:
  /// **'Share your location or any GPS coordinates with a QR code'**
  String get locationFormDescription;

  /// Location name field label
  ///
  /// In en, this message translates to:
  /// **'Location Name'**
  String get locationNameLabel;

  /// Location name field hint
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get locationNameHint;

  /// Location name validation error
  ///
  /// In en, this message translates to:
  /// **'Location name is required'**
  String get locationNameRequired;

  /// Location name minimum length validation error
  ///
  /// In en, this message translates to:
  /// **'Location name must be at least 2 characters'**
  String get locationNameTooShort;

  /// Latitude field label
  ///
  /// In en, this message translates to:
  /// **'Latitude *'**
  String get latitudeLabel;

  /// Latitude field hint
  ///
  /// In en, this message translates to:
  /// **'40.7128'**
  String get latitudeHint;

  /// Longitude field label
  ///
  /// In en, this message translates to:
  /// **'Longitude *'**
  String get longitudeLabel;

  /// Longitude field hint
  ///
  /// In en, this message translates to:
  /// **'-74.0060'**
  String get longitudeHint;

  /// Button text to use current location
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// Button text to pick location from map
  ///
  /// In en, this message translates to:
  /// **'Pick from Map'**
  String get pickFromMap;

  /// Location options section title
  ///
  /// In en, this message translates to:
  /// **'Location Options'**
  String get locationOptions;

  /// Manual entry option title
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// Manual entry option description
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates manually'**
  String get manualEntryDesc;

  /// Current location option description
  ///
  /// In en, this message translates to:
  /// **'Use device GPS location'**
  String get currentLocationDesc;

  /// Map location option description
  ///
  /// In en, this message translates to:
  /// **'Select point on interactive map'**
  String get mapLocationDesc;

  /// Latitude validation error
  ///
  /// In en, this message translates to:
  /// **'Latitude is required'**
  String get latitudeRequired;

  /// Longitude validation error
  ///
  /// In en, this message translates to:
  /// **'Longitude is required'**
  String get longitudeRequired;

  /// Latitude validation error for invalid range
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid latitude (-90 to 90)'**
  String get latitudeInvalid;

  /// Longitude validation error for invalid range
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid longitude (-180 to 180)'**
  String get longitudeInvalid;

  /// Error message when location permission is needed
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to use current location'**
  String get locationPermissionRequired;

  /// Error message when location services are disabled
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in settings'**
  String get locationServiceDisabled;

  /// Loading message while getting current location
  ///
  /// In en, this message translates to:
  /// **'Getting current location...'**
  String get gettingCurrentLocation;

  /// Success message when location is obtained
  ///
  /// In en, this message translates to:
  /// **'Location obtained successfully!'**
  String get locationObtained;

  /// Error message when getting location fails
  ///
  /// In en, this message translates to:
  /// **'Failed to get current location: {error}'**
  String failedToGetLocation(String error);

  /// Map picker screen title
  ///
  /// In en, this message translates to:
  /// **'Select Location on Map'**
  String get selectLocationOnMap;

  /// Map picker instruction
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to select a location'**
  String get tapMapToSelectLocation;

  /// Button text to confirm selected location
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// Label for selected location info
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// Success message when current location is found
  ///
  /// In en, this message translates to:
  /// **'Current location found'**
  String get currentLocationFound;

  /// Message when using default location
  ///
  /// In en, this message translates to:
  /// **'Using default location - tap to select'**
  String get usingDefaultLocation;

  /// Button text to use current location as selected
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrent;

  /// Error message when map fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load map. Please check your internet connection'**
  String get mapLoadingError;

  /// QR Library screen title
  ///
  /// In en, this message translates to:
  /// **'QR Library'**
  String get qrLibrary;

  /// QR Library subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your QR codes'**
  String get manageQRCodes;

  /// My QRs tab title
  ///
  /// In en, this message translates to:
  /// **'My QRs'**
  String get myQRs;

  /// Favorites tab title
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Recent tab title
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// Total QR codes statistic label
  ///
  /// In en, this message translates to:
  /// **'Total QRs'**
  String get totalQRs;

  /// This month statistic label
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Empty state title when no QR codes exist
  ///
  /// In en, this message translates to:
  /// **'No QR Codes Yet'**
  String get noQRCodesYet;

  /// Empty state subtitle when no QR codes exist
  ///
  /// In en, this message translates to:
  /// **'Create your first QR code to see it here'**
  String get createFirstQRCode;

  /// Empty state title when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No QR Codes Found'**
  String get noQRCodesFound;

  /// Button text to clear search filters
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// Hint text when search returns no results
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// Filter chip label for all QR types
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter chip label for URL QR type
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get filterUrl;

  /// Filter chip label for WiFi QR type
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get filterWifi;

  /// Filter chip label for Email QR type
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get filterEmail;

  /// Filter chip label for vCard QR type
  ///
  /// In en, this message translates to:
  /// **'vCard'**
  String get filterVcard;

  /// Filter chip label for Location QR type
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get filterLocation;

  /// Filter chip label for Text QR type
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get filterText;

  /// Empty state title when no favorite QR codes exist
  ///
  /// In en, this message translates to:
  /// **'No Favorites Yet'**
  String get noFavoritesYet;

  /// Empty state subtitle for favorites tab
  ///
  /// In en, this message translates to:
  /// **'Star your favorite QR codes to see them here'**
  String get starFavoriteQRCodes;

  /// Empty state title when no recent QR codes exist
  ///
  /// In en, this message translates to:
  /// **'No Recent QRs'**
  String get noRecentQRs;

  /// Empty state subtitle for recent tab
  ///
  /// In en, this message translates to:
  /// **'Your recently created QR codes will appear here'**
  String get recentQRCodesAppearHere;

  /// Search dialog title
  ///
  /// In en, this message translates to:
  /// **'Search QR Codes'**
  String get searchQRCodes;

  /// Search input placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search by name, type, or content...'**
  String get searchByNameTypeContent;

  /// Search button text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Search not implemented message
  ///
  /// In en, this message translates to:
  /// **'Search functionality will be implemented soon'**
  String get searchFunctionalityComingSoon;

  /// Edit action text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete action text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Share action text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete QR Code'**
  String get deleteQRCode;

  /// Delete confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deleteQRConfirmation(String name);

  /// Success message when QR added to favorites
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\" to favorites!'**
  String addedToFavorites(String name);

  /// Success message when QR removed from favorites
  ///
  /// In en, this message translates to:
  /// **'Removed \"{name}\" from favorites'**
  String removedFromFavorites(String name);

  /// Error message when favorite update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorite: {error}'**
  String failedToUpdateFavorite(String error);

  /// Message when sharing QR code
  ///
  /// In en, this message translates to:
  /// **'Sharing \"{name}\" QR code...'**
  String sharingQRCode(String name);

  /// Message when edit is not yet implemented
  ///
  /// In en, this message translates to:
  /// **'Edit functionality for \"{name}\" coming soon!'**
  String editFunctionalityComingSoon(String name);

  /// Success message when QR deleted
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" deleted successfully'**
  String deletedSuccessfully(String name);

  /// Error message when QR deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete QR code: {error}'**
  String failedToDeleteQRCode(String error);

  /// Share not implemented message
  ///
  /// In en, this message translates to:
  /// **'Share functionality will be implemented soon'**
  String get shareFunctionalityComingSoon;

  /// Time format for very recent items
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Time format for minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// Time format for hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// Time format for days ago (short version)
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgoShort(int days);

  /// Label for QR code type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Edit profile button and modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Save changes button text
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Discard changes dialog title
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// Discard changes dialog message
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get discardChangesMessage;

  /// Keep editing button in discard dialog
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get keepEditing;

  /// Discard button in discard dialog
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Personal details section title in edit profile
  ///
  /// In en, this message translates to:
  /// **'PERSONAL DETAILS'**
  String get personalDetails;

  /// Work and social section title in edit profile
  ///
  /// In en, this message translates to:
  /// **'WORK & SOCIAL'**
  String get workAndSocial;

  /// Success message when profile is updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// Hint text for display name field
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterDisplayName;

  /// Hint text for phone number field
  ///
  /// In en, this message translates to:
  /// **'+1 234 567 8900'**
  String get enterPhoneNumber;

  /// Hint text for bio field
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get enterBio;

  /// Hint text for location field
  ///
  /// In en, this message translates to:
  /// **'City, Country'**
  String get enterLocation;

  /// Hint text for company field
  ///
  /// In en, this message translates to:
  /// **'Your company name'**
  String get enterCompany;

  /// Hint text for job title field
  ///
  /// In en, this message translates to:
  /// **'Your job title'**
  String get enterJobTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @scanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get scanner;

  /// No description provided for @libraryNav.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryNav;

  /// No description provided for @marketplaceNav.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceNav;

  /// No description provided for @recentQRCodes.
  ///
  /// In en, this message translates to:
  /// **'Recent QR Codes'**
  String get recentQRCodes;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @createQR.
  ///
  /// In en, this message translates to:
  /// **'Create QR'**
  String get createQR;

  /// No description provided for @createQRDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate new QR code'**
  String get createQRDescription;

  /// No description provided for @scanQRAction.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQRAction;

  /// No description provided for @scanQRDescription.
  ///
  /// In en, this message translates to:
  /// **'Open camera scanner'**
  String get scanQRDescription;

  /// No description provided for @myLibraryAction.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get myLibraryAction;

  /// No description provided for @myLibraryDescription.
  ///
  /// In en, this message translates to:
  /// **'View saved QR codes'**
  String get myLibraryDescription;

  /// No description provided for @marketplaceAction.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceAction;

  /// No description provided for @marketplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Order laser engraving'**
  String get marketplaceDescription;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera Unavailable'**
  String get cameraUnavailable;

  /// No description provided for @initializingCamera.
  ///
  /// In en, this message translates to:
  /// **'Initializing Camera...'**
  String get initializingCamera;

  /// No description provided for @tapToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap the scan button to start detecting QR codes'**
  String get tapToScan;

  /// No description provided for @cameraInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Camera initialization failed'**
  String get cameraInitFailed;

  /// No description provided for @noCameraAvailable.
  ///
  /// In en, this message translates to:
  /// **'No camera available. Please use a physical device to scan QR codes.'**
  String get noCameraAvailable;

  /// No description provided for @cameraPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied. Please enable in Settings.'**
  String get cameraPermissionDeniedMessage;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error'**
  String get cameraError;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @dismissButton.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissButton;

  /// No description provided for @failedToOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to open app settings: {error}'**
  String failedToOpenSettings(String error);

  /// No description provided for @editQRCode.
  ///
  /// In en, this message translates to:
  /// **'Edit QR Code'**
  String get editQRCode;

  /// No description provided for @formTab.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get formTab;

  /// No description provided for @styleTab.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get styleTab;

  /// No description provided for @saveChangesBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesBtn;

  /// No description provided for @customizeYourQR.
  ///
  /// In en, this message translates to:
  /// **'Customize your QR'**
  String get customizeYourQR;

  /// No description provided for @qrColorLabel.
  ///
  /// In en, this message translates to:
  /// **'QR Color'**
  String get qrColorLabel;

  /// No description provided for @backgroundLabel.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundLabel;

  /// No description provided for @eyeColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Eye Color'**
  String get eyeColorLabel;

  /// No description provided for @sizeSmallPx.
  ///
  /// In en, this message translates to:
  /// **'150px'**
  String get sizeSmallPx;

  /// No description provided for @sizeLargePx.
  ///
  /// In en, this message translates to:
  /// **'500px'**
  String get sizeLargePx;

  /// No description provided for @qrSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'QR code \"{name}\" saved successfully!'**
  String qrSavedSuccess(String name);

  /// No description provided for @qrUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'QR code \"{name}\" updated successfully!'**
  String qrUpdatedSuccess(String name);

  /// No description provided for @failedToSaveQR.
  ///
  /// In en, this message translates to:
  /// **'Failed to save QR code: {error}'**
  String failedToSaveQR(String error);

  /// No description provided for @wifiQrUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'WiFi QR code \"{name}\" updated successfully!'**
  String wifiQrUpdatedSuccess(String name);

  /// No description provided for @wifiQrSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'WiFi QR code \"{name}\" saved successfully!'**
  String wifiQrSavedSuccess(String name);

  /// No description provided for @wifiQrPrefix.
  ///
  /// In en, this message translates to:
  /// **'WiFi: {name}'**
  String wifiQrPrefix(String name);

  /// No description provided for @colorsSection.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colorsSection;

  /// No description provided for @sizeSection.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeSection;

  /// No description provided for @logoSection.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logoSection;

  /// No description provided for @textMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Text Message'**
  String get textMessageTitle;

  /// No description provided for @textFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter any text you want to share via QR code'**
  String get textFormDescription;

  /// No description provided for @textContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Text Content'**
  String get textContentLabel;

  /// No description provided for @textContentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your message...'**
  String get textContentHint;

  /// No description provided for @textInformation.
  ///
  /// In en, this message translates to:
  /// **'Text Information'**
  String get textInformation;

  /// No description provided for @charactersCount.
  ///
  /// In en, this message translates to:
  /// **'Characters: {count}'**
  String charactersCount(int count);

  /// No description provided for @charStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get charStatusEmpty;

  /// No description provided for @charStatusOptimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get charStatusOptimal;

  /// No description provided for @charStatusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get charStatusGood;

  /// No description provided for @charStatusLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get charStatusLarge;

  /// No description provided for @pleaseEnterText.
  ///
  /// In en, this message translates to:
  /// **'Please enter your text'**
  String get pleaseEnterText;

  /// No description provided for @textTooLong.
  ///
  /// In en, this message translates to:
  /// **'Text is too long (max {max} characters)'**
  String textTooLong(int max);

  /// No description provided for @qrNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for your QR code'**
  String get qrNameRequired;

  /// No description provided for @qrNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get qrNameTooShort;

  /// No description provided for @qrNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long (max {max} characters)'**
  String qrNameTooLong(int max);

  /// No description provided for @qrCodeNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'QR Code Name'**
  String get qrCodeNameFieldLabel;

  /// No description provided for @myTextMessage.
  ///
  /// In en, this message translates to:
  /// **'My Text Message'**
  String get myTextMessage;

  /// No description provided for @previewText.
  ///
  /// In en, this message translates to:
  /// **'Preview: {text}'**
  String previewText(String text);

  /// No description provided for @emailAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Email address is required'**
  String get emailAddressRequired;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailFormat;

  /// No description provided for @contactsPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is required to import email addresses'**
  String get contactsPermissionRequired;

  /// No description provided for @noContactsWithEmail.
  ///
  /// In en, this message translates to:
  /// **'No contacts with email addresses found'**
  String get noContactsWithEmail;

  /// No description provided for @contactImportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Contact email imported successfully!'**
  String get contactImportedSuccess;

  /// No description provided for @failedToImportContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to import contact'**
  String get failedToImportContact;

  /// No description provided for @contactsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission denied. Please enable it in device settings.'**
  String get contactsPermissionDenied;

  /// No description provided for @contactsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Contact access is not available on this device.'**
  String get contactsNotAvailable;

  /// No description provided for @selectContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Select Contact Email'**
  String get selectContactEmail;

  /// No description provided for @unknownContact.
  ///
  /// In en, this message translates to:
  /// **'Unknown Contact'**
  String get unknownContact;

  /// No description provided for @enterWebsiteURL.
  ///
  /// In en, this message translates to:
  /// **'Enter the website URL you want to share'**
  String get enterWebsiteURL;

  /// No description provided for @protocolAutoAdded.
  ///
  /// In en, this message translates to:
  /// **'Protocol (https://) will be added automatically'**
  String get protocolAutoAdded;

  /// No description provided for @myWebsite.
  ///
  /// In en, this message translates to:
  /// **'My Website'**
  String get myWebsite;

  /// No description provided for @qrNameHelp.
  ///
  /// In en, this message translates to:
  /// **'This name will help you identify your QR code'**
  String get qrNameHelp;

  /// No description provided for @fillFormToPreview.
  ///
  /// In en, this message translates to:
  /// **'Fill in the form to see preview'**
  String get fillFormToPreview;

  /// No description provided for @validURLExamples.
  ///
  /// In en, this message translates to:
  /// **'Valid URL examples:'**
  String get validURLExamples;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long'**
  String get nameTooLong;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationTitle;

  /// No description provided for @shareGPSCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Share GPS coordinates and map points'**
  String get shareGPSCoordinates;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get comingSoonTitle;

  /// No description provided for @locationQrComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Location QR generator is under development and will be available soon.'**
  String get locationQrComingSoon;

  /// No description provided for @wifiQrComingSoon.
  ///
  /// In en, this message translates to:
  /// **'WiFi QR generator is under development and will be available soon.'**
  String get wifiQrComingSoon;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @softwareDeveloperHint.
  ///
  /// In en, this message translates to:
  /// **'Software Developer'**
  String get softwareDeveloperHint;

  /// No description provided for @searchQRCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Search QR Codes'**
  String get searchQRCodesTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by name, type, or content...'**
  String get searchPlaceholder;

  /// No description provided for @searchComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Search functionality will be implemented soon'**
  String get searchComingSoon;

  /// No description provided for @editQRCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit QR Code'**
  String get editQRCodeTitle;

  /// No description provided for @editTypeName.
  ///
  /// In en, this message translates to:
  /// **'Edit {type} QR Codes'**
  String editTypeName(String type);

  /// No description provided for @editNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Coming soon! Currently only URL and Text QR codes can be edited.'**
  String get editNotSupported;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @qrCodeDetails.
  ///
  /// In en, this message translates to:
  /// **'QR Code Details'**
  String get qrCodeDetails;

  /// No description provided for @qrContent.
  ///
  /// In en, this message translates to:
  /// **'QR Content'**
  String get qrContent;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdLabel;

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdatedLabel;

  /// No description provided for @copyData.
  ///
  /// In en, this message translates to:
  /// **'Copy Data'**
  String get copyData;

  /// No description provided for @deletingBtn.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deletingBtn;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @editVCardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Editing vCard QR codes is coming soon'**
  String get editVCardComingSoon;

  /// No description provided for @editWifiComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Editing WiFi QR codes is coming soon'**
  String get editWifiComingSoon;

  /// No description provided for @editEmailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Editing Email QR codes is coming soon'**
  String get editEmailComingSoon;

  /// No description provided for @editLocationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Editing Location QR codes is coming soon'**
  String get editLocationComingSoon;

  /// No description provided for @editTypeNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Editing {type} QR codes is not supported yet'**
  String editTypeNotSupported(String type);

  /// No description provided for @qrDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'QR code deleted successfully'**
  String get qrDeletedSuccess;

  /// No description provided for @failedToDeleteQR.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete QR code: {error}'**
  String failedToDeleteQR(String error);

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String yesterdayAt(String time);

  /// No description provided for @daysAgoFormat.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgoFormat(int days);

  /// No description provided for @downloadQRData.
  ///
  /// In en, this message translates to:
  /// **'Download your QR codes and data'**
  String get downloadQRData;

  /// No description provided for @backupToCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup your data to cloud'**
  String get backupToCloud;

  /// No description provided for @managePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Manage your privacy settings'**
  String get managePrivacy;

  /// No description provided for @savingBtn.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingBtn;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @openSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Open Settings > {section} > {title} to enable access.'**
  String openSettingsMessage(String section, String title);

  /// Product in stock badge text
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// Product out of stock badge text
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// Default product description when none is provided
  ///
  /// In en, this message translates to:
  /// **'High-quality laser-engraved product with your custom QR code.'**
  String get defaultProductDescription;

  /// Customization section title in product details
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get customization;

  /// Size selector label
  ///
  /// In en, this message translates to:
  /// **'Select Size'**
  String get selectSize;

  /// Finish selector label
  ///
  /// In en, this message translates to:
  /// **'Select Finish'**
  String get selectFinish;

  /// Product gallery section title
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get productGallery;

  /// Gallery placeholder label for front view
  ///
  /// In en, this message translates to:
  /// **'Front View'**
  String get galleryFrontView;

  /// Gallery placeholder label for 3D preview
  ///
  /// In en, this message translates to:
  /// **'3D Preview'**
  String get gallery3DPreview;

  /// Gallery placeholder label for QR code view
  ///
  /// In en, this message translates to:
  /// **'With QR Code'**
  String get galleryWithQRCode;

  /// Product features section title
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// Feature text for precision engraving
  ///
  /// In en, this message translates to:
  /// **'Precision laser engraving'**
  String get featurePrecisionEngraving;

  /// Feature prefix for high quality material
  ///
  /// In en, this message translates to:
  /// **'High-quality'**
  String get featureHighQuality;

  /// Feature text for custom QR design
  ///
  /// In en, this message translates to:
  /// **'Custom QR code design'**
  String get featureCustomQRDesign;

  /// Feature text for durability
  ///
  /// In en, this message translates to:
  /// **'Durable and long-lasting'**
  String get featureDurable;

  /// Total price label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Add to cart button text
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// Added to cart success text
  ///
  /// In en, this message translates to:
  /// **'Added!'**
  String get added;

  /// Added to cart success message suffix
  ///
  /// In en, this message translates to:
  /// **'added to cart!'**
  String get addedToCart;

  /// View cart action button text
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get viewCart;

  /// Error message when adding product to cart fails
  ///
  /// In en, this message translates to:
  /// **'Error adding to cart. Please try again.'**
  String get errorAddingToCart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
