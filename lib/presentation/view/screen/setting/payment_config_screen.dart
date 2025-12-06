import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:joul_v2/presentation/providers/payment_config_provider.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/app_widgets/skeleton_widgets.dart';

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

  // Simplified form state - just two toggles
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
      _syncAndLoadConfig();
    });
  }

  Future<void> _syncAndLoadConfig() async {
    final provider = context.read<PaymentConfigProvider>();

    // First, load any existing cached config immediately
    _loadExistingConfig();

    // Then sync from API to get the latest data
    try {
      await provider.syncPaymentConfig();
      // After sync completes, reload the form with fresh data
      if (mounted) {
        _loadExistingConfig();
      }
    } catch (_) {
      // Silently fail - we already loaded cached data above
      // The error will be handled by the Consumer in the build method
    }
  }

  void _loadExistingConfig() {
    final provider = context.read<PaymentConfigProvider>();
    final config = provider.config;

    if (config != null) {
      setState(() {
        _enableKhqr = config.enableKhqr;
        _enableAbaPayWay = config.enableAbaPayWay;
        _bankNameController.text = config.bankName ?? '';
        _bankAccountNumberController.text = config.bankAccountNumber ?? '';
        _bankAccountNameController.text = config.bankAccountName ?? '';
        _isEditing = true;
      });
    }
  }

  // Auto-calculate paymentMethod based on enabled toggles
  String get _paymentMethod {
    if (_enableKhqr && _enableAbaPayWay) return 'both';
    if (_enableAbaPayWay) return 'aba_payway';
    if (_enableKhqr) return 'khqr';
    return 'none';
  }

  bool get _hasAnyMethodEnabled => _enableKhqr || _enableAbaPayWay;

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          localizations.paymentSettings,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PaymentConfigProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Skeletonizer(
              enabled: true,
              child: PaymentConfigSkeleton(),
            );
          }

          if (provider.hasError) {
            return _buildErrorState(
                context, colorScheme, localizations, provider);
          }

          return _buildForm(context, colorScheme, localizations, provider);
        },
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations localizations,
    PaymentConfigProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.failedToLoadPaymentConfig,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => provider.syncPaymentConfig(),
              icon: const Icon(Icons.refresh),
              label: Text(localizations.retry),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
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
            // Header text
            Text(
              localizations.paymentMethods,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // KHQR Payment Method Card
            _buildPaymentMethodToggleCard(
              title: localizations.khqr,
              description: localizations.khqrDescription,
              icon: Icons.qr_code_2_rounded,
              value: _enableKhqr,
              onChanged: (value) => setState(() => _enableKhqr = value),
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 12),

            // ABA PayWay Payment Method Card
            _buildPaymentMethodToggleCard(
              title: localizations.abaPayWay,
              description: localizations.abaPayWayDescription,
              icon: Icons.payment_rounded,
              value: _enableAbaPayWay,
              onChanged: (value) => setState(() => _enableAbaPayWay = value),
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 32),

            // Bank Details Section (only shown when at least one method is enabled)
            if (_hasAnyMethodEnabled) ...[
              Text(
                localizations.bankDetails,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bankNameController,
                label: localizations.bankName,
                hint: localizations.enterBankName,
                icon: Icons.account_balance_rounded,
                colorScheme: colorScheme,
                validator: (value) {
                  if (_hasAnyMethodEnabled &&
                      (value == null || value.isEmpty)) {
                    return localizations.pleaseEnterBankName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bankAccountNumberController,
                label: localizations.accountNumber,
                hint: localizations.enterAccountNumber,
                icon: Icons.numbers_rounded,
                colorScheme: colorScheme,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_hasAnyMethodEnabled &&
                      (value == null || value.isEmpty)) {
                    return localizations.pleaseEnterAccountNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bankAccountNameController,
                label: localizations.accountHolderName,
                hint: localizations.enterAccountHolderName,
                icon: Icons.person_outline_rounded,
                colorScheme: colorScheme,
                validator: (value) {
                  if (_hasAnyMethodEnabled &&
                      (value == null || value.isEmpty)) {
                    return localizations.pleaseEnterAccountHolderName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
            ],

            // Save Button
            FilledButton(
              onPressed: provider.isLoading ? null : _saveConfiguration,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildPaymentMethodToggleCard({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          paymentMethod: _paymentMethod,
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
          paymentMethod: _paymentMethod,
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
