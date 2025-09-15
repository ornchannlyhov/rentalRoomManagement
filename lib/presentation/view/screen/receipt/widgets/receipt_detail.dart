import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/repositories/currency_repositoy.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class ReceiptDetailScreen extends StatefulWidget {
  final Receipt receipt;
  final VoidCallback? onShareRequested;

  const ReceiptDetailScreen({
    required this.receipt,
    super.key,
    this.onShareRequested,
  });

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  bool _isServiceAvailable = true;
  bool _isSharing = false;
  double? _convertedTotalPrice;
  late ScreenshotController _screenshotController;

  @override
  void initState() {
    super.initState();
    _screenshotController = ScreenshotController();
    _checkServiceAvailability();

    // Call _shareReceipt if onShareRequested is provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onShareRequested != null) {
        _shareReceipt();
      }
    });
  }

  Future<void> _checkServiceAvailability() async {
    final isAvailable = await CurrencyService.isServiceAvailable();
    if (mounted) {
      setState(() {
        _isServiceAvailable = isAvailable;
      });
    }
  }

  Future<void> _convertCurrency(String targetCurrency) async {
    if (targetCurrency == 'USD') {
      setState(() {
        _selectedCurrency = targetCurrency;
        _convertedTotalPrice = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final totalPrice = await CurrencyService.convertFromUSD(
          widget.receipt.totalPrice, targetCurrency);

      if (mounted) {
        setState(() {
          _selectedCurrency = targetCurrency;
          _convertedTotalPrice = totalPrice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to convert currency: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareReceipt() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Capture screenshot
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture screenshot');
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/receipt_${widget.receipt.id}.png';

      // Save image to file
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(imagePath)],
      );

      // Clean up temporary file
      try {
        await imageFile.delete();
      } catch (e) {
        print('Failed to delete temporary file: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មានបញ្ហាក្នុងការចែករំលែក: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Share error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  String _formatPrice(double price, {bool isTotal = false}) {
    if (isTotal && _selectedCurrency != 'USD' && _convertedTotalPrice != null) {
      return CurrencyService.formatCurrency(
          _convertedTotalPrice!, _selectedCurrency);
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  Widget _buildCurrencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          isDense: true,
          // Disable dropdown when service unavailable or loading
          onChanged: (!_isServiceAvailable || _isLoading)
              ? null
              : (String? newValue) {
                  if (newValue != null) {
                    _convertCurrency(newValue);
                  }
                },
          items: CurrencyService.supportedCurrencies.keys
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyService.supportedCurrencies[value]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(value),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasServices = widget.receipt.services.isNotEmpty;
    final hasWaterUsage = widget.receipt.thisWaterUsed > 0;
    final hasElectricUsage = widget.receipt.thisElectricUsed > 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        title: Text('វិក្កយបត្របន្ទប់ជួល'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isSharing ? null : _shareReceipt,
            icon: _isSharing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onSurface,
                      ),
                    ),
                  )
                : const Icon(Icons.share),
            tooltip: 'ចែករំលែកវិក្កយបត្រ',
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: theme.colorScheme.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'វិក្កយបត្របន្ទប់ ${widget.receipt.room?.roomNumber ?? "N/A"}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMMd('km').format(widget.receipt.date),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Utility usage (only show if has usage)
                if (hasWaterUsage || hasElectricUsage) ...[
                  _buildSectionHeader(theme, 'ការប្រើប្រាស់'),
                  if (hasWaterUsage) ...[
                    _buildInfoRow(theme, 'ទឹកប្រើប្រាស់ខែមុន',
                        '${widget.receipt.lastWaterUsed} m³'),
                    _buildInfoRow(theme, 'ទឹកប្រើប្រាស់ខែនេះ',
                        '${widget.receipt.thisWaterUsed} m³'),
                  ],
                  if (hasElectricUsage) ...[
                    _buildInfoRow(theme, 'ភ្លើងប្រើប្រាស់ខែមុន',
                        '${widget.receipt.lastElectricUsed} kWh'),
                    _buildInfoRow(theme, 'ភ្លើងប្រើប្រាស់ខែនេះ',
                        '${widget.receipt.thisElectricUsed} kWh'),
                  ],
                  const SizedBox(height: 8),
                  _buildDividerSimple(theme),
                  const SizedBox(height: 8),
                ],

                // Payment section (only show if has usage)
                if (hasWaterUsage || hasElectricUsage) ...[
                  _buildSectionHeader(theme, 'ទូទាត់ការប្រើប្រាស់'),
                  if (hasWaterUsage) ...[
                    _buildInfoRow(theme, 'ទឹកប្រើប្រាស់',
                        '${widget.receipt.waterUsage} m³'),
                    _buildPriceRow(
                        theme, 'ថ្លៃទឹកសរុប', widget.receipt.waterPrice),
                  ],
                  if (hasElectricUsage) ...[
                    _buildInfoRow(theme, 'ភ្លើងប្រើប្រាស់',
                        '${widget.receipt.electricUsage} kWh'),
                    _buildPriceRow(
                        theme, 'ថ្លៃភ្លើងសរុប', widget.receipt.electricPrice),
                  ],
                  const SizedBox(height: 8),
                  _buildDividerSimple(theme),
                  const SizedBox(height: 8),
                ],

                // Services (only show if has services)
                if (hasServices) ...[
                  _buildSectionHeader(theme, 'សេវាកម្មបន្ថែម'),
                  Column(
                    children: widget.receipt.services
                        .map((service) => _buildServiceItem(
                            theme, service.name, service.price))
                        .toList(),
                  ),
                  _buildPriceRow(
                      theme, 'សរុបសេវាកម្ម', widget.receipt.totalServicePrice),
                  const SizedBox(height: 8),
                  _buildDividerSimple(theme),
                  const SizedBox(height: 8),
                ],

                // Rent
                _buildPriceRow(theme, 'ថ្លៃជួលបន្ទប់',
                    widget.receipt.room?.building?.rentPrice ?? 0),

                const SizedBox(height: 8),
                _buildDividerThick(theme),
                const SizedBox(height: 8),

                // Grand total with currency selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'សរុបទឹកប្រាក់',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatPrice(widget.receipt.totalPrice,
                              isTotal: true),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildCurrencyDropdown(),
                      ],
                    ),
                  ],
                ),

                // Service availability warning
                if (!_isServiceAvailable) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'សេវាប្រាក់ប្តូរមានបញ្ហា - កំពុងបង្ហាញអត្រាមូលដ្ឋាន USD ជំនួសវិញ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Footer note
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'សូមអរគុណសម្រាប់ការប្រើប្រាស់សេវាកម្មរបស់យើងខ្ញុំ!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDividerSimple(ThemeData theme) {
    return Divider(
      height: 1,
      color: theme.colorScheme.onSurface.withOpacity(0.1),
    );
  }

  Widget _buildDividerThick(ThemeData theme) {
    return Divider(
      thickness: 2,
      color: theme.colorScheme.primary.withOpacity(0.2),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(ThemeData theme, String label, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            _formatPrice(price),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(ThemeData theme, String name, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '• $name',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            _formatPrice(price),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
