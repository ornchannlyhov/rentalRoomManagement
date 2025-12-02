import 'package:flutter/material.dart';
import 'package:joul_v2/presentation/providers/payment_config_provider.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';

class PaymentConfigScreen extends StatefulWidget {
  const PaymentConfigScreen({super.key});

  @override
  State<PaymentConfigScreen> createState() => _PaymentConfigScreenState();
}

class _PaymentConfigScreenState extends State<PaymentConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountNumberController;
  late TextEditingController _bankAccountNameController;
  
  // Form state
  String _selectedPaymentMethod = 'none';
  bool _enableKhqr = false;
  bool _enableAbaPayWay = false;
  
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController();
    _bankAccountNumberController = TextEditingController();
    _bankAccountNameController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingConfig();
    });
  }

  void _loadExistingConfig() {
    final provider = context.read<PaymentConfigProvider>();
    final config = provider.config;
    
    if (config != null) {
      setState(() {
        _selectedPaymentMethod = config.paymentMethod;
        _enableKhqr = config.enableKhqr;
        _enableAbaPayWay = config.enableAbaPayWay;
        _bankNameController.text = config.bankName ?? '';
        _bankAccountNumberController.text = config.bankAccountNumber ?? '';
        _bankAccountNameController.text = config.bankAccountName ?? '';
        _isEditing = true;
      });
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        centerTitle: true,
        title: Text(
          localizations.paymentSettings,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<PaymentConfigProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      localizations.failedToLoadPaymentConfig,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.syncPaymentConfig(),
                      icon: const Icon(Icons.refresh),
                      label: Text(localizations.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildForm(context, colorScheme, localizations, provider);
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations localizations,
    PaymentConfigProvider provider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment Method Selection
            Text(
              localizations.paymentMethod,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodCard('khqr', 'KHQR', Icons.qr_code, colorScheme),
            const SizedBox(height: 12),
            _buildPaymentMethodCard('aba_payway', 'ABA PayWay', Icons.payment, colorScheme),
            const SizedBox(height: 12),
            _buildPaymentMethodCard('both', localizations.both, Icons.account_balance_wallet, colorScheme),
            const SizedBox(height: 12),
            _buildPaymentMethodCard('none', localizations.none, Icons.block, colorScheme),
            
            const SizedBox(height: 24),

            // Payment Method Toggles
            if (_selectedPaymentMethod != 'none') ...[
              Text(
                localizations.enabledMethods,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              if (_selectedPaymentMethod == 'khqr' || _selectedPaymentMethod == 'both')
                _buildToggleCard(
                  title: 'KHQR',
                  subtitle: localizations.khqrSubtitle,
                  icon: Icons.qr_code_scanner,
                  value: _enableKhqr,
                  onChanged: (value) => setState(() => _enableKhqr = value),
                  colorScheme: colorScheme,
                ),
              
              const SizedBox(height: 12),
              
              if (_selectedPaymentMethod == 'aba_payway' || _selectedPaymentMethod == 'both')
                _buildToggleCard(
                  title: 'ABA PayWay',
                  subtitle: localizations.abaPayWaySubtitle,
                  icon: Icons.credit_card,
                  value: _enableAbaPayWay,
                  onChanged: (value) => setState(() => _enableAbaPayWay = value),
                  colorScheme: colorScheme,
                ),
              
              const SizedBox(height: 24),
            ],

            // Bank Details
            if (_selectedPaymentMethod != 'none') ...[
              Text(
                localizations.bankDetails,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: localizations.bankName,
                  hintText: localizations.enterBankName,
                  prefixIcon: const Icon(Icons.account_balance),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (_selectedPaymentMethod != 'none' && (value == null || value.isEmpty)) {
                    return localizations.pleaseEnterBankName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _bankAccountNumberController,
                decoration: InputDecoration(
                  labelText: localizations.accountNumber,
                  hintText: localizations.enterAccountNumber,
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_selectedPaymentMethod != 'none' && (value == null || value.isEmpty)) {
                    return localizations.pleaseEnterAccountNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _bankAccountNameController,
                decoration: InputDecoration(
                  labelText: localizations.accountHolderName,
                  hintText: localizations.enterAccountHolderName,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (_selectedPaymentMethod != 'none' && (value == null || value.isEmpty)) {
                    return localizations.pleaseEnterAccountHolderName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
            ],

            // Save Button
            ElevatedButton(
              onPressed: provider.isLoading ? null : _saveConfiguration,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing
                          ? localizations.updatePaymentConfig
                          : localizations.savePaymentConfig,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    String value,
    String title,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.5)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<PaymentConfigProvider>();
    final localizations = AppLocalizations.of(context)!;

    try {
      if (_isEditing) {
        await provider.updatePaymentConfig(
          paymentMethod: _selectedPaymentMethod,
          bankName: _bankNameController.text.trim().isEmpty 
              ? null 
              : _bankNameController.text.trim(),
          bankAccountNumber: _bankAccountNumberController.text.trim().isEmpty
              ? null
              : _bankAccountNumberController.text.trim(),
          bankAccountName: _bankAccountNameController.text.trim().isEmpty
              ? null
              : _bankAccountNameController.text.trim(),
          enableKhqr: _enableKhqr,
          enableAbaPayWay: _enableAbaPayWay,
        );
      } else {
        await provider.setupPaymentConfig(
          paymentMethod: _selectedPaymentMethod,
          bankName: _bankNameController.text.trim().isEmpty
              ? null
              : _bankNameController.text.trim(),
          bankAccountNumber: _bankAccountNumberController.text.trim().isEmpty
              ? null
              : _bankAccountNumberController.text.trim(),
          bankAccountName: _bankAccountNameController.text.trim().isEmpty
              ? null
              : _bankAccountNameController.text.trim(),
          enableKhqr: _enableKhqr,
          enableAbaPayWay: _enableAbaPayWay,
        );
      }

      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: _isEditing
              ? localizations.paymentConfigUpdated
              : localizations.paymentConfigSaved,
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }
}