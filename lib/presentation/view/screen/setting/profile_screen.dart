import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/presentation/providers/theme_provider.dart';
import 'package:receipts_v2/presentation/providers/auth_provider.dart';
import 'package:receipts_v2/data/models/user.dart';
import 'package:receipts_v2/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _getLanguageDisplayName(Locale locale, AppLocalizations localizations) {
    switch (locale.languageCode) {
      case 'km':
        return 'ខ្មែរ (Khmer)';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        centerTitle: true,
        title: Text(
          localizations.settingsTitle,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: authProvider.user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error) => _buildErrorState(context, error, colorScheme, localizations, authProvider, isDarkMode),
        success: (user) {
          if (user == null) {
            return _buildEmptyUserState(context, colorScheme, localizations);
          }
          return _buildContent(
            context,
            themeProvider,
            authProvider,
            isDarkMode,
            colorScheme,
            user,
            localizations,
          );
        },
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    ColorScheme colorScheme,
    AppLocalizations localizations,
    AuthProvider authProvider,
    bool isDarkMode,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              localizations.loading,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Error: ${error.toString().contains("Exception:") ? error.toString().split("Exception:")[1].trim() : error.toString()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => authProvider.getProfile(),
              icon: const Icon(Icons.refresh),
              label: Text(localizations.retryLoadingProfile),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _showLogoutDialog(context, isDarkMode, colorScheme, authProvider, localizations),
              child: Text(
                localizations.signOut,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyUserState(BuildContext context, ColorScheme colorScheme, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              localizations.noLoggedIn,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false),
              child: Text(localizations.goToOnboarding),
            ),
          ],
        ),
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
    AppLocalizations localizations,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProfileHeader(context, isDarkMode, colorScheme, user, localizations),
              _buildSettingsSection(context, isDarkMode, colorScheme, [
                _buildSettingsItem(
                  context: context,
                  colorScheme: colorScheme,
                  icon: Icons.person_outline,
                  title: localizations.accountSettings,
                  subtitle: localizations.privacySecurity,
                  onTap: () {},
                ),
                _buildSettingsItem(
                  context: context,
                  colorScheme: colorScheme,
                  icon: Icons.payment,
                  title: localizations.subscriptions,
                  subtitle: localizations.plansPayments,
                  onTap: () {},
                ),
              ]),
              _buildSettingsSection(context, isDarkMode, colorScheme, [
                _buildSettingsItem(
                  context: context,
                  colorScheme: colorScheme,
                  icon: Icons.palette_outlined,
                  title: localizations.appearance,
                  subtitle: themeProvider.themeMode == ThemeMode.dark
                      ? localizations.darkMode
                      : themeProvider.themeMode == ThemeMode.light
                          ? localizations.lightMode
                          : localizations.systemDefault,
                  trailing: Switch(
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) => themeProvider.toggleTheme(),
                  ),
                  onTap: () => themeProvider.toggleTheme(),
                ),
                _buildSettingsItem(
                  context: context,
                  colorScheme: colorScheme,
                  icon: Icons.language_outlined,
                  title: localizations.language,
                  subtitle: _getLanguageDisplayName(themeProvider.locale, localizations),
                  onTap: () => _showLanguageDialog(context, isDarkMode, colorScheme, themeProvider, localizations),
                ),
              ]),
              _buildSettingsSection(context, isDarkMode, colorScheme, [
                _buildSettingsItem(
                  context: context,
                  colorScheme: colorScheme,
                  icon: Icons.help_outline,
                  title: localizations.helpSupport,
                  subtitle: localizations.faqContact,
                  onTap: () {},
                ),
                _buildSettingsItem(
                  context: context,
                  colorScheme: colorScheme,
                  icon: Icons.info_outline,
                  title: localizations.about,
                  subtitle: localizations.version,
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 30),
              _buildLogoutButton(context, isDarkMode, colorScheme, authProvider, localizations),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDarkMode, ColorScheme colorScheme, User user, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: colorScheme.primary,
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username ?? localizations.unknownUser,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email ?? localizations.noEmailProvided,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    localizations.premiumMember,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizations.editProfileTapped)),
            ),
            icon: Icon(Icons.edit_outlined, color: colorScheme.onSurface.withOpacity(0.6), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isDarkMode, ColorScheme colorScheme, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final isLast = index == items.length - 1;
          return Column(
            children: [
              items[index],
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: colorScheme.onSurface.withOpacity(0.1),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
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
        child: Icon(icon, size: 20, color: colorScheme.onSurface.withOpacity(0.7)),
      ),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.6))),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurface.withOpacity(0.4)),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDarkMode, ColorScheme colorScheme, AuthProvider authProvider, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: TextButton(
        onPressed: () => _showLogoutDialog(context, isDarkMode, colorScheme, authProvider, localizations),
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.red.withOpacity(0.2), width: 1),
        ),
        child: Text(
          localizations.signOut,
          style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    bool isDarkMode,
    ColorScheme colorScheme,
    ThemeProvider themeProvider,
    AppLocalizations localizations,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            Text(localizations.selectLanguage,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 20),
            _buildLanguageOption(context, const Locale('km', ''), 'ខ្មែរ (Khmer)', colorScheme, themeProvider),
            _buildLanguageOption(context, const Locale('en', ''), 'English', colorScheme, themeProvider),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    Locale locale,
    String displayName,
    ColorScheme colorScheme,
    ThemeProvider themeProvider,
  ) {
    bool isSelected = locale.languageCode == themeProvider.locale.languageCode;

    return ListTile(
      onTap: () {
        themeProvider.setLocale(locale);
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
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary, size: 20) : null,
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    bool isDarkMode,
    ColorScheme colorScheme,
    AuthProvider authProvider,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(localizations.signOut,
            style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
        content: Text(localizations.signOutConfirm,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(localizations.cancel,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();
              try {
                await authProvider.logout();
                messenger.showSnackBar(SnackBar(content: Text(localizations.signOutSuccess)));
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('${localizations.signOutFailed}: $e')));
              }
            },
            child: Text(localizations.signOut, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
