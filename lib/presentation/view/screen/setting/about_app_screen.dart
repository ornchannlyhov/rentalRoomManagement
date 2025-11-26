import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Mock content for About App - supporting HTML/MD
    const aboutContent = '''
      <div style="text-align: center;">
        <img src="asset:assets/logo/joul_logo.png" width="100" height="100" />
        <h2>Joul App</h2>
        <p>Version 1.0.0</p>
      </div>
      <br />
      <h3>About Us</h3>
      <p>Joul is a comprehensive building management solution designed to streamline your operations.</p>
      
      <h3>Terms of Service</h3>
      <p>By using this app, you agree to our <a href="https://joul.com/terms">Terms of Service</a>.</p>
      
      <h3>Privacy Policy</h3>
      <p>We value your privacy. Read our <a href="https://joul.com/privacy">Privacy Policy</a>.</p>
      
      <h3>Credits</h3>
      <p>Developed by the Joul Team.</p>
    ''';

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.about),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HtmlWidget(
          aboutContent,
          textStyle: Theme.of(context).textTheme.bodyMedium,
          onTapUrl: (url) {
            // TODO: Implement URL launching
            return true;
          },
        ),
      ),
    );
  }
}
