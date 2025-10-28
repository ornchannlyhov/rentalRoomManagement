// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get receiptTab => 'Receipts';

  @override
  String get historyTab => 'Old Data';

  @override
  String get buildingTab => 'Buildings';

  @override
  String get tenantTab => 'Tenants';

  @override
  String get settingsTab => 'Settings';

  @override
  String get detailedAnalysis => 'Detailed Analysis';

  @override
  String get moneyTab => 'Money';

  @override
  String get buildingAnalysisTab => 'Building';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInPrompt => 'Sign in to your account';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get loginButton => 'Login';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get registerLink => 'Register';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpPrompt => 'Sign up to get started';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get registerButton => 'Register';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get loginLink => 'Login';

  @override
  String get buildingsTitle => 'Buildings';

  @override
  String get searchBuildingHint => 'Search building...';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String deleteConfirmMsg(Object building) {
    return 'Are you sure you want to delete building $building?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String buildingDeleted(Object building) {
    return 'Building $building deleted successfully';
  }

  @override
  String deleteFailed(Object error) {
    return 'Failed to delete building: $error';
  }

  @override
  String get noBuildings => 'No buildings';

  @override
  String get noBuildingsSearch => 'No buildings found';

  @override
  String get addNewBuildingHint => 'Tap + to add a new building';

  @override
  String get tryDifferentKeyword => 'Try a different keyword';

  @override
  String get oldDataTitle => 'Old Data';

  @override
  String get searchReceiptHint => 'Search receipts...';

  @override
  String get paidStatus => 'Paid';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get overdueStatus => 'Overdue';

  @override
  String get viewDetail => 'View Details';

  @override
  String get share => 'Share';

  @override
  String get edit => 'Edit';

  @override
  String get deleteOption => 'Delete';

  @override
  String get undo => 'Undo';

  @override
  String get receiptTitle => 'Receipts';

  @override
  String get noReceipts => 'No receipts';

  @override
  String get loading => 'Loading...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get privacySecurity => 'Privacy, security, change password';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get plansPayments => 'Plans, payment methods';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get lightMode => 'Light mode';

  @override
  String get systemDefault => 'System default';

  @override
  String get language => 'Language';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get faqContact => 'FAQs, contact us';

  @override
  String get about => 'About';

  @override
  String get version => 'Version 1.2.3';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get premiumMember => 'Premium Member';

  @override
  String get tenantsTitle => 'Tenants';

  @override
  String get searchTenantHint => 'Search tenant...';

  @override
  String tenantAdded(Object tenant) {
    return 'Tenant $tenant added successfully';
  }

  @override
  String get tenantAddFailed => 'Error adding tenant';

  @override
  String tenantUpdated(Object tenant) {
    return 'Tenant $tenant updated successfully';
  }

  @override
  String get tenantUpdateFailed => 'Error updating tenant';

  @override
  String tenantDeleted(Object tenant) {
    return 'Tenant $tenant deleted';
  }

  @override
  String get tenantDeleteFailed => 'Error deleting tenant';

  @override
  String roomChanged(Object tenant, Object room) {
    return 'Room for $tenant changed to $room';
  }

  @override
  String get roomChangeFailed => 'Error undoing room change';

  @override
  String get retryLoadingProfile => 'Retry Loading Profile';

  @override
  String get noLoggedIn => 'You are not logged in.';

  @override
  String get goToOnboarding => 'Go to Onboarding';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get noEmailProvided => 'No Email Provided';

  @override
  String get editProfileTapped => 'Edit profile tapped';

  @override
  String get signOutSuccess => 'Signed out successfully!';

  @override
  String get signOutFailed => 'Failed to sign out';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Confirm your password';

  @override
  String get manageBuildings => 'Manage Buildings & Rooms';

  @override
  String get manageBuildingsDesc => 'Manage your buildings, rooms, and services easily with our intuitive interface.';

  @override
  String get tenantManagement => 'Tenant Management';

  @override
  String get tenantManagementDesc => 'Assign tenants and automate receipts with just a few taps.';

  @override
  String get paymentTracking => 'Payment Tracking';

  @override
  String get paymentTrackingDesc => 'Track payments easily - Pending, Paid, and Overdue status at a glance.';

  @override
  String get automationTools => 'Automation Tools';

  @override
  String get automationToolsDesc => 'Automate work with Telegram bot reminders and utilities input.';
}
