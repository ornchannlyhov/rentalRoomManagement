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
      <p><strong>Last updated: December 6, 2025</strong></p>
      <p>Welcome to Joul. Please read these Terms of Service ("Terms") carefully before using our property management application.</p>

      <h2>1. Acceptance of Terms</h2>
      <p>By downloading, installing, or using the Joul application ("App"), you agree to be bound by these Terms. If you do not agree to these Terms, do not use the App.</p>
      <p>These Terms constitute a legally binding agreement between you and Joul Inc. ("Company", "we", "us", or "our") regarding your use of the App and related services.</p>

      <h2>2. Eligibility</h2>
      <p>You must be at least 18 years old to use this App. By using the App, you represent and warrant that you are at least 18 years of age and have the legal capacity to enter into these Terms.</p>

      <h2>3. Description of Service</h2>
      <p>Joul is a property management platform that enables landlords and property managers to:</p>
      <ul>
        <li>Manage buildings, rooms, and rental units</li>
        <li>Track and manage tenants and their information</li>
        <li>Generate and manage monthly utility receipts</li>
        <li>Process rent and utility payments</li>
        <li>Communicate with tenants via integrated messaging</li>
        <li>Generate reports and analytics</li>
      </ul>

      <h2>4. Account Registration</h2>
      <p><strong>4.1 Account Creation:</strong> To use certain features, you must create an account by providing accurate, current, and complete information including your phone number.</p>
      <p><strong>4.2 Account Security:</strong> You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized access or use of your account.</p>
      <p><strong>4.3 One Account Per User:</strong> You may only maintain one account. Duplicate accounts may be terminated without notice.</p>

      <h2>5. User Responsibilities</h2>
      <p>You agree to:</p>
      <ul>
        <li>Provide accurate and truthful information about yourself, your properties, and your tenants</li>
        <li>Use the App only for lawful purposes related to property management</li>
        <li>Obtain necessary consent from tenants before storing or processing their personal data</li>
        <li>Comply with all applicable laws, including landlord-tenant regulations in your jurisdiction</li>
        <li>Not use the App to harass, abuse, or harm others</li>
        <li>Not attempt to gain unauthorized access to our systems or other users' accounts</li>
      </ul>

      <h2>6. Payment Processing</h2>
      <p><strong>6.1 Third-Party Services:</strong> Payments are processed through third-party payment providers (KHQR, ABA PayWay). Your use of these services is subject to their respective terms and conditions.</p>
      <p><strong>6.2 Transaction Fees:</strong> We may charge fees for payment processing. Current fee structures are available in the App.</p>
      <p><strong>6.3 Disputes:</strong> Payment disputes between landlords and tenants are the responsibility of the involved parties. We are not liable for payment disputes.</p>

      <h2>7. Data and Content</h2>
      <p><strong>7.1 Your Data:</strong> You retain ownership of all data and content you upload to the App, including building information, tenant data, and receipts.</p>
      <p><strong>7.2 License Grant:</strong> By using the App, you grant us a non-exclusive license to use, store, and process your data solely for providing our services.</p>
      <p><strong>7.3 Data Accuracy:</strong> You are responsible for the accuracy of data you enter. We are not liable for errors resulting from inaccurate input.</p>

      <h2>8. Intellectual Property</h2>
      <p>The App, including its design, features, code, and content, is owned by Joul Inc. and protected by intellectual property laws. You may not copy, modify, distribute, or reverse engineer any part of the App.</p>

      <h2>9. Limitation of Liability</h2>
      <p><strong>9.1 No Warranty:</strong> The App is provided "as is" without warranties of any kind, either express or implied.</p>
      <p><strong>9.2 Limited Liability:</strong> To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of data, revenue, or profits.</p>
      <p><strong>9.3 Maximum Liability:</strong> Our total liability shall not exceed the amount you paid us in the 12 months preceding the claim.</p>

      <h2>10. Termination</h2>
      <p><strong>10.1 By You:</strong> You may stop using the App and delete your account at any time.</p>
      <p><strong>10.2 By Us:</strong> We may suspend or terminate your access if you violate these Terms or for any other reason at our discretion.</p>
      <p><strong>10.3 Effect of Termination:</strong> Upon termination, your right to use the App ceases immediately. We may retain your data as required by law.</p>

      <h2>11. Changes to Terms</h2>
      <p>We reserve the right to modify these Terms at any time. We will notify you of significant changes through the App or via your registered phone number. Continued use after changes constitutes acceptance of the new Terms.</p>

      <h2>12. Governing Law</h2>
      <p>These Terms shall be governed by and construed in accordance with the laws of the Kingdom of Cambodia, without regard to conflict of law principles.</p>

      <h2>13. Dispute Resolution</h2>
      <p>Any disputes arising from these Terms or your use of the App shall be resolved through good-faith negotiation. If negotiation fails, disputes shall be submitted to the courts of Phnom Penh, Cambodia.</p>

      <h2>14. Contact Information</h2>
      <p>For questions about these Terms, please contact us:</p>
      <ul>
        <li>Email: legal@joul.app</li>
        <li>Support: support@joul.app</li>
        <li>Telegram: @JoulSupport</li>
      </ul>

      <hr>
      <p><em>By using Joul, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.</em></p>
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
