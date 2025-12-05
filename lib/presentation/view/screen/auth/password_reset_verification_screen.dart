// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/repositories/auth_repository.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/auth/widget/custom_text_feild.dart';

class PasswordResetVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const PasswordResetVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<PasswordResetVerificationScreen> createState() =>
      _PasswordResetVerificationScreenState();
}

class _PasswordResetVerificationScreenState
    extends State<PasswordResetVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Timer? _timer;
  int _start = 300; // 5 minutes
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _start = 300;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  String get _timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(height: 32),
                Text(
                  'Reset Password',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the code sent to ${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 55,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF10B981), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFFFFFF),
                        ),
                        onChanged: (value) => _onCodeChanged(value, index),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _passwordController,
                  label: localizations.newPassword,
                  hintText: 'Enter new password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF9E9E9E),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: localizations.confirmPasswordLabel,
                  hintText: 'Confirm new password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF9E9E9E),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
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
                        onPressed:
                            authProvider.passwordResetVerifyState.isLoading
                                ? null
                                : () => _handleResetPassword(authProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor:
                              const Color.fromARGB(255, 245, 245, 245),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: authProvider.passwordResetVerifyState.isLoading
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
                                'Reset Password',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return authProvider.passwordResetVerifyState.when(
                      loading: () => const SizedBox.shrink(),
                      success: (success) => const SizedBox.shrink(),
                      error: (error) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE57373)),
                        ),
                        child: Text(
                          error.toString().replaceAll('Exception: ', ''),
                          style: const TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive code? ",
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                      ),
                    ),
                    if (_canResend)
                      GestureDetector(
                        onTap: () => _resendOtp(context),
                        child: Text(
                          'Resend',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        _timerText,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  void _handleResetPassword(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final otp = _otpCode;
    if (otp.length != 6) {
      GlobalSnackBar.show(
        context: context,
        message: 'Please enter a valid 6-digit code',
        isError: true,
      );
      return;
    }

    final request = VerifyPasswordResetRequest(
      phoneNumber: widget.phoneNumber,
      otp: otp,
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    await authProvider.verifyPasswordReset(request);

    if (mounted) {
      authProvider.passwordResetVerifyState.when(
        loading: () {},
        success: (success) {
          GlobalSnackBar.show(
            context: context,
            message:
                'Password reset successfully. Please login with your new password.',
            isError: false,
          );
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        },
        error: (error) {
          // Error is shown in UI
        },
      );
    }
  }

  void _resendOtp(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resendOtp(widget.phoneNumber, 'reset_password');
    _startTimer();
    if (mounted) {
      GlobalSnackBar.show(
        context: context,
        message: 'OTP Resent',
        isError: false,
      );
    }
  }
}
