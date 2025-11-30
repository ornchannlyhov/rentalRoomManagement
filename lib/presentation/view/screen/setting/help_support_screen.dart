import 'package:flutter/material.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _reportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.helpAndSupport),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.faqs),
            Tab(text: localizations.reportProblem),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqsTab(context),
          _buildReportProblemTab(context, localizations, colorScheme),
        ],
      ),
    );
  }

  Widget _buildFaqsTab(BuildContext context) {
    final faqs = [
      _FaqItem(
        question: "How do I reset my password?",
        answer:
            "You can reset your password by going to the login screen and clicking on 'Forgot Password'. Follow the instructions sent to your email to create a new password.",
      ),
      _FaqItem(
        question: "How do I contact support?",
        answer:
            "You can contact support via the 'Report Problem' tab in this screen, or email us directly at support@joul.com. We aim to respond within 24 hours.",
      ),
      _FaqItem(
        question: "Is my data secure?",
        answer:
            "Yes, we use industry-standard encryption to protect your data. Your personal information and building data are stored securely and are never shared with third parties without your consent.",
      ),
      _FaqItem(
        question: "How do I add a new tenant?",
        answer:
            "Navigate to the Building Detail screen, select the 'Tenants' tab (if available) or go to a Room and assign a tenant. You can also use the main 'Tenants' screen to manage all tenants.",
      ),
      _FaqItem(
        question: "Can I manage multiple buildings?",
        answer:
            "Yes! The app supports managing multiple buildings. You can switch between buildings from the home screen or the buildings list.",
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(
              faq.question,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            collapsedBackgroundColor: Colors.transparent,
            shape: const Border(), // Remove default border
            children: [
              Text(
                faq.answer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportProblemTab(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.describeProblem,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reportController,
            maxLines: 5,
            minLines: 3,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: localizations.enterProblemDescription,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement send report logic
              if (_reportController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.reportSent)),
                );
                _reportController.clear();
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
            child: Text(localizations.send),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}
