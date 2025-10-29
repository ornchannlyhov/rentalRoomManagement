// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/presentation/providers/theme_provider.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/data/models/user.dart';

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
              _buildModernProfileHeader(context, isDarkMode, colorScheme, user),
              _buildSettingsSection(
                context,
                isDarkMode,
                colorScheme,
                [
                  _buildSettingsItem(
                    context: context,
                    isDarkMode: isDarkMode,
                    colorScheme: colorScheme,
                    icon: Icons.person_outline,
                    title: localizations.accountSettings,
                    subtitle: localizations.accountSettingsSubtitle,
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    context: context,
                    isDarkMode: isDarkMode,
                    colorScheme: colorScheme,
                    icon: Icons.payment,
                    title: localizations.subscriptions,
                    subtitle: localizations.subscriptionsSubtitle,
                    onTap: () {},
                  ),
                ],
              ),
              _buildSettingsSection(
                context,
                isDarkMode,
                colorScheme,
                [
                  _buildSettingsItem(
                    context: context,
                    isDarkMode: isDarkMode,
                    colorScheme: colorScheme,
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
                  _buildSettingsItem(
                    context: context,
                    isDarkMode: isDarkMode,
                    colorScheme: colorScheme,
                    icon: Icons.language_outlined,
                    title: localizations.language,
                    subtitle: getLanguageSubtitle(),
                    onTap: () => _showLanguageDialog(
                        context, isDarkMode, colorScheme, themeProvider),
                  ),
                ],
              ),
              _buildSettingsSection(
                context,
                isDarkMode,
                colorScheme,
                [
                  _buildSettingsItem(
                    context: context,
                    isDarkMode: isDarkMode,
                    colorScheme: colorScheme,
                    icon: Icons.help_outline,
                    title: localizations.helpAndSupport,
                    subtitle: localizations.helpAndSupportSubtitle,
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    context: context,
                    isDarkMode: isDarkMode,
                    colorScheme: colorScheme,
                    icon: Icons.info_outline,
                    title: localizations.about,
                    subtitle: localizations.version("1.2.3"),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildLogoutButton(
                  context, isDarkMode, colorScheme, authProvider),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernProfileHeader(BuildContext context, bool isDarkMode,
      ColorScheme colorScheme, User user) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username ?? localizations.unknownUser,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email ?? localizations.noEmailProvided,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    localizations.premiumMember,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.edit_outlined,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isDarkMode,
      ColorScheme colorScheme, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          int index = items.indexOf(item);
          bool isLast = index == items.length - 1;

          return Column(
            children: [
              item,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: colorScheme.onSurface.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required bool isDarkMode,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDarkMode,
      ColorScheme colorScheme, AuthProvider authProvider) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: TextButton(
        onPressed: () =>
            _showLogoutDialog(context, isDarkMode, colorScheme, authProvider),
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: Colors.red.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          localizations.signOut,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
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
