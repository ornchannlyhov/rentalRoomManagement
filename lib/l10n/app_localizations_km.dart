// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get receiptTab => 'វិក្កយបត្រ';

  @override
  String get historyTab => 'ទិន្នន័យចាស់';

  @override
  String get buildingTab => 'អគារ';

  @override
  String get tenantTab => 'អ្នកជួល';

  @override
  String get settingsTab => 'ការកំណត់';

  @override
  String get detailedAnalysis => 'ការវិភាគលម្អិត';

  @override
  String get moneyTab => 'ប្រាក់';

  @override
  String get buildingAnalysisTab => 'អគារ';

  @override
  String get welcomeBack => 'សូមស្វាគមន័យការត្រឡប់មកវិញ';

  @override
  String get signInPrompt => 'ចូលទៅក្នុងគណនីរបស់អ្នក';

  @override
  String get tenantInformation => 'ព័ត៌មានអ្នកជួល';

  @override
  String deleteTenantConfirmMsg(String tenant) {
    return 'តើអ្នកពិតជាចង់លុបអ្នកជួល $tenant មែនទេ?';
  }

  @override
  String get editReceipt => 'កែប្រែវិក្កយបត្រ';

  @override
  String get createNewReceipt => 'បង្កើតវិក្កយបត្រថ្មី';

  @override
  String get noBuildingsPrompt => 'មិនមានអគារទេ។ សូមបង្កើតអគារមុននឹងបង្កើតវិក្កយបត្រ។';

  @override
  String get createNewBuilding => 'បង្កើតអគារថ្មី';

  @override
  String get selectBuilding => 'ជ្រើសរើសអគារ';

  @override
  String get all => 'ទាំងអស់';

  @override
  String get selectRoom => 'ជ្រើសរើសបន្ទប់';

  @override
  String get noOccupiedRooms => 'មិនមានបន្ទប់ដែលមានអ្នកជួលទេ';

  @override
  String get pleaseSelectRoom => 'សូមជ្រើសរើសបន្ទប់';

  @override
  String get previousMonthUsage => 'ការប្រើប្រាស់ខែមុន';

  @override
  String get currentMonthUsage => 'ការប្រើប្រាស់ខែនេះ';

  @override
  String get waterM3 => 'ទឹក (m³)';

  @override
  String get electricityKWh => 'ភ្លើង (kWh)';

  @override
  String get services => 'សេវា';

  @override
  String get selectBuildingFirst => 'សូមជ្រើសរើសអគារមុនសិន';

  @override
  String get noServicesForBuilding => 'មិនមានសេវាកម្មសម្រាប់អគារនេះទេ';

  @override
  String get errorLoadingServices => 'មានបញ្ហាក្នុងការផ្ទុកសេវាកម្ម';

  @override
  String get receiptDetailTitle => 'វិក្កយបត្របន្ទប់ជួល';

  @override
  String get shareReceipt => 'ចែករំលែកវិក្កយបត្រ';

  @override
  String receiptForRoom(Object room) {
    return 'វិក្កយបត្របន្ទប់ $room';
  }

  @override
  String get tenantInfo => 'ព័ត៌មានអ្នកជួល';

  @override
  String tenantName(Object name) {
    return 'ម្ចាស់បន្ទប់៖ $name';
  }

  @override
  String get phoneNumber => 'លេខទូរស័ព្ទ';

  @override
  String get utilityUsage => 'ការប្រើប្រាស់';

  @override
  String get waterPreviousMonth => 'ទឹកប្រើប្រាស់ខែមុន';

  @override
  String get waterCurrentMonth => 'ទឹកប្រើប្រាស់ខែនេះ';

  @override
  String get electricPreviousMonth => 'ភ្លើងប្រើប្រាស់ខែមុន';

  @override
  String get electricCurrentMonth => 'ភ្លើងប្រើប្រាស់ខែនេះ';

  @override
  String get paymentBreakdown => 'ទូទាត់ការប្រើប្រាស់';

  @override
  String get waterUsage => 'ទឹកប្រើប្រាស់';

  @override
  String get totalWaterPrice => 'ថ្លៃទឹកសរុប';

  @override
  String get electricUsage => 'ភ្លើងប្រើប្រាស់';

  @override
  String get totalElectricPrice => 'ថ្លៃភ្លើងសរុប';

  @override
  String get additionalServices => 'សេវាកម្មបន្ថែម';

  @override
  String get totalServicePrice => 'សរុបសេវាកម្ម';

  @override
  String get roomRent => 'ថ្លៃជួលបន្ទប់';

  @override
  String get grandTotal => 'សរុបទឹកប្រាក់';

  @override
  String get available => 'ទំនេរ';

  @override
  String get rented => 'មានអ្នកជួល';

  @override
  String get editService => 'កែប្រែសេវា';

  @override
  String get createNewService => 'បង្កើតសេវាថ្មី';

  @override
  String get serviceName => 'ឈ្មោះសេវា';

  @override
  String get serviceNameRequired => 'សូមបញ្ចូលឈ្មោះសេវា';

  @override
  String get servicePriceLabel => 'តម្លៃសេវា';

  @override
  String get addService => 'បញ្ចូលសេវា';

  @override
  String get currencyServiceUnavailable => 'សេវាប្រាក់ប្តូរមានបញ្ហា - កំពុងបង្ហាញអត្រាមូលដ្ឋាន USD ជំនួសវិញ';

  @override
  String get thankYouForUsingOurService => 'សូមអរគុណសម្រាប់ការប្រើប្រាស់សេវាកម្មរបស់យើងខ្ញុំ!';

  @override
  String get currencyConversionFailed => 'បរាជ័យក្នុងការប្តូរប្រាក់';

  @override
  String get shareReceiptFailed => 'មានបញ្ហាក្នុងការចែករំលែក';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get errorLoadingBuildings => 'មានបញ្ហាក្នុងការទាញយកអគារ';

  @override
  String get unknown => 'មិនស្គាល់';

  @override
  String get menu => 'ម៉ឺនុយ';

  @override
  String get dueDate => 'កាលបរិច្ឆេទផុតកំណត់';

  @override
  String get paidStatus => 'បានបង់ប្រាក់';

  @override
  String get pendingStatus => 'មិនទាន់បង់ប្រាក់';

  @override
  String get overdueStatus => 'ហួសកំណត់';

  @override
  String get delete => 'លុប';

  @override
  String get unknownRoom => 'មិនស្គាល់បន្ទប់';

  @override
  String get room => 'បន្ទប់';

  @override
  String get changedTo => 'បានផ្លាស់ប្តូរទៅជា';

  @override
  String get noTenants => 'មិនមានអ្នកជួល';

  @override
  String get tapToAddNewTenant => 'សូមចុចប៊ូតុង + ដើម្បីបន្ថែមអ្នកជួលថ្មី';

  @override
  String get errorLoadingData => 'មានបញ្ហាក្នុងការផ្ទុកទិន្នន័យ';

  @override
  String get tryAgain => 'ព្យាយាមម្តងទៀត';

  @override
  String get male => 'បុរស';

  @override
  String get female => 'នារី';

  @override
  String get other => 'ផ្សេងៗ';

  @override
  String get contactInformation => 'ព័ត៌មានទំនាក់ទំនង';

  @override
  String get roomInformation => 'ព័ត៌មានបន្ទប់';

  @override
  String get notAvailable => 'មិនមាន';

  @override
  String get rentalPrice => 'ថ្លៃជួល';

  @override
  String get editTenant => 'កែប្រែអ្នកជួល';

  @override
  String get createNewTenant => 'បង្កើតអ្នកជួលថ្មី';

  @override
  String get pleaseEnterTenantName => 'សូមបញ្ចូលឈ្មោះអ្នកជួល';

  @override
  String get pleaseEnterPhoneNumber => 'សូមបញ្ចូលលេខទូរស័ព្ទ';

  @override
  String get invalidPhoneNumber => 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';

  @override
  String get searchCountry => 'ស្វែងរកប្រទេស';

  @override
  String get gender => 'ភេទ';

  @override
  String get updateTenant => 'កែប្រអ្នកជួល';

  @override
  String get createTenant => 'បង្កើតអ្នកជួល';

  @override
  String get errorLoadingRooms => 'មានបញ្ហាក្នុងការផ្ទុកបន្ទប់';

  @override
  String get emailLabel => 'អ៊ីមែល';

  @override
  String get emailHint => 'បញ្ចូលអ៊ីមែលរបស់អ្នក';

  @override
  String get passwordLabel => 'ពាក្យសម្ងាត់';

  @override
  String get passwordHint => 'បញ្ចូលពាក្យសម្ងាត់របស់អ្នក';

  @override
  String get loginButton => 'ចូលប្រើ';

  @override
  String get noAccount => 'មិនមានគណនីទេ?';

  @override
  String get registerLink => 'ចុះឈ្មោះ';

  @override
  String get createAccount => 'បង្កើតគណនីថ្មី';

  @override
  String get signUpPrompt => 'ចុះឈ្មោះដើម្បីចាប់ផ្តើមប្រើប្រាស់';

  @override
  String get fullNameLabel => 'ឈ្មោះពេញ';

  @override
  String get fullNameHint => 'បញ្ចូលឈ្មោះពេញរបស់អ្នក';

  @override
  String get registerButton => 'ចុះឈ្មោះ';

  @override
  String get haveAccount => 'មានគណនីរួចហើយ?';

  @override
  String get loginLink => 'ចូលប្រើ';

  @override
  String get buildingsTitle => 'អគារ';

  @override
  String get searchBuildingHint => 'ស្វែងរកអគារ...';

  @override
  String get confirmDelete => 'បញ្ជាក់ការលុប';

  @override
  String get buildings => 'អគារ';

  @override
  String get searchBuildings => 'ស្វែងរកអគារ...';

  @override
  String get noBuildingsFound => 'រកមិនឃើញអគារ';

  @override
  String get noBuildingsAvailable => 'មិនមានអគារ';

  @override
  String get tryDifferentKeywords => 'សូមព្យាយាមស្វែងរកជាមួយពាក្យគន្លឹះផ្សេង';

  @override
  String get tapPlusToAddBuilding => 'សូមចុចប៊ូតុង + ដើម្បីបន្ថែមអគារថ្មី';

  @override
  String get loading => 'កំពុងដំណើរការ...';

  @override
  String deleteBuildingConfirmMsg(Object name) {
    return 'តើអ្នកពិតជាចង់លុបអគារ \"$name\" មែនទេ?';
  }

  @override
  String get cancel => 'បោះបង់';

  @override
  String buildingDeletedSuccess(Object name) {
    return 'បានលុបអគារ \"$name\" ជោគជ័យ';
  }

  @override
  String buildingDeleted(String building, Object name) {
    return 'អគារ $building ត្រូវបានលុបដោយជោគជ័យ';
  }

  @override
  String buildingDeleteFailed(Object error) {
    return 'បរាជ័យក្នុងការលុបអគារ: $error';
  }

  @override
  String get rentPriceLabel => 'តម្លៃជួលប្រចាំខែ';

  @override
  String get electricPricePerKwh => 'តម្លៃអគ្គិសនី (1kWh)';

  @override
  String get waterPricePerCubicMeter => 'តម្លៃទឹក (1m³)';

  @override
  String get rentPricePerMonthLabel => 'តម្លៃជួលប្រចាំខែ';

  @override
  String rentPricePerMonth(Object price) {
    return 'តម្លៃជួលប្រចាំខែ';
  }

  @override
  String passKey(Object key) {
    return 'Key: $key';
  }

  @override
  String get perMonth => '/ខែ';

  @override
  String get electricity => 'អគ្គិសនី';

  @override
  String get water => 'ទឹក';

  @override
  String get viewDetails => 'មើលព័ត៌មានលម្អិត';

  @override
  String get edit => 'កែប្រែ';

  @override
  String ofTotal(Object total) {
    return '/$total';
  }

  @override
  String deleteConfirmMsg(String building) {
    return 'តើអ្នកពិតជាចង់លុបអគារ $building មែនទេ?';
  }

  @override
  String deleteFailed(String error) {
    return 'បរាជ័យក្នុងការលុបអគារ: $error';
  }

  @override
  String get noBuildings => 'មិនមានអគារ';

  @override
  String get noBuildingsSearch => 'រកមិនឃើញអគារ';

  @override
  String get addNewBuildingHint => 'សូមចុចប៊ូតុង + ដើម្បីបន្ថែមអគារថ្មី';

  @override
  String get tryDifferentKeyword => 'សូមព្យាយាមប្រើពាក្យគន្លឹះផ្សេងទៀត';

  @override
  String get oldDataTitle => 'ទិន្នន័យចាស់';

  @override
  String get searchReceiptHint => 'ស្វែងរកវិក្កយបត្រ...';

  @override
  String get viewDetail => 'មើលលម្អិត';

  @override
  String get share => 'ចែករំលែក';

  @override
  String get deleteOption => 'លុប';

  @override
  String get undo => 'មិនធ្វើវិញ';

  @override
  String get receiptTitle => 'វិក្កយបត្រ';

  @override
  String get noReceipts => 'មិនមានវិក្កយបត្រ';

  @override
  String get settingsTitle => 'ការកំណត់';

  @override
  String get settings => 'ការកំណត់';

  @override
  String get changeRoom => 'ផ្លាស់ប្តូរបន្ទប់';

  @override
  String get building => 'អគារ';

  @override
  String roomNumberLabel(Object number) {
    return 'បន្ទប់ $number';
  }

  @override
  String get tenantNameLabel => 'ឈ្មោះ';

  @override
  String roomStatus(Object status) {
    return 'ស្ថានភាព: $status';
  }

  @override
  String rentPrice(Object price) {
    return 'តម្លៃជួល៖ $price\$';
  }

  @override
  String get noRoom => 'មិនមានបន្ទប់';

  @override
  String get accountSettings => 'ការកំណត់គណនី';

  @override
  String get accountSettingsSubtitle => 'ឯកជនភាព, សុវត្ថិភាព, ប្តូរពាក្យសម្ងាត់';

  @override
  String get privacySecurity => 'ភាពឯកជន សុវត្ថិភាព និងការផ្លាស់ប្តូរពាក្យសម្ងាត់';

  @override
  String get subscriptions => 'ការជាវសេវាកម្ម';

  @override
  String get subscriptionsSubtitle => 'គម្រោង, វិធីសាស្រ្តទូទាត់';

  @override
  String get plansPayments => 'គម្រោង និងវិធីទូទាត់ប្រាក់';

  @override
  String get appearance => 'រូបរាង';

  @override
  String get darkMode => 'Theme ងងឹត';

  @override
  String get lightMode => 'Theme ភ្លឺ';

  @override
  String get systemDefault => 'លំនាំដើមប្រព័ន្ធ';

  @override
  String get language => 'ភាសា';

  @override
  String get khmer => 'ខ្មែរ';

  @override
  String get english => 'English';

  @override
  String get chinese => 'ចិន';

  @override
  String get helpAndSupport => 'ជំនួយ';

  @override
  String get helpAndSupportSubtitle => 'សំណួរញឹកញាប់ និងទំនាក់ទំនងមកយើង';

  @override
  String get faqContact => 'សំណួរញឹកញាប់ និងទំនាក់ទំនងមកយើង';

  @override
  String get about => 'អំពីកម្មវិធី';

  @override
  String get receiptDeleted => 'បានលុបវិក្កយបត្រដោយជោគជ័យ';

  @override
  String get receiptRestored => 'បានស្ដារវិក្កយបត្រដោយជោគជ័យ';

  @override
  String noReceiptsForMonth(String month) {
    return 'មិនមានវិក្កយបត្រសម្រាប់ខែ $month';
  }

  @override
  String get noReceiptsForBuilding => 'មិនមានវិក្កយបត្រសម្រាប់អគារនេះ';

  @override
  String noSearchResults(String query) {
    return 'មិនមានលទ្ធផលស្វែងរកសម្រាប់ \"$query\"';
  }

  @override
  String receiptStatusChanged(String status) {
    return 'ស្ថានភាពវិក្កយបត្របានផ្លាស់ប្តូរទៅជា $status';
  }

  @override
  String version(String versionNumber) {
    return 'ជំនាន់ $versionNumber';
  }

  @override
  String get signOut => 'ចាកចេញ';

  @override
  String get signOutConfirm => 'តើអ្នកពិតជាចង់ចេញពីប្រព័ន្ធមែនទេ?';

  @override
  String get signOutConfirmation => 'តើអ្នកប្រាកដថាចង់ចាកចេញ?';

  @override
  String get selectLanguage => 'ជ្រើសរើសភាសា';

  @override
  String get premiumMember => 'សមាជិក Premium';

  @override
  String get tenantsTitle => 'អ្នកជួល';

  @override
  String get searchTenantHint => 'ស្វែងរកអ្នកជួល...';

  @override
  String tenantAdded(String tenant) {
    return 'បានបន្ថែមអ្នកជួល $tenant ដោយជោគជ័យ';
  }

  @override
  String get tenantAddFailed => 'បរាជ័យក្នុងការបន្ថែមអ្នកជួល';

  @override
  String tenantUpdated(String tenant) {
    return 'បានកែប្រែព័ត៌មានអ្នកជួល $tenant ដោយជោគជ័យ';
  }

  @override
  String get tenantUpdateFailed => 'បរាជ័យក្នុងការកែប្រែព័ត៌មាន';

  @override
  String tenantDeleted(String tenant) {
    return 'បានលុបអ្នកជួល $tenant';
  }

  @override
  String get tenantDeleteFailed => 'បរាជ័យក្នុងការលុបអ្នកជួល';

  @override
  String roomChanged(String tenant, String room) {
    return 'បានផ្លាស់ប្តូរបន្ទប់សម្រាប់ $tenant ទៅបន្ទប់ $room';
  }

  @override
  String priceValue(Object price) {
    return 'តម្លៃ: $price\$';
  }

  @override
  String get rooms => 'បន្ទប់';

  @override
  String servicePrice(Object price) {
    return 'តម្លៃសេវា: $price\$';
  }

  @override
  String get addRoom => 'បន្ថែមបន្ទប់';

  @override
  String get noRooms => 'គ្មានបន្ទប់';

  @override
  String get noServices => 'គ្មានសេវា';

  @override
  String get pullToRefresh => 'ទាញចុះដើម្បីផ្ទុកទិន្នន័យឡើងវិញ';

  @override
  String roomAddedSuccess(Object number) {
    return 'បន្ថែមបន្ទប់ \"$number\" ដោយជោគជ័យ';
  }

  @override
  String roomUpdatedSuccess(Object number) {
    return 'កែប្រែបន្ទប់ \"$number\" ដោយជោគជ័យ';
  }

  @override
  String roomDeletedSuccess(Object number) {
    return 'បានលុបបន្ទប់ \"$number\" ជោគជ័យ';
  }

  @override
  String serviceAddedSuccess(Object name) {
    return 'បន្ថែមសេវា \"$name\" ដោយជោគជ័យ';
  }

  @override
  String serviceUpdatedSuccess(Object name) {
    return 'កែប្រែសេវា \"$name\" ដោយជោគជ័យ';
  }

  @override
  String serviceDeletedSuccess(Object name) {
    return 'បានលុបសេវា \"$name\" ជោគជ័យ';
  }

  @override
  String buildingUpdatedSuccess(Object name) {
    return 'កែប្រែអគារ \"$name\" ដោយជោគជ័យ';
  }

  @override
  String get deleteBuilding => 'លុបអគារ';

  @override
  String deleteBuildingConfirm(Object name) {
    return 'តើអ្នកចង់លុបអគារ \"$name\"?';
  }

  @override
  String get deleteRoom => 'លុបបន្ទប់';

  @override
  String deleteRoomConfirm(Object number) {
    return 'តើអ្នកចង់លុបបន្ទប់ \"$number\"?';
  }

  @override
  String get deleteService => 'លុបសេវា';

  @override
  String deleteServiceConfirm(Object name) {
    return 'តើអ្នកចង់លុបសេវា \"$name\"?';
  }

  @override
  String get errorOccurred => 'មានកំហុស';

  @override
  String get addNewBuilding => 'បញ្ចូលអគារថ្មី';

  @override
  String get editBuilding => 'កែប្រែអគារ';

  @override
  String get buildingName => 'ឈ្មោះអគារ';

  @override
  String get buildingNameRequired => 'សូមបញ្ចូលឈ្មោះអគារ។';

  @override
  String get roomCount => 'ចំនួនបន្ទប់';

  @override
  String get currentRoomCount => 'ចំនួនបន្ទប់បច្ចុប្បន្ន';

  @override
  String get roomCountRequired => 'សូមបញ្ចូលចំនួនបន្ទប់។';

  @override
  String get roomCountInvalid => 'សូមបញ្ចូលចំនួនបន្ទប់ត្រឹមត្រូវ។';

  @override
  String get roomCountEditNote => 'ចំនួនបន្ទប់មិនអាចកែប្រែបានទេ។ សូមគ្រប់គ្រងបន្ទប់នីមួយៗដាច់ដោយឡែក។';

  @override
  String get saveChanges => 'រក្សាទុកការកែប្រែ';

  @override
  String get saveBuilding => 'រក្សាទុកអគារ';

  @override
  String get roomChangeFailed => 'មានបញ្ហាក្នុងការផ្លាស់ប្តូរបន្ទប់';

  @override
  String get retryLoadingProfile => 'ព្យាយាមម្តងទៀត';

  @override
  String get failedToLoadProfile => 'ការទាញយកព័ត៌មាន Profile បានបរាជ័យ';

  @override
  String get noLoggedIn => 'អ្នកមិនទាន់បានចូលគណនីទេ។';

  @override
  String get notLoggedIn => 'អ្នកមិនទាន់បានចូលគណនីទេ។';

  @override
  String get goToOnboarding => 'ទៅកាន់ទំព័រណែនាំប្រើប្រាស់';

  @override
  String get unknownUser => 'អ្នកប្រើប្រាស់មិនស្គាល់';

  @override
  String get noEmailProvided => 'គ្មានអ៊ីមែល';

  @override
  String get editProfileTapped => 'បានចុចកែប្រែប្រវត្តិ';

  @override
  String get signOutSuccess => 'ចេញពីប្រព័ន្ធដោយជោគជ័យ!';

  @override
  String get signOutFailed => 'បរាជ័យក្នុងការចេញពីប្រព័ន្ធ';

  @override
  String get confirmPasswordLabel => 'បញ្ជាក់ពាក្យសម្ងាត់';

  @override
  String get confirmPasswordHint => 'បញ្ចាក់ពាក្យសម្ងាត់របស់អ្នក';

  @override
  String get manageBuildings => 'គ្រប់គ្រងអគារ និងបន្ទប់';

  @override
  String get manageBuildingsDesc => 'គ្រប់គ្រងអគារ បន្ទប់ និងសេវាកម្មរបស់អ្នកយ៉ាងងាយស្រួលជាមួយផ្ទាំងគ្រប់គ្រងរបស់យើង។';

  @override
  String get tenantManagement => 'ការគ្រប់គ្រងអ្នកជួល';

  @override
  String get tenantManagementDesc => 'ចាត់ចែងអ្នកជួល និងបង្កើតវិក្កយបត្រស្វ័យប្រវត្តិបានយ៉ាងងាយស្រួល។';

  @override
  String get paymentTracking => 'ការតាមដានការទូទាត់ប្រាក់';

  @override
  String get paymentTrackingDesc => 'តាមដានស្ថានភាពការទូទាត់បានយ៉ាងងាយស្រួល - រង់ចាំ បង់រួច និងហួសកំណត់។';

  @override
  String get automationTools => 'ឧបករណ៍ស្វ័យប្រវត្តិ';

  @override
  String get automationToolsDesc => 'ធ្វើឱ្យការងារស្វ័យប្រវត្តិជាមួយការរំលឹកតាម Telegram និងការបញ្ចូលឧបករណ៍ជាច្រើន។';

  @override
  String get advancedAnalysis => 'ការវិភាគកម្រិតខ្ពស់';

  @override
  String get financial => 'ហិរញ្ញវត្ថុ';

  @override
  String get errorLoadingCurrencyRate => 'មានបញ្ហាក្នុងការទាញយកអត្រាប្តូរប្រាក់';

  @override
  String get january => 'មករា';

  @override
  String get february => 'កុម្ភៈ';

  @override
  String get march => 'មីនា';

  @override
  String get april => 'មេសា';

  @override
  String get may => 'ឧសភា';

  @override
  String get june => 'មិថុនា';

  @override
  String get july => 'កក្កដា';

  @override
  String get august => 'សីហា';

  @override
  String get september => 'កញ្ញា';

  @override
  String get october => 'តុលា';

  @override
  String get november => 'វិច្ឆិកា';

  @override
  String get december => 'ធ្នូ';

  @override
  String get orSignOut => 'ឬ ចាកចេញ';

  @override
  String get pleaseEnterValue => 'សូមបញ្ចូលតម្លៃ';

  @override
  String get pleaseEnterValidNumber => 'សូមបញ្ចូលលេខត្រឹមត្រូវ';

  @override
  String receiptsCount(num count) {
    return '$count វិក្កយបត្រ';
  }

  @override
  String receiptDeletedRoom(String room) {
    return 'បានលុបវិក្កយបត្របន្ទប់ $room';
  }

  @override
  String get receiptNotFound => 'រកមិនឃើញវិក្កយបត្រ';

  @override
  String get addReceipt => 'បន្ថែមវិក្កយបត្រ';

  @override
  String deleteReceiptConfirmMsg(String room) {
    return 'តើអ្នកប្រាកដជាចង់លុបវិក្កយបត្រសម្រាប់បន្ទប់ $room មែនទេ?';
  }

  @override
  String get totalRevenue => 'ប្រាក់ចំណូលសរុប';

  @override
  String get paid => 'បានបង់ប្រាក់';

  @override
  String get remaining => 'នៅសល់';

  @override
  String collectionRate(String rate) {
    return 'អត្រាប្រមូល: $rate%';
  }

  @override
  String get tapToSeeDetails => 'ចុចដើម្បីមើលលម្អិត';

  @override
  String get utilityAnalysis => 'ការវិភាគតម្លៃ';

  @override
  String get pending => 'មិនទាន់បង់';

  @override
  String get overdue => 'ហួសកំណត់';

  @override
  String get selectMonth => 'ជ្រើសរើសខែ';

  @override
  String get year => 'ឆ្នាំ: ';

  @override
  String get month => 'ខែ:';

  @override
  String get previousMonth => 'ខែមុន';

  @override
  String get nextMonth => 'ខែបន្ទាប់';

  @override
  String get service => 'សេវាកម្ម';

  @override
  String get emailValidationInvalid => 'សូមបញ្ចូលអ៊ីមែលដែលត្រឹមត្រូវ';

  @override
  String get passwordValidationLength => 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ 6 តួអក្សរ';

  @override
  String get passwordsDoNotMatch => 'ពាក្យសម្ងាត់មិនតរងគ្នាទេ';

  @override
  String get chooseLanguageTitle => 'ជ្រើសរើសភាសារបស់អ្នក';

  @override
  String get chooseLanguageSubtitle => 'ជ្រើសរើសភាសាដែលអ្នកចូលចិត្ត';

  @override
  String get continueButton => 'បន្ត';

  @override
  String get nextButton => 'បន្ទាប់';
}
