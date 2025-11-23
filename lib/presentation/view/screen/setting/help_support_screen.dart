import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
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
    // Mock data for FAQs - supporting both HTML and Markdown-like syntax via HtmlWidget
    const faqsContent = '''
      <h3>How do I reset my password?</h3>
      <p>You can reset your password by going to the login screen and clicking on "Forgot Password".</p>
      
      <h3>How do I contact support?</h3>
      <p>You can contact support via the "Report Problem" tab or email us at support@joul.com.</p>
      
      <h3>Is my data secure?</h3>
      <p>Yes, we use industry-standard encryption to protect your data.</p>
      
      <h3>Markdown Style Test</h3>
      <p>This is <b>bold</b> text and this is <i>italic</i> text.</p>
      <ul>
        <li>List item 1</li>
        <li>List item 2</li>
      </ul>
    ''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: HtmlWidget(
        faqsContent,
        textStyle: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildReportProblemTab(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return Padding(
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
          const SizedBox(height: 16),
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
