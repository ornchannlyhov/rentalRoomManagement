import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/core/services/fcm_service.dart';
import 'package:joul_v2/data/repositories/auth_repository.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? username; // Only for registration
  final String? password; // Only for registration
  final bool isLogin;
  final String? purpose; // "register" or "reset_password"

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.username,
    this.password,
    required this.isLogin,
    this.purpose,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
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
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled to auto-submit?
    // Maybe better to let user press button to avoid accidental submission
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.lock_clock_outlined,
                size: 80,
                color: Color(0xFF10B981),
              ),
              const SizedBox(height: 32),
              Text(
                'Email Verification',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${'Please enter the code sent to'} ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
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
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authProvider.otpState.isLoading
                          ? null
                          : () => _verifyOtp(authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor:
                            const Color.fromARGB(255, 245, 245, 245),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: authProvider.otpState.isLoading
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
                              'Verify',
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
                  return authProvider.otpState.when(
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
    );
  }

  void _verifyOtp(AuthProvider authProvider) async {
    final otp = _otpCode;
    if (otp.length != 6) {
      GlobalSnackBar.show(
        context: context,
        message: 'Please enter a valid 6-digit code',
        isError: true,
      );
      return;
    }

    final repositoryManager =
        Provider.of<RepositoryManager>(context, listen: false);

    if (widget.isLogin) {
      // Login is directly via username/password now - this screen is NOT used for login anymore
      // This case should not occur with the new API, but kept for backwards compatibility
      return;
    } else {
      final request = VerifyRegistrationRequest(
        phoneNumber: widget.phoneNumber,
        otp: otp,
        username: widget.username!,
        password: widget.password!,
      );
      await authProvider.verifyRegistration(request);
    }

    if (mounted) {
      authProvider.user.when(
        loading: () {},
        success: (user) async {
          if (user != null && authProvider.isAuthenticated()) {
            FCMService.initialize().catchError((e) {
              debugPrint('FCM token upload failed: $e');
            });

            if (await ApiHelper.instance.hasNetwork()) {
              await repositoryManager.syncAll();
            }
            // Clear stack and go to home
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          }
        },
        error: (error) {
          // Error is shown in UI
        },
      );
    }
  }

  void _resendOtp(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final purpose = widget.purpose ?? (widget.isLogin ? 'login' : 'register');
    await authProvider.resendOtp(widget.phoneNumber, purpose);
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
