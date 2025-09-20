import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/repositories/currency_repositoy.dart';

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

  // Month filter variables
  DateTime _selectedMonth = DateTime.now();
  List<Receipt> _filteredReceipts = [];

  // Expansion state for building cards
  Set<String> _expandedBuildings = <String>{};

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
      setState(() {
        _isLoadingRates = false;
      });
    }
  }

  void _filterReceiptsByMonth() {
    setState(() {
      _filteredReceipts = widget.receipts.where((receipt) {
        return receipt.date.year == _selectedMonth.year &&
            receipt.date.month == _selectedMonth.month;
      }).toList();
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _filterReceiptsByMonth();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _filterReceiptsByMonth();
  }

  Future<void> _selectMonth() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ជ្រើសរើសខែ'),
          content: Container(
            width: double.minPositive,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year selector
                Row(
                  children: [
                    Text('ឆ្នាំ: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedMonth.year,
                        isExpanded: true,
                        items: List.generate(10, (index) {
                          final year = DateTime.now().year - 5 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (year) {
                          if (year != null) {
                            setState(() {
                              _selectedMonth =
                                  DateTime(year, _selectedMonth.month);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Month selector
                Text('ខែ:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthNames = [
                      'មករា',
                      'កុម្ភៈ',
                      'មីនា',
                      'មេសា',
                      'ឧសភា',
                      'មិថុនា',
                      'កក្កដា',
                      'សីហា',
                      'កញ្ញា',
                      'តុលា',
                      'វិច្ឆិកា',
                      'ធ្នូ'
                    ];
                    final isSelected = _selectedMonth.month == (index + 1);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMonth =
                              DateTime(_selectedMonth.year, index + 1);
                        });
                        _filterReceiptsByMonth();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            monthNames[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('បោះបង់'),
            ),
          ],
        );
      },
    );
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
  double _getTotalExpectedRevenue(List<Receipt> receipts) {
    return receipts.fold(0.0, (sum, receipt) => sum + receipt.totalPrice);
  }

  double _getTotalPaidAmount(List<Receipt> receipts) {
    return receipts
        .where((receipt) => receipt.paymentStatus == PaymentStatus.paid)
        .fold(0.0, (sum, receipt) => sum + receipt.totalPrice);
  }

  double _getTotalPendingAmount(List<Receipt> receipts) {
    return receipts
        .where((receipt) => receipt.paymentStatus == PaymentStatus.pending)
        .fold(0.0, (sum, receipt) => sum + receipt.totalPrice);
  }

  double _getTotalOverdueAmount(List<Receipt> receipts) {
    return receipts
        .where((receipt) => receipt.paymentStatus == PaymentStatus.overdue)
        .fold(0.0, (sum, receipt) => sum + receipt.totalPrice);
  }

  Map<String, double> _getBuildingAnalysis(String buildingId) {
    final buildingReceipts = _filteredReceipts
        .where((receipt) => receipt.room?.building?.id == buildingId)
        .toList();

    return {
      'total': _getTotalExpectedRevenue(buildingReceipts),
      'paid': _getTotalPaidAmount(buildingReceipts),
      'pending': _getTotalPendingAmount(buildingReceipts),
      'overdue': _getTotalOverdueAmount(buildingReceipts),
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

  Widget _buildMonthFilterBar() {
    final monthNames = [
      'មករា',
      'កុម្ភៈ',
      'មីនា',
      'មេសា',
      'ឧសភា',
      'មិថុនា',
      'កក្កដា',
      'សីហា',
      'កញ្ញា',
      'តុលា',
      'វិច្ឆិកា',
      'ធ្នូ'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(Icons.chevron_left),
              tooltip: 'ខែមុន',
            ),
            Expanded(
              child: InkWell(
                onTap: _selectMonth,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: Icon(Icons.chevron_right),
              tooltip: 'ខែបន្ទាប់',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    final totalExpected = _getTotalExpectedRevenue(_filteredReceipts);
    final totalPaid = _getTotalPaidAmount(_filteredReceipts);
    final totalPending = _getTotalPendingAmount(_filteredReceipts);
    final totalOverdue = _getTotalOverdueAmount(_filteredReceipts);
    final collectionRate =
        totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month Filter
          _buildMonthFilterBar(),
          const SizedBox(height: 16),

          // Total Revenue Overview with Currency Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ប្រាក់ចំណូលសរុប',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      // Currency selector moved here
                      _isLoadingRates
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : DropdownButton<String>(
                              value: _selectedCurrency,
                              underline: Container(),
                              items: CurrencyService.supportedCurrencies.keys
                                  .map((currency) => DropdownMenuItem(
                                        value: currency,
                                        child: Text(currency),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCurrency = value!;
                                });
                              },
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatCurrency(totalExpected),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: collectionRate / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'អត្រាប្រមូល: ${collectionRate.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Status Breakdown
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'បានបង់ប្រាក់',
                  totalPaid,
                  Theme.of(context).colorScheme.primary,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusCard(
                  'មិនទាន់បង់',
                  totalPending,
                  Colors.orange,
                  Icons.pending,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'ហួសកំណត់',
                  totalOverdue,
                  Colors.red,
                  Icons.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusCard(
                  'នៅសល់',
                  totalPending + totalOverdue,
                  Colors.blue,
                  Icons.account_balance,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Utility Usage Analysis
          _buildUtilityAnalysis(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            _formatCurrency(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityAnalysis() {
    double totalWaterCost = 0;
    double totalElectricCost = 0;
    double totalRoomCost = 0;
    double totalServiceCost = 0;

    for (final receipt in _filteredReceipts) {
      totalWaterCost += receipt.waterPrice;
      totalElectricCost += receipt.electricPrice;
      totalRoomCost += receipt.roomPrice;
      totalServiceCost += receipt.totalServicePrice;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'ការវិភាគតម្លៃ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildUtilityRow(
                'ទឹក', totalWaterCost, Icons.water_drop, Colors.blue),
            _buildUtilityRow('អគ្គិសនី', totalElectricCost,
                Icons.electrical_services, Colors.yellow[700]!),
            _buildUtilityRow('បន្ទប់', totalRoomCost, Icons.home, Colors.brown),
            _buildUtilityRow('សេវាកម្ម', totalServiceCost,
                Icons.miscellaneous_services, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityRow(
      String title, double amount, IconData icon, Color color) {
    final total = _getTotalExpectedRevenue(_filteredReceipts);
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(title),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingUtilityAnalysis(String buildingId) {
    final utilityData = _getBuildingUtilityAnalysis(buildingId);
    final buildingReceipts = _filteredReceipts
        .where((receipt) => receipt.room?.building?.id == buildingId)
        .toList();
    final total = _getTotalExpectedRevenue(buildingReceipts);

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ការវិភាគតម្លៃ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBuildingUtilityRow('ទឹក', utilityData['water']!,
                Icons.water_drop, Colors.blue, total),
            _buildBuildingUtilityRow('អគ្គិសនី', utilityData['electric']!,
                Icons.electrical_services, Colors.yellow[700]!, total),
            _buildBuildingUtilityRow('បន្ទប់', utilityData['room']!, Icons.home,
                Colors.brown, total),
            _buildBuildingUtilityRow('សេវាកម្ម', utilityData['service']!,
                Icons.miscellaneous_services, Colors.purple, total),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingUtilityRow(
      String title, double amount, IconData icon, Color color, double total) {
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingAnalysis() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month Filter for Building Analysis too
          _buildMonthFilterBar(),
          const SizedBox(height: 16),
          ...widget.buildings.map((building) {
            final analysis = _getBuildingAnalysis(building.id);
            final collectionRate = analysis['total']! > 0
                ? (analysis['paid']! / analysis['total']!) * 100
                : 0.0;
            final isExpanded = _expandedBuildings.contains(building.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedBuildings.remove(building.id);
                        } else {
                          _expandedBuildings.add(building.id);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.apartment,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  building.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                '${analysis['receiptsCount']!.toInt()} វិក្កយបត្រ',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ប្រាក់ចំណូលសរុប:'),
                              Text(
                                _formatCurrency(analysis['total']!),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('បានបង់ប្រាក់:'),
                              Text(
                                _formatCurrency(analysis['paid']!),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('នៅសល់:'),
                              Text(
                                _formatCurrency(analysis['pending']! +
                                    analysis['overdue']!),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: collectionRate / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'អត្រាប្រមូល: ${collectionRate.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'ចុចដើម្បីមើលលម្អិត',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expanded content
                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildBuildingUtilityAnalysis(building.id),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('ការវិភាគលម្អិត'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40), // control height
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet, size: 18),
                    SizedBox(width: 6), // spacing between icon and text
                    Text('ប្រាក់', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apartment, size: 18),
                    SizedBox(width: 6),
                    Text('អគារ', style: TextStyle(fontSize: 14)),
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
          _buildFinancialOverview(),
          _buildBuildingAnalysis(),
        ],
      ),
    );
  }
}
