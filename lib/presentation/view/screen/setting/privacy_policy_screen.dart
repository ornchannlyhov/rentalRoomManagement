import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const htmlContent = '''
      <h1>Privacy Policy</h1>
      <p>Last updated: November 30, 2025</p>

      <h2>1. Introduction</h2>
      <p>Joul is committed to protecting your privacy. This Privacy Policy explains how your personal information is collected, used, and disclosed by Joul.</p>

      <h2>2. Information We Collect</h2>
      <p>We collect information you provide directly to us, such as when you create an account, update your profile, or communicate with us. This may include your name, email address, phone number, and building management data.</p>

      <h2>3. How We Use Your Information</h2>
      <p>We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to protect our users.</p>

      <h2>4. Data Security</h2>
      <p>We implement appropriate technical and organizational measures to protect the security of your personal information.</p>

      <h2>5. Sharing of Information</h2>
      <p>We do not share your personal information with third parties except as described in this policy or with your consent.</p>

      <h2>6. Your Rights</h2>
      <p>You have the right to access, correct, or delete your personal information. You can manage your information through your account settings.</p>

      <h2>7. Contact Us</h2>
      <p>If you have any questions about this Privacy Policy, please contact us at privacy@joul.com.</p>
    ''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
