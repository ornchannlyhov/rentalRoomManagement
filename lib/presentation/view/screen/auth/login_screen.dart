// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joul_v2/core/utils/phone_formatter.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/repositories/auth_repository.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/presentation/view/screen/auth/widget/custom_text_feild.dart';
import 'package:joul_v2/presentation/view/screen/auth/otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.welcomeBack,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.signInPrompt,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hintText: '010 123 456',
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!PhoneFormatter.isValid(value)) {
                      return localizations.invalidPhoneNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authProvider.loginState.isLoading
                            ? null
                            : () => _handleLogin(authProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor:
                              const Color.fromARGB(255, 245, 245, 245),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: authProvider.loginState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 245, 245, 245)),
                                ),
                              )
                            : Text(
                                'Request OTP',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return authProvider.loginState.when(
                      loading: () => const SizedBox.shrink(),
                      success: (isSuccess) => const SizedBox.shrink(),
                      error: (error) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          error.toString().replaceAll('Exception: ', ''),
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${localizations.noAccount} ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: Text(
                        localizations.registerLink,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      final formattedPhone =
          PhoneFormatter.format(_phoneController.text.trim());

      if (formattedPhone == null) {
        // Should be caught by validator, but just in case
        return;
      }

      final request = LoginOtpRequest(
        phoneNumber: formattedPhone,
      );

      await authProvider.requestLoginOtp(request);

      if (mounted && authProvider.otpSent) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              phoneNumber: formattedPhone,
              isLogin: true,
            ),
          ),
        );
      }
    }
  }
}
