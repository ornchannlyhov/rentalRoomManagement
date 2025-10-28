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
  String get welcomeBack => 'សូមស្វាគមន៍ត្រឡប់មកវិញ';

  @override
  String get signInPrompt => 'ចូលទៅកាន់គណនីរបស់អ្នក';

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
  String get noAccount => 'មិនមានគណនីមែនទេ?';

  @override
  String get registerLink => 'ចុះឈ្មោះ';

  @override
  String get createAccount => 'បង្កើតគណនី';

  @override
  String get signUpPrompt => 'ចុះឈ្មោះដើម្បីចាប់ផ្តើម';

  @override
  String get fullNameLabel => 'ឈ្មោះពេញ';

  @override
  String get fullNameHint => 'បញ្ចូលឈ្មោះពេញរបស់អ្នក';

  @override
  String get registerButton => 'ចុះឈ្មោះ';

  @override
  String get haveAccount => 'មានគណនីរួចហើយមែនទេ?';

  @override
  String get loginLink => 'ចូល';

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
    return 'អគារ $building ត្រូវបានលុបជោគជ័យ';
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
  String get tryDifferentKeyword => 'សូមព្យាយាមស្វែងរកជាមួយពាក្យគន្លឹះផ្សេង';

  @override
  String get oldDataTitle => 'ទិន្នន័យចាស់';

  @override
  String get searchReceiptHint => 'ស្វែងរកបង្កាន់ដៃ...';

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
  String get loading => 'កំពុងដំណើការ...';

  @override
  String get settingsTitle => 'ការកំណត់';

  @override
  String get accountSettings => 'ការកំណត់គណនី';

  @override
  String get privacySecurity => 'ភាពឯកជន សុវត្ថិភាព កែប្រែលេខសម្ងាត់';

  @override
  String get subscriptions => 'ការជាវ';

  @override
  String get plansPayments => 'ផែនការនិងវិធីសាស្ត្រទូទាត់';

  @override
  String get appearance => 'រូបរាងកម្មវិធី';

  @override
  String get darkMode => 'ម៉ូដងងឹត';

  @override
  String get lightMode => 'ម៉ូដពន្លឺ';

  @override
  String get systemDefault => 'លំនាំប្រព័ន្ធ';

  @override
  String get language => 'ភាសា';

  @override
  String get helpSupport => 'ជំនួយ';

  @override
  String get faqContact => 'សំណួរញឹកញាប់, ទំនាក់ទំនងយើងខ្ញុំ'; 

  @override
  String get about => 'អំពីកម្មវិធី';

  @override
  String get version => 'កំណែ 1.2.3';

  @override
  String get signOut => 'ចាកចេញ';

  @override
  String get signOutConfirm => 'តើអ្នកពិតជាចង់ចេញពីប្រព័ន្ធមែនទេ?';

  @override
  String get selectLanguage => 'ជ្រើសរើសភាសា';

  @override
  String get premiumMember => 'សមាជិកព្រីម្យូម';

  @override
  String get tenantsTitle => 'អ្នកជួល';

  @override
  String get searchTenantHint => 'ស្វែងរកអ្នកជួល...';

  @override
  String tenantAdded(Object tenant) {
    return 'បានបន្ថែមអ្នកជួល $tenant ដោយជោគជ័យ';
  }

  @override
  String get tenantAddFailed => 'មានបញ្ហាក្នុងការបន្ថែមអ្នកជួល';

  @override
  String tenantUpdated(Object tenant) {
    return 'បានកែប្រែព័ត៌មានអ្នកជួល $tenant ដោយជោគជ័យ';
  }

  @override
  String get tenantUpdateFailed => 'មានបញ្ហាក្នុងការកែប្រែព័ត៌មាន';

  @override
  String tenantDeleted(Object tenant) {
    return 'បានលុបអ្នកជួល $tenant';
  }

  @override
  String get tenantDeleteFailed => 'មានបញ្ហាក្នុងការលុបអ្នកជួល';

  @override
  String roomChanged(Object tenant, Object room) {
    return 'បានផ្លាស់ប្តូរបន្ទប់សម្រាប់ $tenant ទៅបន្ទប់ $room';
  }

  @override
  String get roomChangeFailed => 'មានបញ្ហាក្នុងការត្រឡប់វិញ';

  @override
  String get retryLoadingProfile => 'ព្យាយាមផ្ទុកប្រវត្តិឡើងវិញ';

  @override
  String get noLoggedIn => 'អ្នកមិនបានចូលគណនីទេ។';

  @override
  String get goToOnboarding => 'ទៅកាន់ទំព័រណែនាំ';

  @override
  String get unknownUser => 'អ្នកប្រើដែលមិនស្គាល់';

  @override
  String get noEmailProvided => 'មិនមានអ៊ីមែលផ្តល់ឱ្យ';

  @override
  String get editProfileTapped => 'បានចុចកែប្រែប្រវត្តិ';

  @override
  String get signOutSuccess => 'ចេញពីប្រព័ន្ធដោយជោគជ័យ!';

  @override
  String get signOutFailed => 'បរាជ័យក្នុងការចេញពីប្រព័ន្ធ';

  @override
  String get confirmPasswordLabel => 'បញ្ជាក់លេខសម្ងាត់';

  @override
  String get confirmPasswordHint => 'បញ្ជាក់លេខសម្ងាត់របស់អ្នក';

  @override
  String get manageBuildings => 'គ្រប់គ្រងអគារ និងបន្ទប់';

  @override
  String get manageBuildingsDesc => 'គ្រប់គ្រងអគារ បន្ទប់ និងសេវាកម្មរបស់អ្នកយ៉ាងងាយស្រួលជាមួយផ្ទាំងគ្រប់គ្រងរបស់យើង។';

  @override
  String get tenantManagement => 'ការគ្រប់គ្រងអ្នកជួល';

  @override
  String get tenantManagementDesc => 'ចាត់ចែងអ្នកជួល និងធ្វើឱ្យស្វ័យប្រវត្តិវិក្កយបត្រដោយការប៉ះប៉ះបន្តិចប៉ុណ្ណោះ។';

  @override
  String get paymentTracking => 'ការតាមដានការទូទាត់';

  @override
  String get paymentTrackingDesc => 'តាមដានការទូទាត់យ៉ាងងាយស្រួល - ស្ថានភាពរង់ចាំ បានបង់ និងហួសកំណត់ក្នុងពេលឡើង។';

  @override
  String get automationTools => 'ឧបករណ៍ធ្វើឱ្យស្វ័យប្រវត្តិ';

  @override
  String get automationToolsDesc => 'ធ្វើឱ្យការងារស្វ័យប្រវត្តិជាមួយការរំលឹកប៊ូត Telegram និងការបញ្ចូលឧបករណ៍។';
}
