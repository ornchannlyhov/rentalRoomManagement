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
  String get historyTab => 'History';

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
  String get report => 'Report';

  @override
  String get signInPrompt => 'Sign in to your account';

  @override
  String get tenantInformation => 'Tenant Information';

  @override
  String deleteTenantConfirmMsg(String tenant) {
    return 'Are you sure you want to delete tenant $tenant?';
  }

  @override
  String get reports => 'Reports';

  @override
  String get addReport => 'Add Report';

  @override
  String get editReport => 'Edit Report';

  @override
  String get deleteReport => 'Delete Report';

  @override
  String get noReports => 'No Reports';

  @override
  String get reportAddedSuccess => 'Report added successfully';

  @override
  String get reportUpdatedSuccess => 'Report updated successfully';

  @override
  String get reportDeletedSuccess => 'Report deleted successfully';

  @override
  String get deleteReportConfirm => 'Are you sure you want to delete this report?';

  @override
  String get selectTenant => 'Please select a tenant';

  @override
  String get problemDescription => 'Problem Description';

  @override
  String get enterProblemDescription => 'Please enter a problem description';

  @override
  String get noTenant => 'No Tenant';

  @override
  String get optional => 'Optional';

  @override
  String get reportStatusPending => 'Pending';

  @override
  String get reportStatusInProgress => 'In Progress';

  @override
  String get reportStatusResolved => 'Resolved';

  @override
  String get reportStatusClosed => 'Closed';

  @override
  String get reportPriorityLow => 'Low';

  @override
  String get reportPriorityMedium => 'Medium';

  @override
  String get reportPriorityHigh => 'High';

  @override
  String get reportLanguageEnglish => 'English';

  @override
  String get reportLanguageKhmer => 'Khmer';

  @override
  String get editReceipt => 'Edit Receipt';

  @override
  String get createNewReceipt => 'Create New Receipt';

  @override
  String get noBuildingsPrompt => 'No buildings. Please create a building before creating a receipt.';

  @override
  String get createNewBuilding => 'Create New Building';

  @override
  String get selectBuilding => 'Select Building';

  @override
  String get all => 'All';

  @override
  String get selectRoom => 'Select Room';

  @override
  String get noOccupiedRooms => 'No occupied rooms';

  @override
  String get pleaseSelectRoom => 'Please select room';

  @override
  String get previousMonthUsage => 'Previous Month Usage';

  @override
  String get currentMonthUsage => 'Current Month Usage';

  @override
  String get waterM3 => 'Water (m³)';

  @override
  String get electricityKWh => 'Electricity (kWh)';

  @override
  String get services => 'Services';

  @override
  String get selectBuildingFirst => 'Please select a building first';

  @override
  String get noServicesForBuilding => 'No services available for this building';

  @override
  String get errorLoadingServices => 'Error loading services';

  @override
  String get receiptDetailTitle => 'Receipt Details';

  @override
  String get shareReceipt => 'Share Receipt';

  @override
  String receiptForRoom(Object room) {
    return 'Receipt for Room $room';
  }

  @override
  String get tenantInfo => 'Tenant Information';

  @override
  String tenantName(Object name) {
    return 'Tenant: $name';
  }

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get utilityUsage => 'Utility Usage';

  @override
  String get waterPreviousMonth => 'Water (Previous Month)';

  @override
  String get waterCurrentMonth => 'Water (Current Month)';

  @override
  String get electricPreviousMonth => 'Electricity (Previous Month)';

  @override
  String get electricCurrentMonth => 'Electricity (Current Month)';

  @override
  String get paymentBreakdown => 'Payment Breakdown';

  @override
  String get waterUsage => 'Water Usage';

  @override
  String get totalWaterPrice => 'Total Water Price';

  @override
  String get electricUsage => 'Electricity Usage';

  @override
  String get totalElectricPrice => 'Total Electricity Price';

  @override
  String get additionalServices => 'Additional Services';

  @override
  String get totalServicePrice => 'Total Service Price';

  @override
  String get roomRent => 'Room Rent';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get available => 'Available';

  @override
  String get rented => 'Rented';

  @override
  String get editService => 'Edit Service';

  @override
  String get createNewService => 'Create New Service';

  @override
  String get serviceName => 'Service Name';

  @override
  String get serviceNameRequired => 'Please enter service name';

  @override
  String get servicePriceLabel => 'Service Price';

  @override
  String get addService => 'Add Service';

  @override
  String get currencyServiceUnavailable => 'Currency service unavailable – showing base USD rate';

  @override
  String get thankYouForUsingOurService => 'Thank you for using or service!';

  @override
  String get currencyConversionFailed => 'Failed to convert currency';

  @override
  String get shareReceiptFailed => 'Failed to share receipt';

  @override
  String get save => 'Save';

  @override
  String get errorLoadingBuildings => 'Error loading buildings';

  @override
  String get unknown => 'Unknown';

  @override
  String get menu => 'Menu';

  @override
  String get dueDate => 'Due Date';

  @override
  String get paidStatus => 'Paid';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get notes => 'Notes';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get overdueStatus => 'Overdue';

  @override
  String get status => 'status';

  @override
  String get delete => 'Delete';

  @override
  String get unknownRoom => 'Unknown Room';

  @override
  String get room => 'Room';

  @override
  String get changedTo => 'changed to';

  @override
  String get noTenants => 'No tenants';

  @override
  String get tapToAddNewTenant => 'Tap + to add a new tenant';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get male => 'Male';

  @override
  String get changeStatus => 'Change Status';

  @override
  String get filterByStatus => 'Filter by Status';

  @override
  String get allReports => 'All Reports';

  @override
  String get unknownTenant => 'Unknown Tenant';

  @override
  String reportStatusUpdated(String status) {
    return 'Report status updated to $status';
  }

  @override
  String get reportStatusUpdateFailed => 'Failed to update report status';

  @override
  String noFilteredReports(String status) {
    return 'No $status Reports';
  }

  @override
  String get noFilteredReportsSubtitle => 'No reports match the selected status filter';

  @override
  String get clearFilter => 'Clear Filter';

  @override
  String deleteReportConfirmFrom(String tenant) {
    return 'Are you sure you want to delete this report from $tenant?';
  }

  @override
  String get reportPriorityUrgent => 'Urgent';

  @override
  String deleteBuildingWarning(String name) {
    return 'Are you sure you want to delete $name? This will also delete all rooms, services, and associated data.';
  }

  @override
  String get noRoomsSubtitle => 'Pull to refresh or add a new room';

  @override
  String get noServicesSubtitle => 'Pull to refresh or add a new service';

  @override
  String get noReportsSubtitle => 'Pull to refresh';

  @override
  String get refresh => 'refresh';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get roomInformation => 'Room Information';

  @override
  String get notAvailable => 'N/A';

  @override
  String get rentalPrice => 'Rental Price';

  @override
  String get editTenant => 'Edit Tenant';

  @override
  String get createNewTenant => 'Create New Tenant';

  @override
  String get pleaseEnterTenantName => 'Please enter tenant name';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter phone number';

  @override
  String get invalidPhoneNumber => 'Invalid phone number';

  @override
  String get searchCountry => 'Search country';

  @override
  String get gender => 'Gender';

  @override
  String get updateTenant => 'Update Tenant';

  @override
  String get createTenant => 'Create Tenant';

  @override
  String get errorLoadingRooms => 'Error loading rooms';

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
  String get buildings => 'Buildings';

  @override
  String get searchBuildings => 'Search buildings...';

  @override
  String get noBuildingsFound => 'No buildings found';

  @override
  String get noBuildingsAvailable => 'No buildings available';

  @override
  String get tryDifferentKeywords => 'Try searching with different keywords';

  @override
  String get tapPlusToAddBuilding => 'Tap + to add a new building';

  @override
  String get loading => 'Loading...';

  @override
  String deleteBuildingConfirmMsg(Object name) {
    return 'Are you sure you want to delete building \"$name\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String buildingDeletedSuccess(Object name) {
    return 'Building \"$name\" deleted successfully';
  }

  @override
  String buildingDeleted(String building, Object name) {
    return 'Building $building deleted successfully';
  }

  @override
  String buildingDeleteFailed(Object error) {
    return 'Failed to delete building: $error';
  }

  @override
  String get rentPriceLabel => 'Monthly Rent Price';

  @override
  String get electricPricePerKwh => 'Electricity Price (1 kWh)';

  @override
  String get waterPricePerCubicMeter => 'Water Price (1 m³)';

  @override
  String get rentPricePerMonthLabel => 'Monthly Rent Price';

  @override
  String rentPricePerMonth(Object price) {
    return 'Monthly Rent Price';
  }

  @override
  String passKey(Object key) {
    return 'Key: $key';
  }

  @override
  String get perMonth => '/ month';

  @override
  String get electricity => 'Electricity';

  @override
  String get water => 'Water';

  @override
  String get viewDetails => 'View Details';

  @override
  String get edit => 'Edit';

  @override
  String ofTotal(Object total) {
    return '/ $total';
  }

  @override
  String deleteConfirmMsg(String building) {
    return 'Are you sure you want to delete building $building?';
  }

  @override
  String deleteFailed(String error) {
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
  String get viewDetail => 'View Details';

  @override
  String get share => 'Share';

  @override
  String get deleteOption => 'Delete';

  @override
  String get undo => 'Undo';

  @override
  String get receiptTitle => 'Receipts';

  @override
  String get noReceipts => 'No receipts';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settings => 'Settings';

  @override
  String get changeRoom => 'Change Room';

  @override
  String get building => 'Building';

  @override
  String roomNumberLabel(Object number) {
    return 'Room $number';
  }

  @override
  String get tenantNameLabel => 'Name';

  @override
  String roomStatus(Object status) {
    return 'Status: $status';
  }

  @override
  String rentPrice(Object price) {
    return 'Rent Price: $price\$';
  }

  @override
  String get noRoom => 'No Room';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get accountSettingsSubtitle => 'Privacy, security, change password';

  @override
  String get privacySecurity => 'Privacy, security, change password';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get subscriptionsSubtitle => 'Plans, payment methods';

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
  String get khmer => 'Khmer';

  @override
  String get english => 'English';

  @override
  String get chinese => 'Chinese';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get helpAndSupportSubtitle => 'FAQs, contact us';

  @override
  String get faqContact => 'FAQs, contact us';

  @override
  String get about => 'About';

  @override
  String get receiptDeleted => 'Receipt deleted successfully';

  @override
  String get receiptRestored => 'Receipt restored successfully';

  @override
  String noReceiptsForMonth(String month) {
    return 'No receipts for $month';
  }

  @override
  String get noReceiptsForBuilding => 'No receipts for this building';

  @override
  String noSearchResults(String query) {
    return 'No search results for \"$query\"';
  }

  @override
  String receiptStatusChanged(String status) {
    return 'Receipt status changed to $status';
  }

  @override
  String version(String versionNumber) {
    return 'Version $versionNumber';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get premiumMember => 'Premium Member';

  @override
  String get tenantsTitle => 'Tenants';

  @override
  String get searchTenantHint => 'Search tenant...';

  @override
  String tenantAdded(String tenant) {
    return 'Tenant $tenant added successfully';
  }

  @override
  String get tenantAddFailed => 'Error adding tenant';

  @override
  String tenantUpdated(String tenant) {
    return 'Tenant $tenant updated successfully';
  }

  @override
  String get tenantUpdateFailed => 'Error updating tenant';

  @override
  String tenantDeleted(String tenant) {
    return 'Tenant $tenant deleted';
  }

  @override
  String get tenantDeleteFailed => 'Error deleting tenant';

  @override
  String roomChanged(String tenant, String room) {
    return 'Room for $tenant changed to $room';
  }

  @override
  String priceValue(Object price) {
    return 'Price: $price\$';
  }

  @override
  String get rooms => 'Rooms';

  @override
  String servicePrice(Object price) {
    return '$price\$';
  }

  @override
  String get addRoom => 'Add Room';

  @override
  String get noRooms => 'No Rooms';

  @override
  String get noServices => 'No Services';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String roomAddedSuccess(Object number) {
    return 'Room \"$number\" added successfully';
  }

  @override
  String roomUpdatedSuccess(Object number) {
    return 'Room \"$number\" updated successfully';
  }

  @override
  String roomDeletedSuccess(Object number) {
    return 'Room \"$number\" deleted successfully';
  }

  @override
  String serviceAddedSuccess(Object name) {
    return 'Service \"$name\" added successfully';
  }

  @override
  String serviceUpdatedSuccess(Object name) {
    return 'Service \"$name\" updated successfully';
  }

  @override
  String serviceDeletedSuccess(Object name) {
    return 'Service \"$name\" deleted successfully';
  }

  @override
  String buildingUpdatedSuccess(Object name) {
    return 'Building \"$name\" updated successfully';
  }

  @override
  String get deleteBuilding => 'Delete Building';

  @override
  String deleteBuildingConfirm(Object name) {
    return 'Do you want to delete building \"$name\"?';
  }

  @override
  String get deleteRoom => 'Delete Room';

  @override
  String deleteRoomConfirm(Object number) {
    return 'Do you want to delete room \"$number\"?';
  }

  @override
  String get deleteService => 'Delete Service';

  @override
  String deleteServiceConfirm(Object name) {
    return 'Do you want to delete service \"$name\"?';
  }

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get addNewBuilding => 'Add New Building';

  @override
  String get editBuilding => 'Edit Building';

  @override
  String get buildingName => 'Building Name';

  @override
  String get buildingNameRequired => 'Please enter building name.';

  @override
  String get roomCount => 'Number of Rooms';

  @override
  String get currentRoomCount => 'Current Number of Rooms';

  @override
  String get roomCountRequired => 'Please enter number of rooms.';

  @override
  String get roomCountInvalid => 'Please enter a valid number of rooms.';

  @override
  String get roomCountEditNote => 'Room count cannot be changed. Manage rooms individually.';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get saveBuilding => 'Save Building';

  @override
  String get roomChangeFailed => 'Error undoing room change';

  @override
  String get retryLoadingProfile => 'Retry Loading Profile';

  @override
  String get failedToLoadProfile => 'Failed to load profile.';

  @override
  String get noLoggedIn => 'You are not logged in.';

  @override
  String get notLoggedIn => 'You are not logged in.';

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

  @override
  String get advancedAnalysis => 'Advanced Analysis';

  @override
  String get financial => 'Financial';

  @override
  String get errorLoadingCurrencyRate => 'Error loading currency rate';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get orSignOut => 'Or Sign Out';

  @override
  String get pleaseEnterValue => 'Please enter a value';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String receiptsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count receipts',
      one: '$count receipt',
    );
    return '$_temp0';
  }

  @override
  String receiptDeletedRoom(String room) {
    return 'Receipt for room $room deleted';
  }

  @override
  String get receiptNotFound => 'Receipt not found';

  @override
  String get addReceipt => 'Add Receipt';

  @override
  String deleteReceiptConfirmMsg(String room) {
    return 'Are you sure you want to delete the receipt for room $room?';
  }

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get paid => 'Paid';

  @override
  String get remaining => 'Remaining';

  @override
  String collectionRate(String rate) {
    return 'Collection Rate: $rate%';
  }

  @override
  String get tapToSeeDetails => 'Tap to see details';

  @override
  String get utilityAnalysis => 'Utility Analysis';

  @override
  String get pending => 'Pending';

  @override
  String get overdue => 'Overdue';

  @override
  String get selectMonth => 'Select Month';

  @override
  String get year => 'Year: ';

  @override
  String get month => 'Month:';

  @override
  String get previousMonth => 'Previous Month';

  @override
  String get nextMonth => 'Next Month';

  @override
  String get service => 'Service';

  @override
  String get emailValidationInvalid => 'Please enter a valid email';

  @override
  String get passwordValidationLength => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get chooseLanguageTitle => 'Choose Your Language';

  @override
  String get chooseLanguageSubtitle => 'Select your preferred language';

  @override
  String get continueButton => 'Continue';

  @override
  String get nextButton => 'Next';
}
