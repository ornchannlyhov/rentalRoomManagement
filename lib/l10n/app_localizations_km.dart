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
  String get historyTab => 'ប្រវត្តិ';

  @override
  String get buildingTab => 'អគារ';

  @override
  String get tenantTab => 'អ្នកជួល';

  @override
  String get settingsTab => 'ការកំណត់';

  @override
  String get detailedAnalysis => 'ការវិភាគលម្អិត';

  @override
  String get moneyTab => 'ហិរញ្ញវត្ថុ';

  @override
  String get buildingAnalysisTab => 'អគារ';

  @override
  String get welcomeBack => 'សូមស្វាគមន៍';

  @override
  String get signInPrompt => 'ចូលគណនីរបស់អ្នក';

  @override
  String get tenantInformation => 'ព័ត៌មានអ្នកជួល';

  @override
  String deleteTenantConfirmMsg(String tenant) {
    return 'តើអ្នកប្រាកដថាចង់លុបអ្នកជួល $tenant ដែរឬទេ?';
  }

  @override
  String get report => 'របាយការណ៍';

  @override
  String get reports => 'របាយការណ៍';

  @override
  String get addReport => 'បន្ថែមរបាយការណ៍';

  @override
  String get editReport => 'កែប្រែរបាយការណ៍';

  @override
  String get deleteReport => 'លុបរបាយការណ៍';

  @override
  String get noReports => 'គ្មានរបាយការណ៍';

  @override
  String get reportAddedSuccess => 'បន្ថែមរបាយការណ៍ដោយជោគជ័យ';

  @override
  String get reportUpdatedSuccess => 'ធ្វើបច្ចុប្បន្នភាពរបាយការណ៍ដោយជោគជ័យ';

  @override
  String get reportDeletedSuccess => 'លុបរបាយការណ៍ដោយជោគជ័យ';

  @override
  String get deleteReportConfirm => 'តើអ្នកប្រាកដថាចង់លុបរបាយការណ៍នេះទេ?';

  @override
  String get selectTenant => 'សូមជ្រើសរើសអ្នកជួល';

  @override
  String get problemDescription => 'ការពិពណ៌នាអំពីបញ្ហា';

  @override
  String get enterProblemDescription => 'សូមបញ្ចូលការពិពណ៌នាអំពីបញ្ហា';

  @override
  String get noTenant => 'គ្មានអ្នកជួល';

  @override
  String get optional => 'ជាជម្រើស';

  @override
  String get reportStatusPending => 'រង់ចាំ';

  @override
  String get reportStatusInProgress => 'កំពុងដំណើរការ';

  @override
  String get reportStatusResolved => 'បានដោះស្រាយ';

  @override
  String get reportStatusClosed => 'បានបិទ';

  @override
  String get reportPriorityLow => 'ទាប';

  @override
  String get reportPriorityMedium => 'មធ្យម';

  @override
  String get reportPriorityHigh => 'ខ្ពស់';

  @override
  String get reportLanguageEnglish => 'អង់គ្លេស';

  @override
  String get reportLanguageKhmer => 'ខ្មែរ';

  @override
  String get editReceipt => 'កែប្រែវិក្កយបត្រ';

  @override
  String get createNewReceipt => 'បង្កើតវិក្កយបត្រថ្មី';

  @override
  String get noBuildingsPrompt => 'គ្មានអគារទេ។ សូមបង្កើតអគារជាមុនសិន មុននឹងបង្កើតវិក្កយបត្រ។';

  @override
  String get createNewBuilding => 'បង្កើតអគារថ្មី';

  @override
  String get selectBuilding => 'ជ្រើសរើសអគារ';

  @override
  String get all => 'ទាំងអស់';

  @override
  String get selectRoom => 'ជ្រើសរើសបន្ទប់';

  @override
  String get noOccupiedRooms => 'គ្មានបន្ទប់ដែលមានអ្នកស្នាក់នៅ';

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
  String get services => 'សេវាកម្ម';

  @override
  String get selectBuildingFirst => 'សូមជ្រើសរើសអគារជាមុនសិន';

  @override
  String get noServicesForBuilding => 'មិនមានសេវាកម្មសម្រាប់អគារនេះទេ';

  @override
  String get errorLoadingServices => 'មានកំហុសក្នុងការផ្ទុកសេវាកម្ម';

  @override
  String get receiptDetailTitle => 'ព័ត៌មានលម្អិតវិក្កយបត្រ';

  @override
  String get shareReceipt => 'ចែករំលែកវិក្កយបត្រ';

  @override
  String receiptForRoom(Object room) {
    return 'វិក្កយបត្រសម្រាប់បន្ទប់ $room';
  }

  @override
  String get tenantInfo => 'ព័ត៌មានអ្នកជួល';

  @override
  String tenantName(Object name) {
    return 'អ្នកជួល៖ $name';
  }

  @override
  String get phoneNumber => 'លេខទូរស័ព្ទ';

  @override
  String get utilityUsage => 'ការប្រើប្រាស់ទឹកភ្លើង';

  @override
  String get waterPreviousMonth => 'ទឹក (ខែមុន)';

  @override
  String get waterCurrentMonth => 'ទឹក (ខែនេះ)';

  @override
  String get electricPreviousMonth => 'ភ្លើង (ខែមុន)';

  @override
  String get electricCurrentMonth => 'ភ្លើង (ខែនេះ)';

  @override
  String get paymentBreakdown => 'ការបែងចែកការទូទាត់';

  @override
  String get waterUsage => 'ការប្រើប្រាស់ទឹក';

  @override
  String get totalWaterPrice => 'ថ្លៃទឹកសរុប';

  @override
  String get electricUsage => 'ការប្រើប្រាស់ភ្លើង';

  @override
  String get totalElectricPrice => 'ថ្លៃភ្លើងសរុប';

  @override
  String get additionalServices => 'សេវាកម្មបន្ថែម';

  @override
  String get totalServicePrice => 'ថ្លៃសេវាសរុប';

  @override
  String get roomRent => 'ថ្លៃឈ្នួលបន្ទប់';

  @override
  String get grandTotal => 'សរុបទាំងអស់';

  @override
  String get available => 'ទំនេរ';

  @override
  String get rented => 'ជួលហើយ';

  @override
  String get editService => 'កែប្រែសេវាកម្ម';

  @override
  String get createNewService => 'បង្កើតសេវាកម្មថ្មី';

  @override
  String get serviceName => 'ឈ្មោះសេវាកម្ម';

  @override
  String get serviceNameRequired => 'សូមបញ្ចូលឈ្មោះសេវាកម្ម';

  @override
  String get servicePriceLabel => 'តម្លៃសេវា';

  @override
  String get addService => 'បន្ថែមសេវាកម្ម';

  @override
  String get currencyServiceUnavailable => 'សេវារូបិយប័ណ្ណមិនអាចដំណើរការបាន – បង្ហាញអត្រា USD មូលដ្ឋាន';

  @override
  String get thankYouForUsingOurService => 'សូមអរគុណសម្រាប់ការប្រើប្រាស់សេវាកម្មរបស់យើង!';

  @override
  String get currencyConversionFailed => 'បរាជ័យក្នុងការបំប្លែងរូបិយប័ណ្ណ';

  @override
  String get shareReceiptFailed => 'បរាជ័យក្នុងការចែករំលែកវិក្កយបត្រ';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get errorLoadingBuildings => 'មានកំហុសក្នុងការផ្ទុកអគារ';

  @override
  String get unknown => 'មិនស្គាល់';

  @override
  String get menu => 'ម៉ឺនុយ';

  @override
  String get dueDate => 'កាលបរិច្ឆេទកំណត់';

  @override
  String get paidStatus => 'បានបង់';

  @override
  String get pendingStatus => 'រង់ចាំ';

  @override
  String get notes => 'កំណត់សម្គាល់';

  @override
  String get priorityLabel => 'អាទិភាព';

  @override
  String get overdueStatus => 'ហួសកំណត់';

  @override
  String get status => 'ស្ថានភាព';

  @override
  String get delete => 'លុប';

  @override
  String get unknownRoom => 'មិនស្គាល់បន្ទប់';

  @override
  String get room => 'បន្ទប់';

  @override
  String get changedTo => 'បានប្តូរទៅ';

  @override
  String get noTenants => 'គ្មានអ្នកជួល';

  @override
  String get tapToAddNewTenant => 'ចុច + ដើម្បីបន្ថែមអ្នកជួលថ្មី';

  @override
  String get errorLoadingData => 'មានកំហុសក្នុងការផ្ទុកទិន្នន័យ';

  @override
  String get tryAgain => 'ព្យាយាមម្តងទៀត';

  @override
  String get male => 'ប្រុស';

  @override
  String get changeStatus => 'ផ្លាស់ប្តូរស្ថានភាព';

  @override
  String get filterByStatus => 'ត្រងតាមស្ថានភាព';

  @override
  String get allReports => 'របាយការណ៍ទាំងអស់';

  @override
  String get unknownTenant => 'មិនស្គាល់អ្នកជួល';

  @override
  String reportStatusUpdated(String status) {
    return 'ស្ថានភាពរបាយការណ៍ត្រូវបានកែប្រែទៅ $status';
  }

  @override
  String get reportStatusUpdateFailed => 'បរាជ័យក្នុងការធ្វើបច្ចុប្បន្នភាពស្ថានភាពរបាយការណ៍';

  @override
  String noFilteredReports(String status) {
    return 'គ្មានរបាយការណ៍ $status';
  }

  @override
  String get noFilteredReportsSubtitle => 'គ្មានរបាយការណ៍ដែលត្រូវនឹងស្ថានភាពដែលបានជ្រើសរើសទេ';

  @override
  String get clearFilter => 'សម្អាតការត្រង';

  @override
  String deleteReportConfirmFrom(String tenant) {
    return 'តើអ្នកប្រាកដថាចង់លុបរបាយការណ៍នេះពី $tenant ទេ?';
  }

  @override
  String get reportPriorityUrgent => 'បន្ទាន់';

  @override
  String deleteBuildingWarning(String name) {
    return 'តើអ្នកប្រាកដថាចង់លុប $name ទេ? នេះនឹងលុបបន្ទប់ សេវាកម្ម និងទិន្នន័យពាក់ព័ន្ធទាំងអស់។';
  }

  @override
  String get noRoomsSubtitle => 'ទាញដើម្បីផ្ទុកឡើងវិញ ឬបន្ថែមបន្ទប់ថ្មី';

  @override
  String get noServicesSubtitle => 'ទាញដើម្បីផ្ទុកឡើងវិញ ឬបន្ថែមសេវាកម្មថ្មី';

  @override
  String get noReportsSubtitle => 'ទាញដើម្បីផ្ទុកឡើងវិញ';

  @override
  String get refresh => 'ផ្ទុកឡើងវិញ';

  @override
  String get female => 'ស្រី';

  @override
  String get other => 'ផ្សេងៗ';

  @override
  String get contactInformation => 'ព័ត៌មានទំនាក់ទំនង';

  @override
  String get roomInformation => 'ព័ត៌មានបន្ទប់';

  @override
  String get notAvailable => 'N/A';

  @override
  String get rentalPrice => 'តម្លៃជួល';

  @override
  String get editTenant => 'កែប្រែអ្នកជួល';

  @override
  String get createNewTenant => 'បង្កើតអ្នកជួលថ្មី';

  @override
  String get tenantNameLabel => 'ឈ្មោះ';

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
  String get updateTenant => 'កែប្រែអ្នកជួល';

  @override
  String get createTenant => 'បង្កើតអ្នកជួល';

  @override
  String get errorLoadingRooms => 'មានកំហុសក្នុងការផ្ទុកបន្ទប់';

  @override
  String get emailLabel => 'អ៊ីមែល';

  @override
  String get emailHint => 'បញ្ចូលអ៊ីមែលរបស់អ្នក';

  @override
  String get passwordLabel => 'ពាក្យសម្ងាត់';

  @override
  String get passwordHint => 'បញ្ចូលពាក្យសម្ងាត់របស់អ្នក';

  @override
  String get loginButton => 'ចូល';

  @override
  String get noAccount => 'មិនទាន់មានគណនី?';

  @override
  String get registerLink => 'ចុះឈ្មោះ';

  @override
  String get createAccount => 'បង្កើតគណនី';

  @override
  String get signUpPrompt => 'ចុះឈ្មោះដើម្បីចាប់ផ្តើម';

  @override
  String get fullNameLabel => 'ឈ្មោះ​ពេញ';

  @override
  String get fullNameHint => 'បញ្ចូលឈ្មោះពេញរបស់អ្នក';

  @override
  String get registerButton => 'ចុះឈ្មោះ';

  @override
  String get haveAccount => 'មានគណនីរួចហើយ?';

  @override
  String get loginLink => 'ចូល';

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
  String get tryDifferentKeywords => 'ព្យាយាមស្វែងរកជាមួយពាក្យគន្លឹះផ្សេង';

  @override
  String get tapPlusToAddBuilding => 'ចុច + ដើម្បីបន្ថែមអគារថ្មី';

  @override
  String get loading => 'កំពុងផ្ទុក...';

  @override
  String deleteBuildingConfirmMsg(Object name) {
    return 'តើអ្នកប្រាកដថាចង់លុបអគារ \"$name\" ដែរឬទេ?';
  }

  @override
  String get cancel => 'បោះបង់';

  @override
  String buildingDeletedSuccess(Object name) {
    return 'អគារ \"$name\" ត្រូវបានលុបដោយជោគជ័យ';
  }

  @override
  String buildingDeleted(Object name) {
    return 'អគារ \"$name\" ត្រូវបានលុប';
  }

  @override
  String buildingDeleteFailed(Object error) {
    return 'បរាជ័យក្នុងការលុបអគារ៖ $error';
  }

  @override
  String get rentPriceLabel => 'តម្លៃជួលប្រចាំខែ';

  @override
  String get electricPricePerKwh => 'តម្លៃភ្លើង (1 kWh)';

  @override
  String get waterPricePerCubicMeter => 'តម្លៃទឹក (1 m³)';

  @override
  String get rentPricePerMonthLabel => 'តម្លៃជួលប្រចាំខែ';

  @override
  String rentPricePerMonth(Object price) {
    return '$price\$/ ខែ';
  }

  @override
  String passKey(Object key) {
    return 'សោ៖ $key';
  }

  @override
  String get perMonth => '/ ខែ';

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
    return '/ $total';
  }

  @override
  String deleteConfirmMsg(String building) {
    return 'តើអ្នកប្រាកដថាចង់លុបអគារ $building ដែរឬទេ?';
  }

  @override
  String deleteFailed(String error) {
    return 'បរាជ័យក្នុងការលុបអគារ៖ $error';
  }

  @override
  String get noBuildings => 'គ្មានអគារ';

  @override
  String get noBuildingsSearch => 'រកមិនឃើញអគារ';

  @override
  String get addNewBuildingHint => 'ចុច + ដើម្បីបន្ថែមអគារថ្មី';

  @override
  String get tryDifferentKeyword => 'ព្យាយាមពាក្យគន្លឹះផ្សេង';

  @override
  String get oldDataTitle => 'ប្រវត្តិ';

  @override
  String get searchReceiptHint => 'ស្វែងរកវិក្កយបត្រ...';

  @override
  String get viewDetail => 'មើលព័ត៌មានលម្អិត';

  @override
  String get share => 'ចែករំលែក';

  @override
  String get deleteOption => 'លុប';

  @override
  String get undo => 'មិនធ្វើវិញ';

  @override
  String get receiptTitle => 'វិក្កយបត្រ';

  @override
  String get noReceipts => 'គ្មានវិក្កយបត្រ';

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
  String roomStatus(Object status) {
    return 'ស្ថានភាព៖ $status';
  }

  @override
  String rentPrice(Object price) {
    return 'តម្លៃជួល៖ $price\$';
  }

  @override
  String get noRoom => 'គ្មានបន្ទប់';

  @override
  String get accountSettings => 'ការកំណត់គណនី';

  @override
  String get accountSettingsSubtitle => 'ឯកជនភាព សុវត្ថិភាព ផ្លាស់ប្តូរពាក្យសម្ងាត់';

  @override
  String get privacySecurity => 'ឯកជនភាព សុវត្ថិភាព ផ្លាស់ប្តូរពាក្យសម្ងាត់';

  @override
  String get subscriptions => 'ការជាវ';

  @override
  String get subscriptionsSubtitle => 'គម្រោង វិធីសាស្រ្តទូទាត់';

  @override
  String get plansPayments => 'គម្រោង វិធីសាស្រ្តទូទាត់';

  @override
  String get appearance => 'រូបរាង';

  @override
  String get darkMode => 'មុខងារងងឹត';

  @override
  String get lightMode => 'មុខងារពន្លឺ';

  @override
  String get systemDefault => 'លំនាំដើមប្រព័ន្ធ';

  @override
  String get language => 'ភាសា';

  @override
  String get khmer => 'ភាសាខ្មែរ';

  @override
  String get english => 'ភាសាអង់គ្លេស';

  @override
  String get chinese => 'ភាសាចិន';

  @override
  String get helpAndSupport => 'ជំនួយ & ការគាំទ្រ';

  @override
  String get helpAndSupportSubtitle => 'សំណួរដែលសួរញឹកញាប់ ទាក់ទងយើង';

  @override
  String get faqContact => 'សំណួរដែលសួរញឹកញាប់ ទាក់ទងយើង';

  @override
  String get about => 'អំពី';

  @override
  String get receiptDeleted => 'វិក្កយបត្រត្រូវបានលុបដោយជោគជ័យ';

  @override
  String get receiptRestored => 'វិក្កយបត្រត្រូវបានស្តារឡើងវិញដោយជោគជ័យ';

  @override
  String noReceiptsForMonth(String month) {
    return 'គ្មានវិក្កយបត្រសម្រាប់ $month';
  }

  @override
  String get noReceiptsForBuilding => 'គ្មានវិក្កយបត្រសម្រាប់អគារនេះទេ';

  @override
  String noSearchResults(String query) {
    return 'គ្មានលទ្ធផលស្វែងរកសម្រាប់ \"$query\"';
  }

  @override
  String receiptStatusChanged(String status) {
    return 'ស្ថានភាពវិក្កយបត្របានប្តូរទៅ $status';
  }

  @override
  String version(String versionNumber) {
    return 'កំណែ $versionNumber';
  }

  @override
  String get signOut => 'ចាកចេញ';

  @override
  String get signOutConfirm => 'តើអ្នកប្រាកដថាចង់ចាកចេញទេ?';

  @override
  String get signOutConfirmation => 'តើអ្នកប្រាកដថាចង់ចាកចេញទេ?';

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
  String get tenantAddFailed => 'មានកំហុសក្នុងការបន្ថែមអ្នកជួល';

  @override
  String tenantUpdated(String tenant) {
    return 'បានកែប្រែអ្នកជួល $tenant ដោយជោគជ័យ';
  }

  @override
  String get tenantUpdateFailed => 'មានកំហុសក្នុងការធ្វើបច្ចុប្បន្នភាពអ្នកជួល';

  @override
  String tenantDeleted(String tenant) {
    return 'បានលុបអ្នកជួល $tenant';
  }

  @override
  String get tenantDeleteFailed => 'មានកំហុសក្នុងការលុបអ្នកជួល';

  @override
  String roomChanged(String tenant, String room) {
    return 'បន្ទប់សម្រាប់ $tenant បានផ្លាស់ប្តូរទៅ $room';
  }

  @override
  String priceValue(Object price) {
    return 'តម្លៃ៖ $price\$';
  }

  @override
  String get rooms => 'បន្ទប់';

  @override
  String servicePrice(Object price) {
    return '$price\$';
  }

  @override
  String get addRoom => 'បន្ថែមបន្ទប់';

  @override
  String get noRooms => 'គ្មានបន្ទប់';

  @override
  String get noServices => 'គ្មានសេវាកម្ម';

  @override
  String get pullToRefresh => 'ទាញចុះក្រោមដើម្បីផ្ទុកឡើងវិញ';

  @override
  String roomAddedSuccess(Object number) {
    return 'បានបន្ថែមបន្ទប់ \"$number\" ដោយជោគជ័យ';
  }

  @override
  String roomUpdatedSuccess(Object number) {
    return 'បានកែប្រែបន្ទប់ \"$number\" ដោយជោគជ័យ';
  }

  @override
  String roomDeletedSuccess(Object number) {
    return 'បានលុបបន្ទប់ \"$number\" ដោយជោគជ័យ';
  }

  @override
  String serviceAddedSuccess(Object name) {
    return 'បានបន្ថែមសេវាកម្ម \"$name\" ដោយជោគជ័យ';
  }

  @override
  String serviceUpdatedSuccess(Object name) {
    return 'បានកែប្រែសេវាកម្ម \"$name\" ដោយជោគជ័យ';
  }

  @override
  String serviceDeletedSuccess(Object name) {
    return 'បានលុបសេវាកម្ម \"$name\" ដោយជោគជ័យ';
  }

  @override
  String buildingUpdatedSuccess(Object name) {
    return 'បានកែប្រែអគារ \"$name\" ដោយជោគជ័យ';
  }

  @override
  String get deleteBuilding => 'លុបអគារ';

  @override
  String deleteBuildingConfirm(Object name) {
    return 'តើអ្នកចង់លុបអគារ \"$name\" ដែរឬទេ?';
  }

  @override
  String get deleteRoom => 'លុបបន្ទប់';

  @override
  String deleteRoomConfirm(Object number) {
    return 'តើអ្នកចង់លុបបន្ទប់ \"$number\" ដែរឬទេ?';
  }

  @override
  String get deleteService => 'លុបសេវាកម្ម';

  @override
  String deleteServiceConfirm(Object name) {
    return 'តើអ្នកចង់លុបសេវាកម្ម \"$name\" ដែរឬទេ?';
  }

  @override
  String get errorOccurred => 'មានកំហុសបានកើតឡើង';

  @override
  String get addNewBuilding => 'បន្ថែមអគារថ្មី';

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
  String get roomCountInvalid => 'សូមបញ្ចូលចំនួនបន្ទប់ដែលត្រឹមត្រូវ។';

  @override
  String get roomCountEditNote => 'ចំនួនបន្ទប់មិនអាចផ្លាស់ប្តូរបានទេ។ គ្រប់គ្រងបន្ទប់ដោយឡែក។';

  @override
  String get saveChanges => 'រក្សាទុកការផ្លាស់ប្តូរ';

  @override
  String get saveBuilding => 'រក្សាទុកអគារ';

  @override
  String get roomChangeFailed => 'កំហុសក្នុងការមិនធ្វើវិញការប្តូរបន្ទប់';

  @override
  String get retryLoadingProfile => 'ព្យាយាមផ្ទុកប្រវត្តិរូបឡើងវិញ';

  @override
  String get failedToLoadProfile => 'បរាជ័យក្នុងការផ្ទុកប្រវត្តិរូប។';

  @override
  String get noLoggedIn => 'អ្នកមិនទាន់បានចូលទេ។';

  @override
  String get notLoggedIn => 'អ្នកមិនទាន់បានចូលទេ។';

  @override
  String get goToOnboarding => 'ទៅកាន់ការចាប់ផ្តើម';

  @override
  String get unknownUser => 'អ្នកប្រើប្រាស់មិនស្គាល់';

  @override
  String get noEmailProvided => 'មិនបានផ្តល់អ៊ីមែល';

  @override
  String get editProfileTapped => 'បានចុចកែប្រែប្រវត្តិរូប';

  @override
  String get signOutSuccess => 'បានចាកចេញដោយជោគជ័យ!';

  @override
  String get signOutFailed => 'បរាជ័យក្នុងការចាកចេញ';

  @override
  String get confirmPasswordLabel => 'បញ្ជាក់ពាក្យសម្ងាត់';

  @override
  String get confirmPasswordHint => 'បញ្ជាក់ពាក្យសម្ងាត់របស់អ្នក';

  @override
  String get manageBuildings => 'គ្រប់គ្រងអគារ & បន្ទប់';

  @override
  String get manageBuildingsDesc => 'គ្រប់គ្រងអគារ បន្ទប់ និងសេវាកម្មរបស់អ្នកយ៉ាងងាយស្រួល។';

  @override
  String get tenantManagement => 'ការគ្រប់គ្រងអ្នកជួល';

  @override
  String get tenantManagementDesc => 'ចាត់តាំងអ្នកជួល និងធ្វើវិក្កយបត្រដោយស្វ័យប្រវត្តិ។';

  @override
  String get paymentTracking => 'ការតាមដានការទូទាត់';

  @override
  String get paymentTrackingDesc => 'តាមដានការទូទាត់យ៉ាងងាយស្រួល - រង់ចាំ, បានបង់, និងហួសកំណត់។';

  @override
  String get automationTools => 'ឧបករណ៍ស្វ័យប្រវត្តិកម្ម';

  @override
  String get automationToolsDesc => 'ធ្វើការងារដោយស្វ័យប្រវត្តិជាមួយការរំលឹកតាម Telegram bot និងការបញ្ចូលទឹកភ្លើង។';

  @override
  String get advancedAnalysis => 'ការវិភាគកម្រិតខ្ពស់';

  @override
  String get financial => 'ហិរញ្ញវត្ថុ';

  @override
  String get errorLoadingCurrencyRate => 'មានកំហុសក្នុងការផ្ទុកអត្រារូបិយប័ណ្ណ';

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
  String get pleaseEnterValidNumber => 'សូមបញ្ចូលលេខដែលត្រឹមត្រូវ';

  @override
  String receiptsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count វិក្កយបត្រ',
    );
    return '$_temp0';
  }

  @override
  String receiptDeletedRoom(String room) {
    return 'វិក្កយបត្រសម្រាប់បន្ទប់ $room ត្រូវបានលុប';
  }

  @override
  String get receiptNotFound => 'រកមិនឃើញវិក្កយបត្រ';

  @override
  String get addReceipt => 'បន្ថែមវិក្កយបត្រ';

  @override
  String deleteReceiptConfirmMsg(String room) {
    return 'តើអ្នកប្រាកដថាចង់លុបវិក្កយបត្រសម្រាប់បន្ទប់ $room ដែរឬទេ?';
  }

  @override
  String get totalRevenue => 'ចំណូលសរុប';

  @override
  String get paid => 'បានបង់';

  @override
  String get remaining => 'នៅសល់';

  @override
  String collectionRate(String rate) {
    return 'អត្រាប្រមូល៖ $rate%';
  }

  @override
  String get tapToSeeDetails => 'ចុចដើម្បីមើលព័ត៌មានលម្អិត';

  @override
  String get utilityAnalysis => 'ការវិភាគទឹកភ្លើង';

  @override
  String get pending => 'រង់ចាំ';

  @override
  String get overdue => 'ហួសកំណត់';

  @override
  String get selectMonth => 'ជ្រើសរើសខែ';

  @override
  String get year => 'ឆ្នាំ៖ ';

  @override
  String get month => 'ខែ៖';

  @override
  String get previousMonth => 'ខែមុន';

  @override
  String get nextMonth => 'ខែបន្ទាប់';

  @override
  String get service => 'សេវាកម្ម';

  @override
  String get emailValidationInvalid => 'សូមបញ្ចូលអ៊ីមែលដែលត្រឹមត្រូវ';

  @override
  String get passwordValidationLength => 'ពាក្យសម្ងាត់ត្រូវតែមានយ៉ាងហោចណាស់ 6 តួអក្សរ';

  @override
  String get passwordsDoNotMatch => 'ពាក្យសម្ងាត់មិនត្រូវគ្នាទេ';

  @override
  String get chooseLanguageTitle => 'ជ្រើសរើសភាសារបស់អ្នក';

  @override
  String get chooseLanguageSubtitle => 'ជ្រើសរើសភាសាដែលអ្នកពេញចិត្ត';

  @override
  String get continueButton => 'បន្ត';

  @override
  String get nextButton => 'បន្ទាប់';

  @override
  String get notificationRemoved => 'ការជូនដំណឹងត្រូវបានដកចេញ';

  @override
  String get notificationsCleared => 'ការជូនដំណឹងទាំងអស់ត្រូវបានសម្អាត';

  @override
  String get noNotifications => 'គ្មានការជូនដំណឹង';

  @override
  String get newReceiptNotification => 'ការជូនដំណឹងវិក្កយបត្រថ្មីនឹងបង្ហាញនៅទីនេះ';

  @override
  String get clearAllNotifications => 'សម្អាតការជូនដំណឹងទាំងអស់?';

  @override
  String get clearNotificationsMessage => 'វានឹងលុបធាតុជូនដំណឹងទាំងអស់។ អ្នកនៅតែអាចមើលវិក្កយបត្រនៅក្នុងផ្ទាំងវិក្កយបត្រ។';

  @override
  String get phoneNumberHint => '010 123 456';

  @override
  String get requestOtp => 'ស្នើសុំ OTP';

  @override
  String get verificationCode => 'លេខកូដបញ្ជាក់';

  @override
  String get enterCodeSentTo => 'សូមបញ្ចូលលេខកូដដែលបានផ្ញើទៅ';

  @override
  String get verify => 'ផ្ទៀងផ្ទាត់';

  @override
  String get didNotReceiveCode => 'មិនទទួលបានលេខកូដ? ';

  @override
  String get resend => 'ផ្ញើម្តងទៀត';

  @override
  String get invalidOtp => 'សូមបញ្ចូលលេខកូដ 6 ខ្ទង់ដែលត្រឹមត្រូវ';

  @override
  String get otpResent => 'OTP ត្រូវបានផ្ញើម្តងទៀត';

  @override
  String get faqs => 'សំណួរដែលសួរញឹកញាប់';

  @override
  String get reportProblem => 'រាយការណ៍បញ្ហា';

  @override
  String get describeProblem => 'ពិពណ៌នាបញ្ហា';

  @override
  String get reportSent => 'របាយការណ៍ត្រូវបានផ្ញើដោយជោគជ័យ';

  @override
  String get send => 'ផ្ញើ';

  @override
  String get changePassword => 'ផ្លាស់ប្តូរពាក្យសម្ងាត់';

  @override
  String get oldPassword => 'ពាក្យសម្ងាត់ចាស់';

  @override
  String get newPassword => 'ពាក្យសម្ងាត់ថ្មី';

  @override
  String get updatePassword => 'កែប្រែពាក្យសម្ងាត់';

  @override
  String get passwordUpdated => 'ពាក្យសម្ងាត់ត្រូវបានកែប្រែដោយជោគជ័យ';

  @override
  String get pleaseEnterPassword => 'សូមបញ្ចូលពាក្យសម្ងាត់';

  @override
  String get passwordTooShort => 'ពាក្យសម្ងាត់ត្រូវតែមានយ៉ាងហោចណាស់ 6 តួអក្សរ';

  @override
  String get paymentSettings => 'ការកំណត់ការទូទាត់';

  @override
  String get paymentSettingsSubtitle => 'កំណត់វិធីសាស្រ្តបើកប្រាក់';

  @override
  String get paymentConfigInfo => 'រៀបចំរបៀបដែលអ្នកចង់ទទួលការទូទាត់ពីអ្នកជួលរបស់អ្នក';

  @override
  String get paymentMethod => 'វិធីសាស្ត្រទូទាត់';

  @override
  String get both => 'ទាំងពីរ';

  @override
  String get none => 'គ្មាន';

  @override
  String get enabledMethods => 'វិធីសាស្ត្រដែលបានបើកដំណើរការ';

  @override
  String get khqrSubtitle => 'ការទូទាត់តាម QR កូដ';

  @override
  String get abaPayWaySubtitle => 'ការទូទាត់តាមធនាគារអនឡាញ';

  @override
  String get bankDetails => 'ព័ត៌មានលម្អិតធនាគារ';

  @override
  String get bankName => 'ឈ្មោះធនាគារ';

  @override
  String get enterBankName => 'ឧ. ធនាគារ ABA';

  @override
  String get accountNumber => 'លេខគណនី';

  @override
  String get enterAccountNumber => 'ឧ. 001122334';

  @override
  String get accountHolderName => 'ឈ្មោះម្ចាស់គណនី';

  @override
  String get enterAccountHolderName => 'ឧ. ចាន់ សុខា';

  @override
  String get pleaseEnterBankName => 'សូមបញ្ចូលឈ្មោះធនាគារ';

  @override
  String get pleaseEnterAccountNumber => 'សូមបញ្ចូលលេខគណនី';

  @override
  String get pleaseEnterAccountHolderName => 'សូមបញ្ចូលឈ្មោះម្ចាស់គណនី';

  @override
  String get savePaymentConfig => 'រក្សាទុកការកំណត់';

  @override
  String get updatePaymentConfig => 'កែប្រែការកំណត់';

  @override
  String get paymentConfigSaved => 'ការកំណត់ការទូទាត់ត្រូវបានរក្សាទុកដោយជោគជ័យ';

  @override
  String get paymentConfigUpdated => 'ការកំណត់ការទូទាត់ត្រូវបានកែប្រែដោយជោគជ័យ';

  @override
  String get failedToLoadPaymentConfig => 'បរាជ័យក្នុងការផ្ទុកការកំណត់ការទូទាត់';

  @override
  String get retry => 'ព្យាយាមម្តងទៀត';

  @override
  String get useOfflineMode => 'Use Offline Mode';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get confirmReceipt => 'Confirm Receipt';

  @override
  String failedToPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get usernameOrPhoneNumber => 'Username or Phone Number';

  @override
  String get khqr => 'KHQR';

  @override
  String get abaPayWay => 'ABA PayWay';

  @override
  String get confirmAndSendPdf => 'Confirm & Send PDF';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get sending => 'Sending...';

  @override
  String get buildingImage => 'រូបភាពអគារ';

  @override
  String get addBuildingImage => 'បន្ថែមរូបភាពអគារ';

  @override
  String get replaceImage => 'ប្ដូររូបភាព';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get addPhoto => 'បន្ថែមរូបភាព';

  @override
  String get deposit => 'ប្រាក់កក់';

  @override
  String get resolved => 'Resolved';

  @override
  String roomWithNumber(Object number) {
    return 'Room $number';
  }

  @override
  String get roomNumber => 'លេខបន្ទប់';

  @override
  String get financialInformation => 'ព័ត៌មានហិរញ្ញវត្ថុ';

  @override
  String get offlineDataLoaded => 'បច្ចុប្បន្នគ្មានអ៊ីនធឺណិត ទិន្នន័យត្រូវបានផ្ទុកពីឧបករណ៍';

  @override
  String get date => 'កាលបរិច្ឆេទ';

  @override
  String get roomOccupancy => 'ការកាន់កាប់បន្ទប់';

  @override
  String get paymentMethods => 'វិធីសាស្ត្រទូទាត់';

  @override
  String get khqrDescription => 'ទទួលការទូទាត់តាមរយៈ KHQR QR code';

  @override
  String get abaPayWayDescription => 'ទទួលការទូទាត់តាមរយៈ ABA PayWay';

  @override
  String get notificationsTitle => 'ការជូនដំណឹង';

  @override
  String get clearAllTooltip => 'សម្អាតទាំងអស់';

  @override
  String get newNotificationsMessage => 'ការជូនដំណឹងថ្មីនឹងបង្ហាញនៅទីនេះ';

  @override
  String get errorLoadingNotifications => 'មានបញ្ហាក្នុងការផ្ទុកការជូនដំណឹង';

  @override
  String get clearAllNotificationsQuestion => 'សម្អាតការជូនដំណឹងទាំងអស់?';

  @override
  String get clearAllNotificationsWarning => 'នេះនឹងលុបការជូនដំណឹងទាំងអស់។ អ្នកនៅតែអាចមើលវិក្កយបត្រនៅក្នុងផ្ទាំងវិក្កយបត្រ។';

  @override
  String get clearAction => 'សម្អាត';
}
