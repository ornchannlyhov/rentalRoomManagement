import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/presentation/providers/theme_provider.dart';
import 'package:receipts_v2/presentation/providers/auth_provider.dart';
import 'package:receipts_v2/data/models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'ខ្មែរ'; // Default language

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        centerTitle: true,
        title: Text(
          'ការកំណត់', // Settings
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
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load profile.',
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
                  label: const Text('Retry Loading Profile'),
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
                    'Or Sign Out',
                    style: TextStyle(color: Colors.red, fontSize: 16),
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
                      'You are not logged in.',
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
                      child: const Text('Go to Onboarding'),
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Profile Header
              _buildModernProfileHeader(context, isDarkMode, colorScheme, user),

              // Settings Sections
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
                    title: 'Account Settings',
                    subtitle: 'Privacy, security, change password',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: const Text('Account Settings tapped'),
                            backgroundColor: colorScheme.primary),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context: context,
                    isDarkMode: isDarkMode,
                    colorScheme: colorScheme,
                    icon: Icons.payment,
                    title: 'Subscriptions',
                    subtitle: 'Plans, payment methods',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: const Text('Subscriptions tapped'),
                            backgroundColor: colorScheme.primary),
                      );
                    },
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
                    title: 'Appearance',
                    subtitle: themeProvider.themeMode == ThemeMode.dark
                        ? 'Dark mode'
                        : themeProvider.themeMode == ThemeMode.light
                            ? 'Light mode'
                            : 'System default',
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
                    title: 'Language',
                    subtitle: _selectedLanguage,
                    onTap: () =>
                        _showLanguageDialog(context, isDarkMode, colorScheme),
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
                    title: 'Help & Support',
                    subtitle: 'FAQs, contact us',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: const Text('Help & Support tapped'),
                            backgroundColor: colorScheme.primary),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context: context,
                    isDarkMode: isDarkMode,
                    colorScheme: colorScheme,
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version 1.2.3',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: const Text('About tapped'),
                            backgroundColor: colorScheme.primary),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Logout Button
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
          // Profile Picture
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

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username ?? 'Unknown User', // Handle nullable username
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email ?? 'No Email Provided', // Handle nullable email
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
                    'Premium Member', // This can be dynamic based on user.
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

          // Edit Button
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: const Text('Edit profile tapped'),
                    backgroundColor: colorScheme.primary),
              );
            },
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
        child: const Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, bool isDarkMode, ColorScheme colorScheme) {
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
                  'Select Language',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption('ខ្មែរ', 'ខ្មែរ', colorScheme),
              _buildLanguageOption('English', 'English', colorScheme),
              _buildLanguageOption('中文', '中文', colorScheme),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
      String language, String displayName, ColorScheme colorScheme) {
    bool isSelected = language == _selectedLanguage;

    return ListTile(
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
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
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Capture references BEFORE any async operations
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Close the dialog
                Navigator.of(dialogContext).pop();

                try {
                  await authProvider.logout();

                  // Use captured references - no context lookup after await
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text('Signed out successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );

                  // Navigate using captured navigator
                  navigator.pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                } catch (e) {
                  // Use captured reference for error message too
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to sign out: ${e.toString().contains("Exception:") ? e.toString().split("Exception:")[1].trim() : e.toString()}',
                      ),
                      backgroundColor: Colors.red[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(
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
