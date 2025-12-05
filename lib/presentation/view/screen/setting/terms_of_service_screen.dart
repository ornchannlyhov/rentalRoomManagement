import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    const htmlContent = '''
      <h1>Terms of Service</h1>
      <p>Last updated: November 30, 2025</p>

      <h2>1. Acceptance of Terms</h2>
      <p>By accessing and using the Joul application, you accept and agree to be bound by the terms and provision of this agreement.</p>

      <h2>2. Description of Service</h2>
      <p>Joul provides a building management platform that allows users to manage rooms, tenants, services, and reports.</p>

      <h2>3. User Account</h2>
      <p>To use certain features of the app, you may be required to create an account. You are responsible for maintaining the confidentiality of your account and password.</p>

      <h2>4. User Conduct</h2>
      <p>You agree to use the app only for lawful purposes. You are prohibited from posting or transmitting any unlawful, threatening, libelous, defamatory, obscene, or profane material.</p>

      <h2>5. Termination</h2>
      <p>We may terminate or suspend access to our service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.</p>

      <h2>6. Changes to Terms</h2>
      <p>We reserve the right, at our sole discretion, to modify or replace these Terms at any time.</p>

      <h2>7. Contact Us</h2>
      <p>If you have any questions about these Terms, please contact us at support@joul.com.</p>
    ''';

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.termsOfService),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HtmlWidget(
          htmlContent,
          textStyle: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
