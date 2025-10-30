// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get receiptTab => '收据';

  @override
  String get historyTab => '旧数据';

  @override
  String get buildingTab => '建筑物';

  @override
  String get tenantTab => '租户';

  @override
  String get settingsTab => '设置';

  @override
  String get detailedAnalysis => '详细分析';

  @override
  String get moneyTab => '金钱';

  @override
  String get buildingAnalysisTab => '建筑物';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get signInPrompt => '登录您的帐户';

  @override
  String get tenantInformation => '租户信息';

  @override
  String deleteTenantConfirmMsg(String tenant) {
    return '您确定要删除租户 $tenant 吗？';
  }

  @override
  String get noTenants => '没有租户';

  @override
  String get tapToAddNewTenant => '点击 + 添加新租户';

  @override
  String get errorLoadingData => '加载数据时出错';

  @override
  String get tryAgain => '重试';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get other => '其他';

  @override
  String get contactInformation => '联系信息';

  @override
  String get roomInformation => '房间信息';

  @override
  String get notAvailable => '不可用';

  @override
  String get rentalPrice => '租金';

  @override
  String get editTenant => '编辑租户';

  @override
  String get createNewTenant => '创建新租户';

  @override
  String get selectBuilding => '选择建筑物';

  @override
  String get tenantName => '租户姓名';

  @override
  String get pleaseEnterTenantName => '请输入租户姓名';

  @override
  String get pleaseEnterPhoneNumber => '请输入电话号码';

  @override
  String get invalidPhoneNumber => '电话号码无效';

  @override
  String get searchCountry => '搜索国家';

  @override
  String get pleaseSelectRoom => '请选择房间';

  @override
  String get gender => '性别';

  @override
  String get updateTenant => '更新租户';

  @override
  String get createTenant => '创建租户';

  @override
  String get errorLoadingRooms => '加载房间时出错';

  @override
  String get emailLabel => '电子邮件';

  @override
  String get emailHint => '输入您的电子邮件';

  @override
  String get passwordLabel => '密码';

  @override
  String get passwordHint => '输入您的密码';

  @override
  String get loginButton => '登录';

  @override
  String get noAccount => '没有帐户？';

  @override
  String get registerLink => '注册';

  @override
  String get createAccount => '创建帐户';

  @override
  String get signUpPrompt => '注册开始使用';

  @override
  String get fullNameLabel => '全名';

  @override
  String get fullNameHint => '输入您的全名';

  @override
  String get registerButton => '注册';

  @override
  String get haveAccount => '已有帐户？';

  @override
  String get loginLink => '登录';

  @override
  String get buildingsTitle => '建筑物';

  @override
  String get searchBuildingHint => '搜索建筑物...';

  @override
  String get confirmDelete => '确认删除';

  @override
  String deleteConfirmMsg(String building) {
    return '您确定要删除建筑物 $building 吗？';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String buildingDeleted(String building) {
    return '建筑物 $building 删除成功';
  }

  @override
  String deleteFailed(String error) {
    return '删除建筑物失败：$error';
  }

  @override
  String get noBuildings => '没有建筑物';

  @override
  String get noBuildingsSearch => '未找到建筑物';

  @override
  String get addNewBuildingHint => '点击 + 添加新建筑物';

  @override
  String get tryDifferentKeyword => '尝试不同的关键字';

  @override
  String get oldDataTitle => '旧数据';

  @override
  String get searchReceiptHint => '搜索收据...';

  @override
  String get paidStatus => '已支付';

  @override
  String get pendingStatus => '待处理';

  @override
  String get overdueStatus => '逾期';

  @override
  String get viewDetail => '查看详情';

  @override
  String get share => '分享';

  @override
  String get edit => '编辑';

  @override
  String get deleteOption => '删除';

  @override
  String get undo => '撤销';

  @override
  String get receiptTitle => '收据';

  @override
  String get noReceipts => '没有收据';

  @override
  String get loading => '加载中...';

  @override
  String get settingsTitle => '设置';

  @override
  String get settings => '设置';

  @override
  String get changeRoom => '更换房间';

  @override
  String get viewDetails => '查看详情';

  @override
  String get building => '建筑物';

  @override
  String get roomNumber => '房间号';

  @override
  String get phoneNumber => '电话号码';

  @override
  String get noRoom => '没有房间';

  @override
  String get unknownRoom => '未知房间';

  @override
  String get accountSettings => '帐户设置';

  @override
  String get accountSettingsSubtitle => '隐私、安全、更改密码';

  @override
  String get privacySecurity => '隐私、安全、更改密码';

  @override
  String get subscriptions => '订阅';

  @override
  String get subscriptionsSubtitle => '计划、支付方式';

  @override
  String get plansPayments => '计划和支付方式';

  @override
  String get appearance => '外观';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get systemDefault => '系统默认';

  @override
  String get language => '语言';

  @override
  String get khmer => '高棉语';

  @override
  String get english => '英语';

  @override
  String get chinese => '中文';

  @override
  String get helpAndSupport => '帮助与支持';

  @override
  String get helpAndSupportSubtitle => '常见问题与联系我们';

  @override
  String get faqContact => '常见问题与联系我们';

  @override
  String get about => '关于';

  @override
  String get receiptDeleted => '收据删除成功';

  @override
  String get receiptRestored => '收据恢复成功';

  @override
  String noReceiptsForMonth(String month) {
    return '$month 没有收据';
  }

  @override
  String get noReceiptsForBuilding => '此建筑物没有收据';

  @override
  String noSearchResults(String query) {
    return '未找到 \"$query\" 的搜索结果';
  }

  @override
  String receiptStatusChanged(String status) {
    return '收据状态已更改为 $status';
  }

  @override
  String version(String versionNumber) {
    return '版本 $versionNumber';
  }

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirm => '您确定要退出登录吗？';

  @override
  String get signOutConfirmation => '您确定要退出登录吗？';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get premiumMember => '高级会员';

  @override
  String get tenantsTitle => '租户';

  @override
  String get searchTenantHint => '搜索租户...';

  @override
  String tenantAdded(String tenant) {
    return '租户 $tenant 添加成功';
  }

  @override
  String get tenantAddFailed => '添加租户失败';

  @override
  String tenantUpdated(String tenant) {
    return '租户 $tenant 更新成功';
  }

  @override
  String get tenantUpdateFailed => '更新租户失败';

  @override
  String tenantDeleted(String tenant) {
    return '租户 $tenant 已删除';
  }

  @override
  String get tenantDeleteFailed => '删除租户失败';

  @override
  String roomChanged(String tenant, String room) {
    return '$tenant 的房间已更改为 $room';
  }

  @override
  String get roomChangeFailed => '更改房间失败';

  @override
  String get retryLoadingProfile => '重试加载资料';

  @override
  String get failedToLoadProfile => '加载资料失败';

  @override
  String get noLoggedIn => '您尚未登录。';

  @override
  String get notLoggedIn => '您尚未登录。';

  @override
  String get goToOnboarding => '前往使用指南';

  @override
  String get unknownUser => '未知用户';

  @override
  String get noEmailProvided => '未提供电子邮件';

  @override
  String get editProfileTapped => '点击编辑资料';

  @override
  String get signOutSuccess => '退出登录成功！';

  @override
  String get signOutFailed => '退出登录失败';

  @override
  String get confirmPasswordLabel => '确认密码';

  @override
  String get confirmPasswordHint => '确认您的密码';

  @override
  String get manageBuildings => '管理建筑物和房间';

  @override
  String get manageBuildingsDesc => '使用我们的直观界面轻松管理您的建筑物、房间和服务。';

  @override
  String get tenantManagement => '租户管理';

  @override
  String get tenantManagementDesc => '轻松分配租户并自动生成收据。';

  @override
  String get paymentTracking => '支付跟踪';

  @override
  String get paymentTrackingDesc => '轻松跟踪支付状态 - 待处理、已支付和逾期。';

  @override
  String get automationTools => '自动化工具';

  @override
  String get automationToolsDesc => '使用 Telegram 提醒和实用工具实现自动化工作。';

  @override
  String get advancedAnalysis => '高级分析';

  @override
  String get financial => '财务';

  @override
  String get errorLoadingCurrencyRate => '加载汇率时出错';

  @override
  String get january => '一月';

  @override
  String get february => '二月';

  @override
  String get march => '三月';

  @override
  String get april => '四月';

  @override
  String get may => '五月';

  @override
  String get june => '六月';

  @override
  String get july => '七月';

  @override
  String get august => '八月';

  @override
  String get september => '九月';

  @override
  String get october => '十月';

  @override
  String get november => '十一月';

  @override
  String get december => '十二月';

  @override
  String get orSignOut => '或退出登录';

  @override
  String get all => '全部';

  @override
  String get errorLoadingBuildings => '加载建筑物时出错';

  @override
  String get pleaseEnterValue => '请输入一个值';

  @override
  String get pleaseEnterValidNumber => '请输入有效的数字';

  @override
  String receiptsCount(num count) {
    return '$count 张收据';
  }

  @override
  String get totalRevenue => '总收入';

  @override
  String get paid => '已支付';

  @override
  String get remaining => '剩余';

  @override
  String collectionRate(String rate) {
    return '收款率: $rate%';
  }

  @override
  String get tapToSeeDetails => '点击查看详情';

  @override
  String get utilityAnalysis => '水电费分析';

  @override
  String get pending => '待处理';

  @override
  String get overdue => '已逾期';

  @override
  String get selectMonth => '选择月份';

  @override
  String get year => '年份: ';

  @override
  String get month => '月份:';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get water => '水费';

  @override
  String get electricity => '电费';

  @override
  String get room => '房间';

  @override
  String get service => '服务费';

  @override
  String get emailValidationInvalid => '请输入有效的电子邮件';

  @override
  String get passwordValidationLength => '密码长度至少为 6 个字符';

  @override
  String get passwordsDoNotMatch => '密码不匹配';
}
