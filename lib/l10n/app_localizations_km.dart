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
  String deleteConfirmMsg(Object building) {
    return 'តើអ្នកពិតជាចង់លុបអគារ $building មែនទេ?';
  }

  @override
  String get cancel => 'បោះបង់';

  @override
  String get delete => 'លុប';

  @override
  String buildingDeleted(Object building) {
    return 'អគារ $building ត្រូវបានលុបដោយជោគជ័យ';
  }

  @override
  String deleteFailed(Object error) {
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
  String get paidStatus => 'បានបង់ប្រាក់';

  @override
  String get pendingStatus => 'មិនទាន់បង់ប្រាក់';

  @override
  String get overdueStatus => 'ហួសកំណត់';

  @override
  String get viewDetail => 'មើលលម្អិត';

  @override
  String get share => 'ចែករំលែក';

  @override
  String get edit => 'កែប្រែ';

  @override
  String get deleteOption => 'លុប';

  @override
  String get undo => 'មិនធ្វើវិញ';

  @override
  String get receiptTitle => 'វិក្កយបត្រ';

  @override
  String get noReceipts => 'មិនមានវិក្កយបត្រ';

  @override
  String get loading => 'កំពុងដំណើរការ...';

  @override
  String get settingsTitle => 'ការកំណត់';

  @override
  String get settings => 'ការកំណត់';

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
  String tenantAdded(Object tenant) {
    return 'បានបន្ថែមអ្នកជួល $tenant ដោយជោគជ័យ';
  }

  @override
  String get tenantAddFailed => 'បរាជ័យក្នុងការបន្ថែមអ្នកជួល';

  @override
  String tenantUpdated(Object tenant) {
    return 'បានកែប្រែព័ត៌មានអ្នកជួល $tenant ដោយជោគជ័យ';
  }

  @override
  String get tenantUpdateFailed => 'បរាជ័យក្នុងការកែប្រែព័ត៌មាន';

  @override
  String tenantDeleted(Object tenant) {
    return 'បានលុបអ្នកជួល $tenant';
  }

  @override
  String get tenantDeleteFailed => 'បរាជ័យក្នុងការលុបអ្នកជួល';

  @override
  String roomChanged(Object tenant, Object room) {
    return 'បានផ្លាស់ប្តូរបន្ទប់សម្រាប់ $tenant ទៅបន្ទប់ $room';
  }

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
  String get building => 'អគារ';

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
  String get all => 'ទាំងអស់';

  @override
  String get errorLoadingBuildings => 'មានបញ្ហាក្នុងការទាញយកអគារ';

  @override
  String get pleaseEnterValue => 'សូមបញ្ចូលតម្លៃ';

  @override
  String get pleaseEnterValidNumber => 'សូមបញ្ចូលលេខត្រឹមត្រូវ';

  @override
  String receiptsCount(num count) {
    return '$count វិក្កយបត្រ';
  }

  @override
  String get totalRevenue => 'ប្រាក់ចំណូលសរុប';

  @override
  String get paid => 'បានបង់ប្រាក់';

  @override
  String get remaining => 'នៅសល់';

  @override
  String collectionRate(Object rate) {
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
  String get water => 'ទឹក';

  @override
  String get electricity => 'អគ្គិសនី';

  @override
  String get room => 'បន្ទប់';

  @override
  String get service => 'សេវាកម្ម';

  @override
  String get emailValidationInvalid => 'សូមបញ្ចូលអ៊ីមែលដែលត្រឹមត្រូវ';

  @override
  String get passwordValidationLength => 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ 6 តួអក្សរ';

  @override
  String get passwordsDoNotMatch => 'ពាក្យសម្ងាត់មិនตรงគ្នាទេ';
}
