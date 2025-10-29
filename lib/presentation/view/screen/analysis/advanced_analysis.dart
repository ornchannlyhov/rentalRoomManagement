import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/data/repositories/currency_repositoy.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/analysis/widgets/building_analysis_tab.dart';
import 'package:joul_v2/presentation/view/screen/analysis/widgets/financial_overview_tab.dart';

class AdvancedAnalysisScreen extends StatefulWidget {
  final List<Receipt> receipts;
  final List<dynamic> buildings;
  final String? selectedBuildingId;

  const AdvancedAnalysisScreen({
    super.key,
    required this.receipts,
    required this.buildings,
    this.selectedBuildingId,
  });

  @override
  State<AdvancedAnalysisScreen> createState() => _AdvancedAnalysisScreenState();
}

class _AdvancedAnalysisScreenState extends State<AdvancedAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCurrency = 'USD';
  Map<String, double> _currencyRates = {};
  bool _isLoadingRates = true;

  DateTime _selectedMonth = DateTime.now();
  List<Receipt> _filteredReceipts = [];

  final Set<String> _expandedBuildings = <String>{};

  List<String> _getMonthNames(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.january,
      localizations.february,
      localizations.march,
      localizations.april,
      localizations.may,
      localizations.june,
      localizations.july,
      localizations.august,
      localizations.september,
      localizations.october,
      localizations.november,
      localizations.december,
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrencyRates();
    _filterReceiptsByMonth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencyRates() async {
    try {
      final rates = await CurrencyService.getExchangeRates();
      setState(() {
        _currencyRates = rates;
        _isLoadingRates = false;
      });
    } catch (e) {
      GlobalSnackBar.show(
          // ignore: use_build_context_synchronously
          message: AppLocalizations.of(context)!.errorLoadingCurrencyRate,
          isError: true,
          context: context);
      setState(() {
        _isLoadingRates = false;
      });
    }
  }

  void _updateSelectedMonth(DateTime newMonth) {
    setState(() {
      _selectedMonth = newMonth;
    });
    _filterReceiptsByMonth();
  }

  void _filterReceiptsByMonth() {
    setState(() {
      _filteredReceipts = widget.receipts.where((receipt) {
        return receipt.date.year == _selectedMonth.year &&
            receipt.date.month == _selectedMonth.month;
      }).toList();
    });
  }

  double _convertAmount(double amount) {
    if (_selectedCurrency == 'USD' || _currencyRates.isEmpty) return amount;
    return amount * (_currencyRates[_selectedCurrency] ?? 1.0);
  }

  String _formatCurrency(double amount) {
    return CurrencyService.formatCurrency(
        _convertAmount(amount), _selectedCurrency);
  }

  // Financial calculations using filtered receipts
  double _getSumOfReceiptsByStatus(
      List<Receipt> receipts, PaymentStatus? status) {
    return receipts
        .where((receipt) => status == null || receipt.paymentStatus == status)
        .fold(0.0, (sum, receipt) => sum + receipt.totalPrice);
  }

  Map<String, double> _getBuildingFinancialAnalysis(String buildingId) {
    final buildingReceipts = _filteredReceipts
        .where((receipt) => receipt.room?.building?.id == buildingId)
        .toList();

    return {
      'total': _getSumOfReceiptsByStatus(buildingReceipts, null),
      'paid': _getSumOfReceiptsByStatus(buildingReceipts, PaymentStatus.paid),
      'pending':
          _getSumOfReceiptsByStatus(buildingReceipts, PaymentStatus.pending),
      'overdue':
          _getSumOfReceiptsByStatus(buildingReceipts, PaymentStatus.overdue),
      'receiptsCount': buildingReceipts.length.toDouble(),
    };
  }

  Map<String, double> _getBuildingUtilityAnalysis(String buildingId) {
    final buildingReceipts = _filteredReceipts
        .where((receipt) => receipt.room?.building?.id == buildingId)
        .toList();

    double totalWaterCost = 0;
    double totalElectricCost = 0;
    double totalRoomCost = 0;
    double totalServiceCost = 0;

    for (final receipt in buildingReceipts) {
      totalWaterCost += receipt.waterPrice;
      totalElectricCost += receipt.electricPrice;
      totalRoomCost += receipt.roomPrice;
      totalServiceCost += receipt.totalServicePrice;
    }

    return {
      'water': totalWaterCost,
      'electric': totalElectricCost,
      'room': totalRoomCost,
      'service': totalServiceCost,
    };
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final monthNames = _getMonthNames(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(localizations.advancedAnalysis),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 18),
                    const SizedBox(width: 6),
                    Text(localizations.financial,
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.apartment, size: 18),
                    const SizedBox(width: 6),
                    Text(localizations.building,
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FinancialOverviewTab(
            selectedMonth: _selectedMonth,
            onMonthChanged: _updateSelectedMonth,
            filteredReceipts: _filteredReceipts,
            selectedCurrency: _selectedCurrency,
            onCurrencyChanged: (value) =>
                setState(() => _selectedCurrency = value!),
            isLoadingRates: _isLoadingRates,
            formatCurrency: _formatCurrency,
            monthNames: monthNames,
            getTotalExpectedRevenue: (receipts) =>
                _getSumOfReceiptsByStatus(receipts, null),
            getTotalPaidAmount: (receipts) =>
                _getSumOfReceiptsByStatus(receipts, PaymentStatus.paid),
            getTotalPendingAmount: (receipts) =>
                _getSumOfReceiptsByStatus(receipts, PaymentStatus.pending),
            getTotalOverdueAmount: (receipts) =>
                _getSumOfReceiptsByStatus(receipts, PaymentStatus.overdue),
          ),
          BuildingAnalysisTab(
            selectedMonth: _selectedMonth,
            onMonthChanged: _updateSelectedMonth,
            buildings: widget.buildings,
            filteredReceipts: _filteredReceipts,
            expandedBuildings: _expandedBuildings,
            onToggleExpand: (buildingId) {
              setState(() {
                if (_expandedBuildings.contains(buildingId)) {
                  _expandedBuildings.remove(buildingId);
                } else {
                  _expandedBuildings.add(buildingId);
                }
              });
            },
            getBuildingFinancialAnalysis: _getBuildingFinancialAnalysis,
            getBuildingUtilityAnalysis: _getBuildingUtilityAnalysis,
            formatCurrency: _formatCurrency,
            monthNames: monthNames,
            getTotalExpectedRevenue: (receipts) =>
                _getSumOfReceiptsByStatus(receipts, null),
          ),
        ],
      ),
    );
  }
}
