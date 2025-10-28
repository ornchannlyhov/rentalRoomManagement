
import 'package:flutter/material.dart';
import 'package:receipts_v2/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key}); // REMOVED setLocale

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      titleKey: 'manageBuildings',
      descriptionKey: 'manageBuildingsDesc',
      icon: Icons.apartment_rounded,
    ),
    OnboardingData(
      titleKey: 'tenantManagement',
      descriptionKey: 'tenantManagementDesc',
      icon: Icons.people_rounded,
    ),
    OnboardingData(
      titleKey: 'paymentTracking',
      descriptionKey: 'paymentTrackingDesc',
      icon: Icons.payment_rounded,
    ),
    OnboardingData(
      titleKey: 'automationTools',
      descriptionKey: 'automationToolsDesc',
      icon: Icons.smart_toy_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    data: _onboardingData[index],
                    localizations: localizations,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        localizations.loginButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(
                            color: Color(0xFF10B981), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        localizations.registerLink,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;

  OnboardingData({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final AppLocalizations localizations;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 100,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            _getLocalizedText(localizations, data.titleKey),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _getLocalizedText(localizations, data.descriptionKey),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getLocalizedText(AppLocalizations localizations, String key) {
    switch (key) {
      case 'manageBuildings':
        return localizations.manageBuildings;
      case 'manageBuildingsDesc':
        return localizations.manageBuildingsDesc;
      case 'tenantManagement':
        return localizations.tenantManagement;
      case 'tenantManagementDesc':
        return localizations.tenantManagementDesc;
      case 'paymentTracking':
        return localizations.paymentTracking;
      case 'paymentTrackingDesc':
        return localizations.paymentTrackingDesc;
      case 'automationTools':
        return localizations.automationTools;
      case 'automationToolsDesc':
        return localizations.automationToolsDesc;
      default:
        return key;
    }
  }
}