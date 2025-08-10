// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'QRaft';

  @override
  String get welcomeTitle => 'Welcome to QRaft!';

  @override
  String get welcomeSubtitle => 'Your complete solution for custom QR codes';

  @override
  String get featureCreateTitle => 'Create Custom QR';

  @override
  String get featureCreateDescription =>
      'Design and customize your own QR codes for any purpose.';

  @override
  String get featureShareTitle => 'Share Easily';

  @override
  String get featureShareDescription =>
      'Send your QR codes to your contacts or publish them on your social networks.';

  @override
  String get featureEngraveTitle => 'Engrave on Materials';

  @override
  String get featureEngraveDescription =>
      'Get your QR codes engraved on wood, metal and other quality materials.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign In';

  @override
  String get mainFeatures => 'Main Features';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinue =>
      'Sign in to continue creating amazing QR codes';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinQRaft => 'Join QRaft and start creating amazing QR codes';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get createPassword => 'Create a password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Confirm your password';

  @override
  String get agreeToTerms =>
      'I agree to the Terms & Conditions and Privacy Policy';

  @override
  String get alreadyHaveAccountSignIn => 'Already have an account? Sign In';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get passwordMinLengthSignUp =>
      'Password must be at least 8 characters';

  @override
  String get passwordMustContainUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordMustContainLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordMustContainNumber =>
      'Password must contain at least one number';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pleaseAgreeToTerms => 'Please agree to Terms & Conditions';

  @override
  String loginAttempt(String email) {
    return 'Login attempt: $email';
  }

  @override
  String accountCreated(String name) {
    return 'Account created for: $name';
  }

  @override
  String get forgotPasswordComingSoon =>
      'Forgot password functionality coming soon';

  @override
  String get loginSuccessful => 'Login successful! Welcome back.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordSubtitle => 'Enter your email to receive reset link';

  @override
  String get enterEmailForReset => 'Enter your email address';

  @override
  String get sendResetLink => 'Send';

  @override
  String get emailSent => 'Email Sent!';

  @override
  String checkEmailForReset(String email) {
    return 'We\'ve sent a password reset link to $email. Please check your email and follow the instructions to reset your password.';
  }

  @override
  String get done => 'Done';

  @override
  String get profile => 'Profile';

  @override
  String get anonymousUser => 'Anonymous User';

  @override
  String get noEmail => 'No email';

  @override
  String get changeProfilePhoto => 'Change Profile Photo';

  @override
  String get choosePhotoSource =>
      'Choose how you want to update your profile photo';

  @override
  String get updatingProfilePhoto => 'Updating profile photo...';

  @override
  String get profilePhotoUpdatedSuccess =>
      'Profile photo updated successfully!';

  @override
  String get profilePhotoUpdateFailed =>
      'Failed to update profile photo. Please try again.';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String joinedDate(String date) {
    return 'Joined $date';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String monthsAgo(int months, String plural) {
    return '$months month$plural ago';
  }

  @override
  String yearsAgo(int years, String plural) {
    return '$years year$plural ago';
  }

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get displayName => 'Display Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get bio => 'Bio';

  @override
  String get location => 'Location';

  @override
  String get website => 'Website';

  @override
  String get company => 'Company';

  @override
  String get jobTitle => 'Job Title';

  @override
  String enterField(String field) {
    return 'Enter $field';
  }

  @override
  String get notProvided => 'Not provided';

  @override
  String get statistics => 'Statistics';

  @override
  String get qrCodes => 'QR Codes';

  @override
  String get scans => 'Scans';

  @override
  String get orders => 'Orders';

  @override
  String get daysActive => 'Days Active';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get myQRCodes => 'My QR Codes';

  @override
  String get scanHistory => 'Scan History';

  @override
  String get myOrders => 'My Orders';

  @override
  String get shareProfile => 'Share Profile';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataDescription => 'Download your QR codes and data';

  @override
  String get backupSync => 'Backup & Sync';

  @override
  String get backupSyncDescription => 'Backup your data to cloud';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get privacySecurityDescription => 'Manage your privacy settings';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String featureComingSoon(String feature) {
    return '$feature will be available in a future update.';
  }

  @override
  String get ok => 'OK';

  @override
  String get saving => 'Saving...';

  @override
  String get save => 'Save';

  @override
  String failedToUpdate(String field, String error) {
    return 'Failed to update $field: $error';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get close => 'Close';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get dataPrivacySettings => 'Data and privacy settings';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get helpSupportDescription => 'Get help and contact support';

  @override
  String get signOutConfirm =>
      'Are you sure you want to sign out of your account?';

  @override
  String get signingOut => 'Signing out...';

  @override
  String get signOutFailed => 'Failed to sign out. Please try again.';

  @override
  String get selectPhotoSource => 'Select Photo Source';

  @override
  String get choosePhotoMethod => 'Choose how you want to add your photo';

  @override
  String get camera => 'Camera';

  @override
  String get takeNewPhoto => 'Take a new photo';

  @override
  String get gallery => 'Gallery';

  @override
  String get chooseFromPhotos => 'Choose from photos';

  @override
  String failedToLoadProfile(String error) {
    return 'Failed to load profile: $error';
  }

  @override
  String failedToUpdateProfile(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String failedToUpdateProfilePhoto(String error) {
    return 'Failed to update profile photo: $error';
  }

  @override
  String get cameraPermissionDenied =>
      'QRaft needs access to your camera to take photos for your profile picture. Please allow camera permission in your device settings.';

  @override
  String get galleryPermissionDenied =>
      'QRaft needs access to your photo library to select images for your profile picture. Please allow storage permission in your device settings.';

  @override
  String get imageSelectionCancelled => 'Image selection was cancelled.';

  @override
  String get retry => 'Retry';

  @override
  String get cropImage => 'Crop Image';

  @override
  String get crop => 'Crop';

  @override
  String get cancel => 'Cancel';

  @override
  String get rotateLeft => 'Rotate Left';

  @override
  String get rotateRight => 'Rotate Right';

  @override
  String get cropInstruction => 'Adjust the crop area by dragging the corners';

  @override
  String get cropFailed => 'Failed to crop image. Please try again.';

  @override
  String get processingImage => 'Processing image...';

  @override
  String get qrScanner => 'QR Scanner';

  @override
  String get pointCameraAtQR => 'Point camera at QR code to scan';

  @override
  String get copy => 'Copy';

  @override
  String get clearAll => 'Clear All';

  @override
  String get clearAllHistory => 'Clear All History';

  @override
  String get clearAllHistoryConfirm =>
      'Are you sure you want to clear all scan history? This action cannot be undone.';

  @override
  String get noScansYet => 'No Scans Yet';

  @override
  String get startScanningToSeeHistory =>
      'Start scanning QR codes to see your history here';

  @override
  String get startScanning => 'Start Scanning';

  @override
  String get createQRCode => 'Create QR Code';

  @override
  String get chooseQRType => 'Choose the type of QR code you want to create';

  @override
  String get qrFormWebsiteUrl => 'Website URL';

  @override
  String get qrFormWebsiteSubtitle => 'Create a QR code that opens a website';

  @override
  String get urlFieldLabel => 'Website URL';

  @override
  String get urlFieldPlaceholder => 'https://example.com';

  @override
  String get continueButton => 'Continue';

  @override
  String get urlValidationEmpty => 'Please enter a URL';

  @override
  String get urlValidationSpaces => 'URL cannot contain spaces';

  @override
  String get urlValidationInvalid => 'Please enter a valid URL';

  @override
  String get urlValidationDomain => 'Please enter a valid domain';

  @override
  String get customizeQR => 'Customize Your QR';

  @override
  String get customizeQRSubtitle => 'Make your QR code unique';

  @override
  String get foregroundColor => 'Foreground Color';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get eyeColor => 'Eye Color';

  @override
  String get qrSize => 'Size';

  @override
  String get templates => 'Templates';

  @override
  String get logo => 'Logo';

  @override
  String get addLogo => 'Add Logo';

  @override
  String get removeLogo => 'Remove Logo';

  @override
  String get preview => 'Preview';

  @override
  String get generateQR => 'Generate QR';

  @override
  String get qrFormCompleteFields =>
      'Complete all fields correctly to continue';

  @override
  String get qrFormStepEnterInfo => 'Enter information';

  @override
  String get qrFormStepCustomize => 'Customize appearance';

  @override
  String get qrFormStepPreviewSave => 'Preview & save';

  @override
  String get qrFormButtonContinue => 'Continue';

  @override
  String get qrFormButtonPreview => 'Preview';

  @override
  String get qrFormButtonSave => 'Save QR Code';

  @override
  String get generateQRTitle => 'Generate QR';

  @override
  String get generateQRSubtitle => 'Create QR codes for various purposes';

  @override
  String get templateLibrary => 'Template Library';

  @override
  String get templateLibraryDescription => 'Browse pre-designed QR templates';

  @override
  String get qrTypePersonalInfo => 'Personal Info';

  @override
  String get qrTypePersonalInfoDesc => 'Contact details\nvCard format';

  @override
  String get qrTypeWebsiteUrl => 'Website URL';

  @override
  String get qrTypeWebsiteUrlDesc => 'Links to websites\nand web pages';

  @override
  String get qrTypeWifi => 'WiFi Network';

  @override
  String get qrTypeWifiDesc => 'Share WiFi\ncredentials easily';

  @override
  String get qrTypeText => 'Text Message';

  @override
  String get qrTypeTextDesc => 'Plain text content\nfor any purpose';

  @override
  String get qrTypeEmail => 'Email';

  @override
  String get qrTypeEmailDesc => 'Send email with\npre-filled content';

  @override
  String get qrTypeLocation => 'Location';

  @override
  String get qrTypeLocationDesc => 'GPS coordinates\nand map points';

  @override
  String get styleColors => 'Colors';

  @override
  String get backToQRTypes => 'Back to QR Types';

  @override
  String get plannedFeatures => 'Planned Features';

  @override
  String get expectedInNextUpdate => 'Expected in next major update';

  @override
  String qrCodeSizeLabel(int size) {
    return 'QR Code Size: ${size}px';
  }

  @override
  String get logoAdded => 'Logo Added';

  @override
  String get noLogo => 'No Logo';

  @override
  String get logoDescription => 'Add a logo to personalize your QR';

  @override
  String get logoAddedDescription => 'Tap to change or remove';

  @override
  String get changeLogo => 'Change';

  @override
  String get logoUpdateSuccess => 'Logo updated successfully!';

  @override
  String get viewFullSize => 'View Full Size';

  @override
  String get personalInfoFormTitle => 'Personal Information';

  @override
  String get personalInfoFormSubtitle =>
      'Create a vCard with your contact information';

  @override
  String get qrCodeNameLabel => 'QR Code Name *';

  @override
  String get qrCodeNameHint => 'My Contact Card';

  @override
  String get firstName => 'First Name *';

  @override
  String get firstNameHint => 'John';

  @override
  String get lastName => 'Last Name *';

  @override
  String get lastNameHint => 'Doe';

  @override
  String get organization => 'Organization';

  @override
  String get organizationHint => 'Acme Corporation';

  @override
  String get phoneHint => '(555) 123-4567';

  @override
  String get emailHint => 'john@example.com';

  @override
  String get websiteHint => 'https://johndoe.com';

  @override
  String get address => 'Address';

  @override
  String get addressHint => '123 Main St, City, State 12345';

  @override
  String get note => 'Note';

  @override
  String get noteHint => 'Additional information...';

  @override
  String get requiredFieldsMessage => 'Please fill in all required fields (*)';

  @override
  String get searchCountry => 'Search country';
}
