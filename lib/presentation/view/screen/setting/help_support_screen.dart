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
        question: "How do I add a new building?",
        answer:
            "Go to the Buildings tab and tap the '+' button. Fill in the building details including name, passkey, rent price, and utility rates (electricity and water per unit).",
      ),
      _FaqItem(
        question: "How do I assign a tenant to a room?",
        answer:
            "From the Tenants screen, create a new tenant and select their room. Or from a Room's detail page, tap 'Add Tenant' to assign a tenant.",
      ),
      _FaqItem(
        question: "How are receipts generated?",
        answer:
            "Receipts are created each month for occupied rooms. You'll receive a notification to confirm meter readings. Once confirmed, the receipt is generated with calculated costs.",
      ),
      _FaqItem(
        question: "How do tenants pay their bills?",
        answer:
            "Tenants receive payment links via Telegram. They can pay using KHQR or ABA PayWay. Once payment is confirmed, the receipt status updates to 'Paid'.",
      ),
      _FaqItem(
        question: "How do I mark a receipt as paid manually?",
        answer:
            "Swipe right on any receipt in the list to toggle its payment status between 'Paid' and 'Pending'.",
      ),
      _FaqItem(
        question: "Is my data secure?",
        answer:
            "Yes, all data is encrypted in transit. Your personal information and building data are stored securely and never shared without your consent.",
      ),
      _FaqItem(
        question: "How do I reset my password?",
        answer:
            "Tap 'Forgot Password' on the login screen, enter your phone number, and follow the OTP verification process to create a new password.",
      ),
      _FaqItem(
        question: "How do I contact support?",
        answer:
            "Use the 'Report Problem' tab above, email support@joul.app, or contact us via Telegram at @JoulSupport. We respond within 24 hours.",
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
