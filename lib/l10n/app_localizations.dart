import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';
import 'app_localizations_zh.dart';

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
    Locale('km'),
    Locale('zh')
  ];

  /// No description provided for @receiptTab.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
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

  /// Label for a single report
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInPrompt;

  /// No description provided for @tenantInformation.
  ///
  /// In en, this message translates to:
  /// **'Tenant Information'**
  String get tenantInformation;

  /// No description provided for @deleteTenantConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete tenant {tenant}?'**
  String deleteTenantConfirmMsg(String tenant);

  /// Label for multiple reports
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Button text to add a new report
  ///
  /// In en, this message translates to:
  /// **'Add Report'**
  String get addReport;

  /// Button text to edit an existing report
  ///
  /// In en, this message translates to:
  /// **'Edit Report'**
  String get editReport;

  /// Button text to delete a report
  ///
  /// In en, this message translates to:
  /// **'Delete Report'**
  String get deleteReport;

  /// Message shown when there are no reports
  ///
  /// In en, this message translates to:
  /// **'No Reports'**
  String get noReports;

  /// Success message after adding a report
  ///
  /// In en, this message translates to:
  /// **'Report added successfully'**
  String get reportAddedSuccess;

  /// Success message after updating a report
  ///
  /// In en, this message translates to:
  /// **'Report updated successfully'**
  String get reportUpdatedSuccess;

  /// Success message after deleting a report
  ///
  /// In en, this message translates to:
  /// **'Report deleted successfully'**
  String get reportDeletedSuccess;

  /// Confirmation message before deleting a report
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this report?'**
  String get deleteReportConfirm;

  /// Validation message to select a tenant
  ///
  /// In en, this message translates to:
  /// **'Please select a tenant'**
  String get selectTenant;

  /// Label for problem description field
  ///
  /// In en, this message translates to:
  /// **'Problem Description'**
  String get problemDescription;

  /// Validation message for problem description field
  ///
  /// In en, this message translates to:
  /// **'Please enter a problem description'**
  String get enterProblemDescription;

  /// Text shown when report has no tenant assigned
  ///
  /// In en, this message translates to:
  /// **'No Tenant'**
  String get noTenant;

  /// Label indicating a field is optional
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// Report status: Pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reportStatusPending;

  /// Report status: In Progress
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get reportStatusInProgress;

  /// Report status: Resolved
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get reportStatusResolved;

  /// Report status: Closed
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get reportStatusClosed;

  /// Report priority: Low
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get reportPriorityLow;

  /// Report priority: Medium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get reportPriorityMedium;

  /// Report priority: High
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get reportPriorityHigh;

  /// Report language: English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get reportLanguageEnglish;

  /// Report language: Khmer
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get reportLanguageKhmer;

  /// No description provided for @editReceipt.
  ///
  /// In en, this message translates to:
  /// **'Edit Receipt'**
  String get editReceipt;

  /// No description provided for @createNewReceipt.
  ///
  /// In en, this message translates to:
  /// **'Create New Receipt'**
  String get createNewReceipt;

  /// No description provided for @noBuildingsPrompt.
  ///
  /// In en, this message translates to:
  /// **'No buildings. Please create a building before creating a receipt.'**
  String get noBuildingsPrompt;

  /// No description provided for @createNewBuilding.
  ///
  /// In en, this message translates to:
  /// **'Create New Building'**
  String get createNewBuilding;

  /// No description provided for @selectBuilding.
  ///
  /// In en, this message translates to:
  /// **'Select Building'**
  String get selectBuilding;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @selectRoom.
  ///
  /// In en, this message translates to:
  /// **'Select Room'**
  String get selectRoom;

  /// No description provided for @noOccupiedRooms.
  ///
  /// In en, this message translates to:
  /// **'No occupied rooms'**
  String get noOccupiedRooms;

  /// No description provided for @pleaseSelectRoom.
  ///
  /// In en, this message translates to:
  /// **'Please select room'**
  String get pleaseSelectRoom;

  /// No description provided for @previousMonthUsage.
  ///
  /// In en, this message translates to:
  /// **'Previous Month Usage'**
  String get previousMonthUsage;

  /// No description provided for @currentMonthUsage.
  ///
  /// In en, this message translates to:
  /// **'Current Month Usage'**
  String get currentMonthUsage;

  /// No description provided for @waterM3.
  ///
  /// In en, this message translates to:
  /// **'Water (m³)'**
  String get waterM3;

  /// No description provided for @electricityKWh.
  ///
  /// In en, this message translates to:
  /// **'Electricity (kWh)'**
  String get electricityKWh;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @selectBuildingFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a building first'**
  String get selectBuildingFirst;

  /// No description provided for @noServicesForBuilding.
  ///
  /// In en, this message translates to:
  /// **'No services available for this building'**
  String get noServicesForBuilding;

  /// No description provided for @errorLoadingServices.
  ///
  /// In en, this message translates to:
  /// **'Error loading services'**
  String get errorLoadingServices;

  /// No description provided for @receiptDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt Details'**
  String get receiptDetailTitle;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt'**
  String get shareReceipt;

  /// No description provided for @receiptForRoom.
  ///
  /// In en, this message translates to:
  /// **'Receipt for Room {room}'**
  String receiptForRoom(Object room);

  /// No description provided for @tenantInfo.
  ///
  /// In en, this message translates to:
  /// **'Tenant Information'**
  String get tenantInfo;

  /// No description provided for @tenantName.
  ///
  /// In en, this message translates to:
  /// **'Tenant: {name}'**
  String tenantName(Object name);

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @utilityUsage.
  ///
  /// In en, this message translates to:
  /// **'Utility Usage'**
  String get utilityUsage;

  /// No description provided for @waterPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Water (Previous Month)'**
  String get waterPreviousMonth;

  /// No description provided for @waterCurrentMonth.
  ///
  /// In en, this message translates to:
  /// **'Water (Current Month)'**
  String get waterCurrentMonth;

  /// No description provided for @electricPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Electricity (Previous Month)'**
  String get electricPreviousMonth;

  /// No description provided for @electricCurrentMonth.
  ///
  /// In en, this message translates to:
  /// **'Electricity (Current Month)'**
  String get electricCurrentMonth;

  /// No description provided for @paymentBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Payment Breakdown'**
  String get paymentBreakdown;

  /// No description provided for @waterUsage.
  ///
  /// In en, this message translates to:
  /// **'Water Usage'**
  String get waterUsage;

  /// No description provided for @totalWaterPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Water Price'**
  String get totalWaterPrice;

  /// No description provided for @electricUsage.
  ///
  /// In en, this message translates to:
  /// **'Electricity Usage'**
  String get electricUsage;

  /// No description provided for @totalElectricPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Electricity Price'**
  String get totalElectricPrice;

  /// No description provided for @additionalServices.
  ///
  /// In en, this message translates to:
  /// **'Additional Services'**
  String get additionalServices;

  /// No description provided for @totalServicePrice.
  ///
  /// In en, this message translates to:
  /// **'Total Service Price'**
  String get totalServicePrice;

  /// No description provided for @roomRent.
  ///
  /// In en, this message translates to:
  /// **'Room Rent'**
  String get roomRent;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @rented.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get rented;

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// No description provided for @createNewService.
  ///
  /// In en, this message translates to:
  /// **'Create New Service'**
  String get createNewService;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @serviceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter service name'**
  String get serviceNameRequired;

  /// No description provided for @servicePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Price'**
  String get servicePriceLabel;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @currencyServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currency service unavailable – showing base USD rate'**
  String get currencyServiceUnavailable;

  /// No description provided for @thankYouForUsingOurService.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using or service!'**
  String get thankYouForUsingOurService;

  /// No description provided for @currencyConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert currency'**
  String get currencyConversionFailed;

  /// No description provided for @shareReceiptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share receipt'**
  String get shareReceiptFailed;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @errorLoadingBuildings.
  ///
  /// In en, this message translates to:
  /// **'Error loading buildings'**
  String get errorLoadingBuildings;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

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

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @overdueStatus.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueStatus;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'status'**
  String get status;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @unknownRoom.
  ///
  /// In en, this message translates to:
  /// **'Unknown Room'**
  String get unknownRoom;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @changedTo.
  ///
  /// In en, this message translates to:
  /// **'changed to'**
  String get changedTo;

  /// No description provided for @noTenants.
  ///
  /// In en, this message translates to:
  /// **'No tenants'**
  String get noTenants;

  /// No description provided for @tapToAddNewTenant.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new tenant'**
  String get tapToAddNewTenant;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @roomInformation.
  ///
  /// In en, this message translates to:
  /// **'Room Information'**
  String get roomInformation;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @rentalPrice.
  ///
  /// In en, this message translates to:
  /// **'Rental Price'**
  String get rentalPrice;

  /// No description provided for @editTenant.
  ///
  /// In en, this message translates to:
  /// **'Edit Tenant'**
  String get editTenant;

  /// No description provided for @createNewTenant.
  ///
  /// In en, this message translates to:
  /// **'Create New Tenant'**
  String get createNewTenant;

  /// No description provided for @pleaseEnterTenantName.
  ///
  /// In en, this message translates to:
  /// **'Please enter tenant name'**
  String get pleaseEnterTenantName;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @updateTenant.
  ///
  /// In en, this message translates to:
  /// **'Update Tenant'**
  String get updateTenant;

  /// No description provided for @createTenant.
  ///
  /// In en, this message translates to:
  /// **'Create Tenant'**
  String get createTenant;

  /// No description provided for @errorLoadingRooms.
  ///
  /// In en, this message translates to:
  /// **'Error loading rooms'**
  String get errorLoadingRooms;

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

  /// No description provided for @buildings.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get buildings;

  /// No description provided for @searchBuildings.
  ///
  /// In en, this message translates to:
  /// **'Search buildings...'**
  String get searchBuildings;

  /// No description provided for @noBuildingsFound.
  ///
  /// In en, this message translates to:
  /// **'No buildings found'**
  String get noBuildingsFound;

  /// No description provided for @noBuildingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No buildings available'**
  String get noBuildingsAvailable;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try searching with different keywords'**
  String get tryDifferentKeywords;

  /// No description provided for @tapPlusToAddBuilding.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new building'**
  String get tapPlusToAddBuilding;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @deleteBuildingConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete building \"{name}\"?'**
  String deleteBuildingConfirmMsg(Object name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @buildingDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Building \"{name}\" deleted successfully'**
  String buildingDeletedSuccess(Object name);

  /// Success message after deleting a building
  ///
  /// In en, this message translates to:
  /// **'Building {building} deleted successfully'**
  String buildingDeleted(String building, Object name);

  /// No description provided for @buildingDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete building: {error}'**
  String buildingDeleteFailed(Object error);

  /// No description provided for @rentPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent Price'**
  String get rentPriceLabel;

  /// No description provided for @electricPricePerKwh.
  ///
  /// In en, this message translates to:
  /// **'Electricity Price (1 kWh)'**
  String get electricPricePerKwh;

  /// No description provided for @waterPricePerCubicMeter.
  ///
  /// In en, this message translates to:
  /// **'Water Price (1 m³)'**
  String get waterPricePerCubicMeter;

  /// No description provided for @rentPricePerMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent Price'**
  String get rentPricePerMonthLabel;

  /// No description provided for @rentPricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent Price'**
  String rentPricePerMonth(Object price);

  /// No description provided for @passKey.
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String passKey(Object key);

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// No description provided for @electricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get electricity;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @ofTotal.
  ///
  /// In en, this message translates to:
  /// **'/ {total}'**
  String ofTotal(Object total);

  /// Confirmation message for deleting a building
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete building {building}?'**
  String deleteConfirmMsg(String building);

  /// Error message when building deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete building: {error}'**
  String deleteFailed(String error);

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

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @changeRoom.
  ///
  /// In en, this message translates to:
  /// **'Change Room'**
  String get changeRoom;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @roomNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String roomNumberLabel(Object number);

  /// No description provided for @tenantNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tenantNameLabel;

  /// No description provided for @roomStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String roomStatus(Object status);

  /// No description provided for @rentPrice.
  ///
  /// In en, this message translates to:
  /// **'Rent Price: {price}\$'**
  String rentPrice(Object price);

  /// No description provided for @noRoom.
  ///
  /// In en, this message translates to:
  /// **'No Room'**
  String get noRoom;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @accountSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy, security, change password'**
  String get accountSettingsSubtitle;

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

  /// No description provided for @subscriptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plans, payment methods'**
  String get subscriptionsSubtitle;

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

  /// No description provided for @khmer.
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get khmer;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @helpAndSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs, contact us'**
  String get helpAndSupportSubtitle;

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

  /// No description provided for @receiptDeleted.
  ///
  /// In en, this message translates to:
  /// **'Receipt deleted successfully'**
  String get receiptDeleted;

  /// No description provided for @receiptRestored.
  ///
  /// In en, this message translates to:
  /// **'Receipt restored successfully'**
  String get receiptRestored;

  /// No description provided for @noReceiptsForMonth.
  ///
  /// In en, this message translates to:
  /// **'No receipts for {month}'**
  String noReceiptsForMonth(String month);

  /// No description provided for @noReceiptsForBuilding.
  ///
  /// In en, this message translates to:
  /// **'No receipts for this building'**
  String get noReceiptsForBuilding;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results for \"{query}\"'**
  String noSearchResults(String query);

  /// No description provided for @receiptStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Receipt status changed to {status}'**
  String receiptStatusChanged(String status);

  /// The application version number
  ///
  /// In en, this message translates to:
  /// **'Version {versionNumber}'**
  String version(String versionNumber);

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

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

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
  String tenantAdded(String tenant);

  /// No description provided for @tenantAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Error adding tenant'**
  String get tenantAddFailed;

  /// Success message after updating a tenant
  ///
  /// In en, this message translates to:
  /// **'Tenant {tenant} updated successfully'**
  String tenantUpdated(String tenant);

  /// No description provided for @tenantUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Error updating tenant'**
  String get tenantUpdateFailed;

  /// Success message after deleting a tenant
  ///
  /// In en, this message translates to:
  /// **'Tenant {tenant} deleted'**
  String tenantDeleted(String tenant);

  /// No description provided for @tenantDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Error deleting tenant'**
  String get tenantDeleteFailed;

  /// Message when a tenant's room is changed
  ///
  /// In en, this message translates to:
  /// **'Room for {tenant} changed to {room}'**
  String roomChanged(String tenant, String room);

  /// No description provided for @priceValue.
  ///
  /// In en, this message translates to:
  /// **'Price: {price}\$'**
  String priceValue(Object price);

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @servicePrice.
  ///
  /// In en, this message translates to:
  /// **'{price}\$'**
  String servicePrice(Object price);

  /// No description provided for @addRoom.
  ///
  /// In en, this message translates to:
  /// **'Add Room'**
  String get addRoom;

  /// No description provided for @noRooms.
  ///
  /// In en, this message translates to:
  /// **'No Rooms'**
  String get noRooms;

  /// No description provided for @noServices.
  ///
  /// In en, this message translates to:
  /// **'No Services'**
  String get noServices;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @roomAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Room \"{number}\" added successfully'**
  String roomAddedSuccess(Object number);

  /// No description provided for @roomUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Room \"{number}\" updated successfully'**
  String roomUpdatedSuccess(Object number);

  /// No description provided for @roomDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Room \"{number}\" deleted successfully'**
  String roomDeletedSuccess(Object number);

  /// No description provided for @serviceAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service \"{name}\" added successfully'**
  String serviceAddedSuccess(Object name);

  /// No description provided for @serviceUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service \"{name}\" updated successfully'**
  String serviceUpdatedSuccess(Object name);

  /// No description provided for @serviceDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service \"{name}\" deleted successfully'**
  String serviceDeletedSuccess(Object name);

  /// No description provided for @buildingUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Building \"{name}\" updated successfully'**
  String buildingUpdatedSuccess(Object name);

  /// No description provided for @deleteBuilding.
  ///
  /// In en, this message translates to:
  /// **'Delete Building'**
  String get deleteBuilding;

  /// No description provided for @deleteBuildingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete building \"{name}\"?'**
  String deleteBuildingConfirm(Object name);

  /// No description provided for @deleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Delete Room'**
  String get deleteRoom;

  /// No description provided for @deleteRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete room \"{number}\"?'**
  String deleteRoomConfirm(Object number);

  /// No description provided for @deleteService.
  ///
  /// In en, this message translates to:
  /// **'Delete Service'**
  String get deleteService;

  /// No description provided for @deleteServiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete service \"{name}\"?'**
  String deleteServiceConfirm(Object name);

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @addNewBuilding.
  ///
  /// In en, this message translates to:
  /// **'Add New Building'**
  String get addNewBuilding;

  /// No description provided for @editBuilding.
  ///
  /// In en, this message translates to:
  /// **'Edit Building'**
  String get editBuilding;

  /// No description provided for @buildingName.
  ///
  /// In en, this message translates to:
  /// **'Building Name'**
  String get buildingName;

  /// No description provided for @buildingNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter building name.'**
  String get buildingNameRequired;

  /// No description provided for @roomCount.
  ///
  /// In en, this message translates to:
  /// **'Number of Rooms'**
  String get roomCount;

  /// No description provided for @currentRoomCount.
  ///
  /// In en, this message translates to:
  /// **'Current Number of Rooms'**
  String get currentRoomCount;

  /// No description provided for @roomCountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter number of rooms.'**
  String get roomCountRequired;

  /// No description provided for @roomCountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number of rooms.'**
  String get roomCountInvalid;

  /// No description provided for @roomCountEditNote.
  ///
  /// In en, this message translates to:
  /// **'Room count cannot be changed. Manage rooms individually.'**
  String get roomCountEditNote;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saveBuilding.
  ///
  /// In en, this message translates to:
  /// **'Save Building'**
  String get saveBuilding;

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

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile.'**
  String get failedToLoadProfile;

  /// No description provided for @noLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not logged in.'**
  String get noLoggedIn;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not logged in.'**
  String get notLoggedIn;

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

  /// No description provided for @advancedAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analysis'**
  String get advancedAnalysis;

  /// No description provided for @financial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get financial;

  /// No description provided for @errorLoadingCurrencyRate.
  ///
  /// In en, this message translates to:
  /// **'Error loading currency rate'**
  String get errorLoadingCurrencyRate;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @orSignOut.
  ///
  /// In en, this message translates to:
  /// **'Or Sign Out'**
  String get orSignOut;

  /// No description provided for @pleaseEnterValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get pleaseEnterValue;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @receiptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{{count} receipt}other{{count} receipts}}'**
  String receiptsCount(num count);

  /// Success message after a receipt is deleted
  ///
  /// In en, this message translates to:
  /// **'Receipt for room {room} deleted'**
  String receiptDeletedRoom(String room);

  /// Error message when a receipt cannot be found in the provider
  ///
  /// In en, this message translates to:
  /// **'Receipt not found'**
  String get receiptNotFound;

  /// Tooltip for the add-receipt button
  ///
  /// In en, this message translates to:
  /// **'Add Receipt'**
  String get addReceipt;

  /// Confirmation dialog when deleting a receipt
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the receipt for room {room}?'**
  String deleteReceiptConfirmMsg(String room);

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @collectionRate.
  ///
  /// In en, this message translates to:
  /// **'Collection Rate: {rate}%'**
  String collectionRate(String rate);

  /// No description provided for @tapToSeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to see details'**
  String get tapToSeeDetails;

  /// No description provided for @utilityAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Utility Analysis'**
  String get utilityAnalysis;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year: '**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month:'**
  String get month;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get nextMonth;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @emailValidationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailValidationInvalid;

  /// No description provided for @passwordValidationLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordValidationLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get chooseLanguageSubtitle;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'km', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'km': return AppLocalizationsKm();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
