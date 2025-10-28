import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

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
    Locale('km')
  ];

  /// No description provided for @receiptTab.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'Old Data'**
  String get historyTab;

  /// No description provided for @buildingTab.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get buildingTab;

  /// No description provided for @tenantTab.
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get tenantTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @detailedAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Detailed Analysis'**
  String get detailedAnalysis;

  /// No description provided for @moneyTab.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get moneyTab;

  /// No description provided for @buildingAnalysisTab.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get buildingAnalysisTab;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInPrompt;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get signUpPrompt;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLink;

  /// No description provided for @buildingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get buildingsTitle;

  /// No description provided for @searchBuildingHint.
  ///
  /// In en, this message translates to:
  /// **'Search building...'**
  String get searchBuildingHint;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Confirmation message for deleting a building
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete building {building}?'**
  String deleteConfirmMsg(Object building);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Success message after deleting a building
  ///
  /// In en, this message translates to:
  /// **'Building {building} deleted successfully'**
  String buildingDeleted(Object building);

  /// Error message when building deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete building: {error}'**
  String deleteFailed(Object error);

  /// No description provided for @noBuildings.
  ///
  /// In en, this message translates to:
  /// **'No buildings'**
  String get noBuildings;

  /// No description provided for @noBuildingsSearch.
  ///
  /// In en, this message translates to:
  /// **'No buildings found'**
  String get noBuildingsSearch;

  /// No description provided for @addNewBuildingHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new building'**
  String get addNewBuildingHint;

  /// No description provided for @tryDifferentKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword'**
  String get tryDifferentKeyword;

  /// No description provided for @oldDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Old Data'**
  String get oldDataTitle;

  /// No description provided for @searchReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Search receipts...'**
  String get searchReceiptHint;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @overdueStatus.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueStatus;

  /// No description provided for @viewDetail.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetail;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deleteOption.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteOption;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptTitle;

  /// No description provided for @noReceipts.
  ///
  /// In en, this message translates to:
  /// **'No receipts'**
  String get noReceipts;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy, security, change password'**
  String get privacySecurity;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @plansPayments.
  ///
  /// In en, this message translates to:
  /// **'Plans, payment methods'**
  String get plansPayments;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @faqContact.
  ///
  /// In en, this message translates to:
  /// **'FAQs, contact us'**
  String get faqContact;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.2.3'**
  String get version;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @premiumMember.
  ///
  /// In en, this message translates to:
  /// **'Premium Member'**
  String get premiumMember;

  /// No description provided for @tenantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get tenantsTitle;

  /// No description provided for @searchTenantHint.
  ///
  /// In en, this message translates to:
  /// **'Search tenant...'**
  String get searchTenantHint;

  /// Success message after adding a tenant
  ///
  /// In en, this message translates to:
  /// **'Tenant {tenant} added successfully'**
  String tenantAdded(Object tenant);

  /// No description provided for @tenantAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Error adding tenant'**
  String get tenantAddFailed;

  /// Success message after updating a tenant
  ///
  /// In en, this message translates to:
  /// **'Tenant {tenant} updated successfully'**
  String tenantUpdated(Object tenant);

  /// No description provided for @tenantUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Error updating tenant'**
  String get tenantUpdateFailed;

  /// Success message after deleting a tenant
  ///
  /// In en, this message translates to:
  /// **'Tenant {tenant} deleted'**
  String tenantDeleted(Object tenant);

  /// No description provided for @tenantDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Error deleting tenant'**
  String get tenantDeleteFailed;

  /// Message when a tenant's room is changed
  ///
  /// In en, this message translates to:
  /// **'Room for {tenant} changed to {room}'**
  String roomChanged(Object tenant, Object room);

  /// No description provided for @roomChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Error undoing room change'**
  String get roomChangeFailed;

  /// No description provided for @retryLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Retry Loading Profile'**
  String get retryLoadingProfile;

  /// No description provided for @noLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not logged in.'**
  String get noLoggedIn;

  /// No description provided for @goToOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Go to Onboarding'**
  String get goToOnboarding;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @noEmailProvided.
  ///
  /// In en, this message translates to:
  /// **'No Email Provided'**
  String get noEmailProvided;

  /// No description provided for @editProfileTapped.
  ///
  /// In en, this message translates to:
  /// **'Edit profile tapped'**
  String get editProfileTapped;

  /// No description provided for @signOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully!'**
  String get signOutSuccess;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out'**
  String get signOutFailed;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordHint;

  /// No description provided for @manageBuildings.
  ///
  /// In en, this message translates to:
  /// **'Manage Buildings & Rooms'**
  String get manageBuildings;

  /// No description provided for @manageBuildingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your buildings, rooms, and services easily with our intuitive interface.'**
  String get manageBuildingsDesc;

  /// No description provided for @tenantManagement.
  ///
  /// In en, this message translates to:
  /// **'Tenant Management'**
  String get tenantManagement;

  /// No description provided for @tenantManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Assign tenants and automate receipts with just a few taps.'**
  String get tenantManagementDesc;

  /// No description provided for @paymentTracking.
  ///
  /// In en, this message translates to:
  /// **'Payment Tracking'**
  String get paymentTracking;

  /// No description provided for @paymentTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Track payments easily - Pending, Paid, and Overdue status at a glance.'**
  String get paymentTrackingDesc;

  /// No description provided for @automationTools.
  ///
  /// In en, this message translates to:
  /// **'Automation Tools'**
  String get automationTools;

  /// No description provided for @automationToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Automate work with Telegram bot reminders and utilities input.'**
  String get automationToolsDesc;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'km': return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
