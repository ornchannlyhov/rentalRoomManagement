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
  String get historyTab => '历史记录';

  @override
  String get buildingTab => '楼宇';

  @override
  String get tenantTab => '租户';

  @override
  String get settingsTab => '设置';

  @override
  String get detailedAnalysis => '详细分析';

  @override
  String get moneyTab => '财务';

  @override
  String get buildingAnalysisTab => '楼宇';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get signInPrompt => '登录您的账户';

  @override
  String get tenantInformation => '租户信息';

  @override
  String deleteTenantConfirmMsg(String tenant) {
    return '您确定要删除租户 $tenant 吗？';
  }

  @override
  String get report => '报告';

  @override
  String get reports => '报告';

  @override
  String get addReport => '添加报告';

  @override
  String get editReport => '编辑报告';

  @override
  String get deleteReport => '删除报告';

  @override
  String get noReports => '暂无报告';

  @override
  String get reportAddedSuccess => '报告添加成功';

  @override
  String get reportUpdatedSuccess => '报告更新成功';

  @override
  String get reportDeletedSuccess => '报告删除成功';

  @override
  String get deleteReportConfirm => '您确定要删除此报告吗？';

  @override
  String get selectTenant => '请选择租户';

  @override
  String get problemDescription => '问题描述';

  @override
  String get enterProblemDescription => '请输入问题描述';

  @override
  String get noTenant => '无租户';

  @override
  String get optional => '可选';

  @override
  String get reportStatusPending => '待处理';

  @override
  String get reportStatusInProgress => '进行中';

  @override
  String get reportStatusResolved => '已解决';

  @override
  String get reportStatusClosed => '已关闭';

  @override
  String get reportPriorityLow => '低';

  @override
  String get reportPriorityMedium => '中';

  @override
  String get reportPriorityHigh => '高';

  @override
  String get reportLanguageEnglish => '英语';

  @override
  String get reportLanguageKhmer => '高棉语';

  @override
  String get editReceipt => '编辑收据';

  @override
  String get createNewReceipt => '创建新收据';

  @override
  String get noBuildingsPrompt => '没有楼宇。请在创建收据前先创建楼宇。';

  @override
  String get createNewBuilding => '创建新楼宇';

  @override
  String get selectBuilding => '选择楼宇';

  @override
  String get all => '全部';

  @override
  String get selectRoom => '选择房间';

  @override
  String get noOccupiedRooms => '没有已入住的房间';

  @override
  String get pleaseSelectRoom => '请选择房间';

  @override
  String get previousMonthUsage => '上月用量';

  @override
  String get currentMonthUsage => '本月用量';

  @override
  String get waterM3 => '水 (m³)';

  @override
  String get electricityKWh => '电 (kWh)';

  @override
  String get services => '服务';

  @override
  String get selectBuildingFirst => '请先选择楼宇';

  @override
  String get noServicesForBuilding => '该楼宇暂无服务';

  @override
  String get errorLoadingServices => '加载服务出错';

  @override
  String get receiptDetailTitle => '收据详情';

  @override
  String get shareReceipt => '分享收据';

  @override
  String receiptForRoom(Object room) {
    return '$room 房间收据';
  }

  @override
  String get tenantInfo => '租户信息';

  @override
  String tenantName(Object name) {
    return '租户：$name';
  }

  @override
  String get phoneNumber => '电话号码';

  @override
  String get utilityUsage => '水电用量';

  @override
  String get waterPreviousMonth => '水 (上月)';

  @override
  String get waterCurrentMonth => '水 (本月)';

  @override
  String get electricPreviousMonth => '电 (上月)';

  @override
  String get electricCurrentMonth => '电 (本月)';

  @override
  String get paymentBreakdown => '款项明细';

  @override
  String get waterUsage => '用水量';

  @override
  String get totalWaterPrice => '水费总额';

  @override
  String get electricUsage => '用电量';

  @override
  String get totalElectricPrice => '电费总额';

  @override
  String get additionalServices => '附加服务';

  @override
  String get totalServicePrice => '服务费总额';

  @override
  String get roomRent => '房租';

  @override
  String get grandTotal => '总计';

  @override
  String get available => '空闲';

  @override
  String get rented => '已出租';

  @override
  String get editService => '编辑服务';

  @override
  String get createNewService => '创建新服务';

  @override
  String get serviceName => '服务名称';

  @override
  String get serviceNameRequired => '请输入服务名称';

  @override
  String get servicePriceLabel => '服务价格';

  @override
  String get addService => '添加服务';

  @override
  String get currencyServiceUnavailable => '货币服务不可用 – 显示基本美元汇率';

  @override
  String get thankYouForUsingOurService => '感谢您使用我们的服务！';

  @override
  String get currencyConversionFailed => '货币转换失败';

  @override
  String get shareReceiptFailed => '分享收据失败';

  @override
  String get save => '保存';

  @override
  String get errorLoadingBuildings => '加载楼宇出错';

  @override
  String get unknown => '未知';

  @override
  String get menu => '菜单';

  @override
  String get dueDate => '截止日期';

  @override
  String get paidStatus => '已支付';

  @override
  String get pendingStatus => '待处理';

  @override
  String get notes => '备注';

  @override
  String get priorityLabel => '优先级';

  @override
  String get overdueStatus => '逾期';

  @override
  String get status => '状态';

  @override
  String get delete => '删除';

  @override
  String get unknownRoom => '未知房间';

  @override
  String get room => '房间';

  @override
  String get changedTo => '更改为';

  @override
  String get noTenants => '无租户';

  @override
  String get tapToAddNewTenant => '点击 + 添加新租户';

  @override
  String get errorLoadingData => '加载数据出错';

  @override
  String get tryAgain => '重试';

  @override
  String get male => '男';

  @override
  String get changeStatus => '更改状态';

  @override
  String get filterByStatus => '按状态筛选';

  @override
  String get allReports => '所有报告';

  @override
  String get unknownTenant => '未知租户';

  @override
  String reportStatusUpdated(String status) {
    return '报告状态已更新为 $status';
  }

  @override
  String get reportStatusUpdateFailed => '更新报告状态失败';

  @override
  String noFilteredReports(String status) {
    return '没有 $status 报告';
  }

  @override
  String get noFilteredReportsSubtitle => '没有符合所选状态筛选的报告';

  @override
  String get clearFilter => '清除筛选';

  @override
  String deleteReportConfirmFrom(String tenant) {
    return '您确定要删除来自 $tenant 的这份报告吗？';
  }

  @override
  String get reportPriorityUrgent => '紧急';

  @override
  String deleteBuildingWarning(String name) {
    return '您确定要删除 $name 吗？这也将删除所有房间、服务和相关数据。';
  }

  @override
  String get noRoomsSubtitle => '下拉刷新或添加新房间';

  @override
  String get noServicesSubtitle => '下拉刷新或添加新服务';

  @override
  String get noReportsSubtitle => '下拉刷新';

  @override
  String get refresh => '刷新';

  @override
  String get female => '女';

  @override
  String get other => '其他';

  @override
  String get contactInformation => '联系信息';

  @override
  String get roomInformation => '房间信息';

  @override
  String get notAvailable => '不适用';

  @override
  String get rentalPrice => '租金';

  @override
  String get editTenant => '编辑租户';

  @override
  String get createNewTenant => '创建新租户';

  @override
  String get tenantNameLabel => '姓名';

  @override
  String get pleaseEnterTenantName => '请输入租户姓名';

  @override
  String get pleaseEnterPhoneNumber => '请输入电话号码';

  @override
  String get invalidPhoneNumber => '无效的电话号码';

  @override
  String get searchCountry => '搜索国家';

  @override
  String get gender => '性别';

  @override
  String get updateTenant => '更新租户';

  @override
  String get createTenant => '创建租户';

  @override
  String get errorLoadingRooms => '加载房间出错';

  @override
  String get emailLabel => '电子邮件';

  @override
  String get emailHint => '请输入您的电子邮件';

  @override
  String get passwordLabel => '密码';

  @override
  String get passwordHint => '请输入您的密码';

  @override
  String get loginButton => '登录';

  @override
  String get noAccount => '没有账户？';

  @override
  String get registerLink => '注册';

  @override
  String get createAccount => '创建账户';

  @override
  String get signUpPrompt => '注册以开始使用';

  @override
  String get fullNameLabel => '全名';

  @override
  String get fullNameHint => '请输入您的全名';

  @override
  String get registerButton => '注册';

  @override
  String get haveAccount => '已有账户？';

  @override
  String get loginLink => '登录';

  @override
  String get buildingsTitle => '楼宇';

  @override
  String get searchBuildingHint => '搜索楼宇...';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get buildings => '楼宇';

  @override
  String get searchBuildings => '搜索楼宇...';

  @override
  String get noBuildingsFound => '未找到楼宇';

  @override
  String get noBuildingsAvailable => '暂无楼宇';

  @override
  String get tryDifferentKeywords => '尝试使用不同的关键词搜索';

  @override
  String get tapPlusToAddBuilding => '点击 + 添加新楼宇';

  @override
  String get loading => '加载中...';

  @override
  String deleteBuildingConfirmMsg(Object name) {
    return '您确定要删除楼宇“$name”吗？';
  }

  @override
  String get cancel => '取消';

  @override
  String buildingDeletedSuccess(Object name) {
    return '楼宇“$name”删除成功';
  }

  @override
  String buildingDeleted(Object name) {
    return '楼宇“$name”已删除';
  }

  @override
  String buildingDeleteFailed(Object error) {
    return '删除楼宇失败：$error';
  }

  @override
  String get rentPriceLabel => '月租金';

  @override
  String get electricPricePerKwh => '电价 (1 kWh)';

  @override
  String get waterPricePerCubicMeter => '水价 (1 m³)';

  @override
  String get rentPricePerMonthLabel => '月租金';

  @override
  String rentPricePerMonth(Object price) {
    return '$price\$/ 月';
  }

  @override
  String passKey(Object key) {
    return '钥匙：$key';
  }

  @override
  String get perMonth => '/ 月';

  @override
  String get electricity => '电';

  @override
  String get water => '水';

  @override
  String get viewDetails => '查看详情';

  @override
  String get edit => '编辑';

  @override
  String ofTotal(Object total) {
    return '/ $total';
  }

  @override
  String deleteConfirmMsg(String building) {
    return '您确定要删除楼宇 $building 吗？';
  }

  @override
  String deleteFailed(String error) {
    return '删除楼宇失败：$error';
  }

  @override
  String get noBuildings => '无楼宇';

  @override
  String get noBuildingsSearch => '未找到楼宇';

  @override
  String get addNewBuildingHint => '点击 + 添加新楼宇';

  @override
  String get tryDifferentKeyword => '尝试不同的关键词';

  @override
  String get oldDataTitle => '历史记录';

  @override
  String get searchReceiptHint => '搜索收据...';

  @override
  String get viewDetail => '查看详情';

  @override
  String get share => '分享';

  @override
  String get deleteOption => '删除';

  @override
  String get undo => '撤销';

  @override
  String get receiptTitle => '收据';

  @override
  String get noReceipts => '无收据';

  @override
  String get settingsTitle => '设置';

  @override
  String get settings => '设置';

  @override
  String get changeRoom => '更换房间';

  @override
  String get building => '楼宇';

  @override
  String roomNumberLabel(Object number) {
    return '$number号房';
  }

  @override
  String roomStatus(Object status) {
    return '状态：$status';
  }

  @override
  String rentPrice(Object price) {
    return '租金：$price\$';
  }

  @override
  String get noRoom => '无房间';

  @override
  String get accountSettings => '账户设置';

  @override
  String get accountSettingsSubtitle => '隐私、安全、更改密码';

  @override
  String get privacySecurity => '隐私、安全、更改密码';

  @override
  String get subscriptions => '订阅';

  @override
  String get subscriptionsSubtitle => '套餐、支付方式';

  @override
  String get plansPayments => '套餐、支付方式';

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
  String get helpAndSupportSubtitle => '常见问题、联系我们';

  @override
  String get faqContact => '常见问题、联系我们';

  @override
  String get about => '关于';

  @override
  String get receiptDeleted => '收据删除成功';

  @override
  String get receiptRestored => '收据恢复成功';

  @override
  String noReceiptsForMonth(String month) {
    return '$month 无收据';
  }

  @override
  String get noReceiptsForBuilding => '该楼宇暂无收据';

  @override
  String noSearchResults(String query) {
    return '没有找到 \"$query\" 的搜索结果';
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
  String get tenantAddFailed => '添加租户时出错';

  @override
  String tenantUpdated(String tenant) {
    return '租户 $tenant 更新成功';
  }

  @override
  String get tenantUpdateFailed => '更新租户时出错';

  @override
  String tenantDeleted(String tenant) {
    return '租户 $tenant 已删除';
  }

  @override
  String get tenantDeleteFailed => '删除租户时出错';

  @override
  String roomChanged(String tenant, String room) {
    return '$tenant 的房间已更改为 $room';
  }

  @override
  String priceValue(Object price) {
    return '价格：$price\$';
  }

  @override
  String get rooms => '房间';

  @override
  String servicePrice(Object price) {
    return '$price\$';
  }

  @override
  String get addRoom => '添加房间';

  @override
  String get noRooms => '无房间';

  @override
  String get noServices => '无服务';

  @override
  String get pullToRefresh => '下拉刷新';

  @override
  String roomAddedSuccess(Object number) {
    return '房间 \"$number\" 添加成功';
  }

  @override
  String roomUpdatedSuccess(Object number) {
    return '房间 \"$number\" 更新成功';
  }

  @override
  String roomDeletedSuccess(Object number) {
    return '房间 \"$number\" 删除成功';
  }

  @override
  String serviceAddedSuccess(Object name) {
    return '服务 \"$name\" 添加成功';
  }

  @override
  String serviceUpdatedSuccess(Object name) {
    return '服务 \"$name\" 更新成功';
  }

  @override
  String serviceDeletedSuccess(Object name) {
    return '服务 \"$name\" 删除成功';
  }

  @override
  String buildingUpdatedSuccess(Object name) {
    return '楼宇 \"$name\" 更新成功';
  }

  @override
  String get deleteBuilding => '删除楼宇';

  @override
  String deleteBuildingConfirm(Object name) {
    return '您要删除楼宇 \"$name\" 吗？';
  }

  @override
  String get deleteRoom => '删除房间';

  @override
  String deleteRoomConfirm(Object number) {
    return '您要删除房间 \"$number\" 吗？';
  }

  @override
  String get deleteService => '删除服务';

  @override
  String deleteServiceConfirm(Object name) {
    return '您要删除服务 \"$name\" 吗？';
  }

  @override
  String get errorOccurred => '发生错误';

  @override
  String get addNewBuilding => '添加新楼宇';

  @override
  String get editBuilding => '编辑楼宇';

  @override
  String get buildingName => '楼宇名称';

  @override
  String get buildingNameRequired => '请输入楼宇名称。';

  @override
  String get roomCount => '房间数量';

  @override
  String get currentRoomCount => '当前房间数量';

  @override
  String get roomCountRequired => '请输入房间数量。';

  @override
  String get roomCountInvalid => '请输入有效的房间数量。';

  @override
  String get roomCountEditNote => '房间数量无法更改。请单独管理房间。';

  @override
  String get saveChanges => '保存更改';

  @override
  String get saveBuilding => '保存楼宇';

  @override
  String get roomChangeFailed => '撤销房间更改时出错';

  @override
  String get retryLoadingProfile => '重试加载个人资料';

  @override
  String get failedToLoadProfile => '无法加载个人资料。';

  @override
  String get noLoggedIn => '您尚未登录。';

  @override
  String get notLoggedIn => '您尚未登录。';

  @override
  String get goToOnboarding => '前往引导页';

  @override
  String get unknownUser => '未知用户';

  @override
  String get noEmailProvided => '未提供电子邮件';

  @override
  String get editProfileTapped => '点击了编辑个人资料';

  @override
  String get signOutSuccess => '退出登录成功！';

  @override
  String get signOutFailed => '退出登录失败';

  @override
  String get confirmPasswordLabel => '确认密码';

  @override
  String get confirmPasswordHint => '确认您的密码';

  @override
  String get manageBuildings => '管理楼宇和房间';

  @override
  String get manageBuildingsDesc => '通过直观的界面轻松管理您的楼宇、房间和服务。';

  @override
  String get tenantManagement => '租户管理';

  @override
  String get tenantManagementDesc => '只需点击几下即可分配租户并自动生成收据。';

  @override
  String get paymentTracking => '付款追踪';

  @override
  String get paymentTrackingDesc => '轻松追踪付款 - 待处理、已支付和逾期状态一目了然。';

  @override
  String get automationTools => '自动化工具';

  @override
  String get automationToolsDesc => '使用 Telegram 机器人提醒和水电输入自动化工作。';

  @override
  String get advancedAnalysis => '高级分析';

  @override
  String get financial => '财务';

  @override
  String get errorLoadingCurrencyRate => '加载汇率出错';

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
  String get pleaseEnterValue => '请输入数值';

  @override
  String get pleaseEnterValidNumber => '请输入有效的数字';

  @override
  String receiptsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张收据',
    );
    return '$_temp0';
  }

  @override
  String receiptDeletedRoom(String room) {
    return '$room 房间的收据已删除';
  }

  @override
  String get receiptNotFound => '未找到收据';

  @override
  String get addReceipt => '添加收据';

  @override
  String deleteReceiptConfirmMsg(String room) {
    return '您确定要删除 $room 房间的收据吗？';
  }

  @override
  String get totalRevenue => '总收入';

  @override
  String get paid => '已支付';

  @override
  String get remaining => '剩余';

  @override
  String collectionRate(String rate) {
    return '收款率：$rate%';
  }

  @override
  String get tapToSeeDetails => '点击查看详情';

  @override
  String get utilityAnalysis => '水电分析';

  @override
  String get pending => '待处理';

  @override
  String get overdue => '逾期';

  @override
  String get selectMonth => '选择月份';

  @override
  String get year => '年份：';

  @override
  String get month => '月份：';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get service => '服务';

  @override
  String get emailValidationInvalid => '请输入有效的电子邮件';

  @override
  String get passwordValidationLength => '密码长度必须至少为 6 个字符';

  @override
  String get passwordsDoNotMatch => '密码不匹配';

  @override
  String get chooseLanguageTitle => '选择您的语言';

  @override
  String get chooseLanguageSubtitle => '选择您的首选语言';

  @override
  String get continueButton => '继续';

  @override
  String get nextButton => '下一步';

  @override
  String get notificationRemoved => '通知已移除';

  @override
  String get notificationsCleared => '所有通知已清除';

  @override
  String get noNotifications => '暂无通知';

  @override
  String get newReceiptNotification => '新收据通知将显示在这里';

  @override
  String get clearAllNotifications => '清除所有通知？';

  @override
  String get clearNotificationsMessage => '这将移除所有通知项。您仍然可以在收据选项卡中查看收据。';

  @override
  String get phoneNumberHint => '010 123 456';

  @override
  String get requestOtp => '请求验证码';

  @override
  String get verificationCode => '验证码';

  @override
  String get enterCodeSentTo => '请输入发送至以下号码的验证码';

  @override
  String get verify => '验证';

  @override
  String get didNotReceiveCode => '没有收到验证码？';

  @override
  String get resend => '重新发送';

  @override
  String get invalidOtp => '请输入有效的 6 位验证码';

  @override
  String get otpResent => '验证码已重新发送';

  @override
  String get faqs => '常见问题';

  @override
  String get reportProblem => '报告问题';

  @override
  String get describeProblem => '描述问题';

  @override
  String get reportSent => '报告发送成功';

  @override
  String get send => '发送';

  @override
  String get changePassword => '更改密码';

  @override
  String get oldPassword => '旧密码';

  @override
  String get newPassword => '新密码';

  @override
  String get updatePassword => '更新密码';

  @override
  String get passwordUpdated => '密码更新成功';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String get passwordTooShort => '密码长度必须至少为 6 个字符';

  @override
  String get paymentSettings => '支付设置';

  @override
  String get paymentSettingsSubtitle => '配置收款方式';

  @override
  String get paymentConfigInfo => '设置您希望如何从租户处接收款项';

  @override
  String get paymentMethod => '支付方式';

  @override
  String get both => '全部启用';

  @override
  String get none => '无';

  @override
  String get enabledMethods => '已启用的方式';

  @override
  String get khqrSubtitle => '二维码支付 (KHQR)';

  @override
  String get abaPayWaySubtitle => '网上银行支付';

  @override
  String get bankDetails => '银行详情';

  @override
  String get bankName => '银行名称';

  @override
  String get enterBankName => '例如：ABA 银行';

  @override
  String get accountNumber => '银行账号';

  @override
  String get enterAccountNumber => '例如：001122334';

  @override
  String get accountHolderName => '开户人姓名';

  @override
  String get enterAccountHolderName => '例如：John Doe';

  @override
  String get pleaseEnterBankName => '请输入银行名称';

  @override
  String get pleaseEnterAccountNumber => '请输入银行账号';

  @override
  String get pleaseEnterAccountHolderName => '请输入开户人姓名';

  @override
  String get savePaymentConfig => '保存配置';

  @override
  String get updatePaymentConfig => '更新配置';

  @override
  String get paymentConfigSaved => '支付配置保存成功';

  @override
  String get paymentConfigUpdated => '支付配置更新成功';

  @override
  String get failedToLoadPaymentConfig => '无法加载支付配置';

  @override
  String get retry => '重试';

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
  String get buildingImage => '楼宇图片';

  @override
  String get addBuildingImage => '添加楼宇图片';

  @override
  String get replaceImage => '更换图片';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get addPhoto => '添加照片';

  @override
  String get deposit => '押金';

  @override
  String get resolved => 'Resolved';

  @override
  String roomWithNumber(Object number) {
    return 'Room $number';
  }

  @override
  String get roomNumber => '房间号';

  @override
  String get financialInformation => '财务信息';

  @override
  String get offlineDataLoaded => '当前离线，数据已从设备加载';

  @override
  String get date => '日期';

  @override
  String get roomOccupancy => '房间入住率';

  @override
  String get paymentMethods => '支付方式';

  @override
  String get khqrDescription => '通过KHQR二维码接受付款';

  @override
  String get abaPayWayDescription => '通过ABA PayWay接受付款';

  @override
  String get notificationsTitle => '通知';

  @override
  String get clearAllTooltip => '清除所有';

  @override
  String get newNotificationsMessage => '新通知将显示在这里';

  @override
  String get errorLoadingNotifications => '加载通知出错';

  @override
  String get clearAllNotificationsQuestion => '清除所有通知？';

  @override
  String get clearAllNotificationsWarning => '这将删除所有通知项目。您仍然可以在“收据”选项卡中查看收据。';

  @override
  String get clearAction => '清除';

  @override
  String get iAgreeToThe => '我同意';

  @override
  String get and => '和';

  @override
  String get pleaseAcceptTerms => '请接受服务条款和隐私政策以继续';
}
