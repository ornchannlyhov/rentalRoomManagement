import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    const htmlContent = '''
      <h1>Privacy Policy</h1>
      <p><strong>Last updated: December 6, 2025</strong></p>
      <p>Joul Inc. ("Company", "we", "us", or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our property management application.</p>

      <h2>1. Information We Collect</h2>
      
      <h3>1.1 Information You Provide</h3>
      <p>We collect information you provide directly, including:</p>
      <ul>
        <li><strong>Account Information:</strong> Name, phone number, and password when you register</li>
        <li><strong>Property Data:</strong> Building names, addresses, room numbers, utility rates, and rental prices</li>
        <li><strong>Tenant Information:</strong> Names, phone numbers, Telegram usernames, and room assignments that you enter</li>
        <li><strong>Payment Information:</strong> Bank account details and payment method preferences for receiving payments</li>
        <li><strong>Communications:</strong> Messages you send through our support channels</li>
      </ul>

      <h3>1.2 Information Collected Automatically</h3>
      <p>When you use the App, we automatically collect:</p>
      <ul>
        <li><strong>Device Information:</strong> Device type, operating system, unique device identifiers</li>
        <li><strong>Usage Data:</strong> Features used, actions taken, time and date of access</li>
        <li><strong>Log Data:</strong> IP address, browser type, pages visited, crash reports</li>
        <li><strong>Location Data:</strong> General location based on IP address (not precise GPS)</li>
      </ul>

      <h3>1.3 Information from Third Parties</h3>
      <p>We may receive information from payment processors (KHQR, ABA PayWay) regarding transaction status.</p>

      <h2>2. How We Use Your Information</h2>
      <p>We use your information to:</p>
      <ul>
        <li>Provide, maintain, and improve our property management services</li>
        <li>Process and track rent and utility payments</li>
        <li>Send notifications about receipts, payments, and important updates</li>
        <li>Generate reports and analytics for your properties</li>
        <li>Communicate with you about your account and respond to inquiries</li>
        <li>Detect, prevent, and address technical issues, fraud, or security threats</li>
        <li>Comply with legal obligations</li>
      </ul>

      <h2>3. Information Sharing</h2>
      <p>We may share your information in the following circumstances:</p>
      <ul>
        <li><strong>With Your Tenants:</strong> Tenant contact information and receipt details are shared with tenants via Telegram for billing purposes</li>
        <li><strong>Payment Processors:</strong> Payment information is shared with KHQR and ABA PayWay to process transactions</li>
        <li><strong>Service Providers:</strong> We use third-party services for hosting, analytics, and notifications (e.g., Firebase)</li>
        <li><strong>Legal Requirements:</strong> When required by law, court order, or government request</li>
        <li><strong>Business Transfers:</strong> In connection with a merger, acquisition, or sale of assets</li>
      </ul>
      <p><strong>We do not sell your personal information to third parties.</strong></p>

      <h2>4. Data Security</h2>
      <p>We implement industry-standard security measures to protect your data:</p>
      <ul>
        <li>Encryption of data in transit using TLS/SSL</li>
        <li>Secure storage of passwords using encryption</li>
        <li>Regular security audits and updates</li>
        <li>Access controls limiting who can view your data</li>
        <li>Secure authentication using OTP verification</li>
      </ul>
      <p>However, no method of transmission over the Internet is 100% secure. We cannot guarantee absolute security.</p>

      <h2>5. Data Retention</h2>
      <p>We retain your information for as long as:</p>
      <ul>
        <li>Your account is active</li>
        <li>Necessary to provide our services</li>
        <li>Required by law (e.g., financial records may be kept for 7 years)</li>
        <li>Needed to resolve disputes or enforce agreements</li>
      </ul>
      <p>You can request deletion of your account and data at any time.</p>

      <h2>6. Your Rights and Choices</h2>
      <p>You have the right to:</p>
      <ul>
        <li><strong>Access:</strong> Request a copy of your personal data</li>
        <li><strong>Correction:</strong> Update or correct inaccurate information</li>
        <li><strong>Deletion:</strong> Request deletion of your account and associated data</li>
        <li><strong>Portability:</strong> Receive your data in a structured, machine-readable format</li>
        <li><strong>Withdraw Consent:</strong> Opt out of marketing communications</li>
        <li><strong>Notifications:</strong> Manage notification preferences in app settings</li>
      </ul>
      <p>To exercise these rights, contact us at privacy@joul.app.</p>

      <h2>7. Tenant Data</h2>
      <p><strong>Important:</strong> As a property manager using Joul, you are responsible for:</p>
      <ul>
        <li>Obtaining appropriate consent from tenants before entering their data</li>
        <li>Ensuring tenant data is accurate and up-to-date</li>
        <li>Responding to tenant requests regarding their personal data</li>
        <li>Complying with local data protection laws</li>
      </ul>
      <p>We act as a data processor for tenant data that you provide.</p>

      <h2>8. Children's Privacy</h2>
      <p>The App is not intended for users under 18 years of age. We do not knowingly collect personal information from children. If we discover that a child has provided us with personal information, we will delete it promptly.</p>

      <h2>9. International Data Transfers</h2>
      <p>Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your data during such transfers.</p>

      <h2>10. Third-Party Links</h2>
      <p>The App may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies.</p>

      <h2>11. Changes to This Policy</h2>
      <p>We may update this Privacy Policy from time to time. We will notify you of significant changes through the App or via your registered phone number. The "Last updated" date at the top indicates when the policy was last revised.</p>

      <h2>12. Contact Us</h2>
      <p>If you have questions or concerns about this Privacy Policy or our data practices, please contact us:</p>
      <ul>
        <li>Email: privacy@joul.app</li>
        <li>Support: support@joul.app</li>
        <li>Telegram: @JoulSupport</li>
      </ul>

      <hr>
      <p><em>By using Joul, you acknowledge that you have read and understood this Privacy Policy.</em></p>
    ''';

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.privacyPolicy),
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
