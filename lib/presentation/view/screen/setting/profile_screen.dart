// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/presentation/providers/theme_provider.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/data/models/user.dart';
import 'package:joul_v2/presentation/view/screen/setting/widgets/profile_header.dart';
import 'package:joul_v2/presentation/view/screen/setting/widgets/settings_group.dart';
import 'package:joul_v2/presentation/view/screen/setting/widgets/settings_item.dart';
import 'package:joul_v2/presentation/view/screen/setting/widgets/logout_button.dart';
import 'package:joul_v2/presentation/view/screen/setting/help_support_screen.dart';
import 'package:joul_v2/presentation/view/screen/setting/about_app_screen.dart';
import 'package:joul_v2/data/repositories/auth_repository.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        centerTitle: true,
        title: Text(
          localizations.settings,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: authProvider.user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  localizations.failedToLoadProfile,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  'Error: ${error.toString().contains("Exception:") ? error.toString().split("Exception:")[1].trim() : error.toString()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => authProvider.getProfile(),
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.retryLoadingProfile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => _showLogoutDialog(
                      context, isDarkMode, colorScheme, authProvider),
                  child: Text(
                    localizations.orSignOut,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              ],
            ),
          ),
        ),
        success: (user) {
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(height: 16),
                    Text(
                      localizations.notLoggedIn,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/onboarding', (route) => false);
                      },
                      child: Text(localizations.goToOnboarding),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildContent(
            context,
            themeProvider,
            authProvider,
            isDarkMode,
            colorScheme,
            user,
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeProvider themeProvider,
    AuthProvider authProvider,
    bool isDarkMode,
    ColorScheme colorScheme,
    User user,
  ) {
    final localizations = AppLocalizations.of(context)!;

    // This function is now perfect for the new logic.
    String getAppearanceSubtitle() {
      if (themeProvider.themeMode == ThemeMode.dark) {
        return localizations.darkMode;
      } else {
        return localizations.lightMode;
      }
    }

    String getLanguageSubtitle() {
      switch (themeProvider.locale.languageCode) {
        case 'km':
          return localizations.khmer;
        case 'zh':
          return localizations.chinese;
        default: // 'en' and any other fallback
          return localizations.english;
      }
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              ProfileHeader(user: user, isDarkMode: isDarkMode),
              SettingsGroup(
                isDarkMode: isDarkMode,
                items: [
                  SettingsItem(
                    icon: Icons.lock_outline,
                    title: localizations.changePassword,
                    subtitle: localizations.accountSettingsSubtitle,
                    onTap: () => _showChangePasswordBottomSheet(
                        context, isDarkMode, colorScheme, authProvider),
                  ),
                  SettingsItem(
                    icon: Icons.payment,
                    title: localizations.subscriptions,
                    subtitle: localizations.subscriptionsSubtitle,
                    onTap: () {},
                  ),
                ],
              ),
              SettingsGroup(
                isDarkMode: isDarkMode,
                items: [
                  SettingsItem(
                    icon: Icons.palette_outlined,
                    title: localizations.appearance,
                    subtitle: getAppearanceSubtitle(),
                    trailing: Switch(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: colorScheme.primary,
                    ),
                    onTap: () {
                      themeProvider.toggleTheme();
                    },
                  ),
                  SettingsItem(
                    icon: Icons.language_outlined,
                    title: localizations.language,
                    subtitle: getLanguageSubtitle(),
                    onTap: () => _showLanguageDialog(
                        context, isDarkMode, colorScheme, themeProvider),
                  ),
                ],
              ),
              SettingsGroup(
                isDarkMode: isDarkMode,
                items: [
                  SettingsItem(
                    icon: Icons.help_outline,
                    title: localizations.helpAndSupport,
                    subtitle: localizations.helpAndSupportSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  SettingsItem(
                    icon: Icons.info_outline,
                    title: localizations.about,
                    subtitle: localizations.version("1.2.3"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutAppScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              LogoutButton(
                onPressed: () => _showLogoutDialog(
                    context, isDarkMode, colorScheme, authProvider),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangePasswordBottomSheet(BuildContext context, bool isDarkMode,
      ColorScheme colorScheme, AuthProvider authProvider) {
    final localizations = AppLocalizations.of(context)!;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool obscureOldPassword = true;
          bool obscureNewPassword = true;
          bool obscureConfirmPassword = true;
          String? errorMessage;

          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          localizations.changePassword,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          controller: oldPasswordController,
                          label: localizations.oldPassword,
                          icon: Icons.lock_outline,
                          isObscured: obscureOldPassword,
                          onToggleVisibility: () {
                            setState(() {
                              obscureOldPassword = !obscureOldPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.pleaseEnterPassword;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          controller: newPasswordController,
                          label: localizations.newPassword,
                          icon: Icons.lock_reset,
                          isObscured: obscureNewPassword,
                          onToggleVisibility: () {
                            setState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.pleaseEnterPassword;
                            }
                            if (value.length < 6) {
                              return localizations.passwordTooShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          controller: confirmPasswordController,
                          label: localizations.confirmPasswordLabel,
                          icon: Icons.check_circle_outline,
                          isObscured: obscureConfirmPassword,
                          onToggleVisibility: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.pleaseEnterPassword;
                            }
                            if (value != newPasswordController.text) {
                              return localizations.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              errorMessage = null;
                            });

                            if (formKey.currentState!.validate()) {
                              try {
                                await authProvider.updatePassword(
                                  UpdatePasswordRequest(
                                    oldPassword: oldPasswordController.text,
                                    newPassword: newPasswordController.text,
                                    confirmPassword:
                                        confirmPasswordController.text,
                                  ),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  GlobalSnackBar.show(
                                    context: context,
                                    message: localizations.passwordUpdated,
                                    isError: false,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setState(() {
                                    errorMessage = e
                                        .toString()
                                        .replaceAll('Exception: ', '');
                                  });
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authProvider.passwordUpdateState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(localizations.updatePassword),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: validator,
    );
  }

  void _showLanguageDialog(BuildContext context, bool isDarkMode,
      ColorScheme colorScheme, ThemeProvider themeProvider) {
    final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  localizations.selectLanguage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption('km', '🇰🇭 ${localizations.khmer}',
                  colorScheme, themeProvider),
              _buildLanguageOption('en', '🇺🇸 ${localizations.english}',
                  colorScheme, themeProvider),
              _buildLanguageOption('zh', '🇨🇳 ${localizations.chinese}',
                  colorScheme, themeProvider),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String languageCode, String displayName,
      ColorScheme colorScheme, ThemeProvider themeProvider) {
    bool isSelected = languageCode == themeProvider.locale.languageCode;

    return ListTile(
      onTap: () {
        themeProvider.setLocale(Locale(languageCode));
        Navigator.of(context).pop();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        displayName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: colorScheme.primary,
              size: 20,
            )
          : null,
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDarkMode,
      ColorScheme colorScheme, AuthProvider authProvider) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            localizations.signOut,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            localizations.signOutConfirmation,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                localizations.cancel,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await authProvider.logout();
              },
              child: Text(
                localizations.signOut,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
