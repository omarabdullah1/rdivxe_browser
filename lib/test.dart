import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherExample extends StatelessWidget {
  const UrlLauncherExample({super.key});

  Future<void> launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
      'whatsapp://send?phone=201023096929&text=Hello%20World',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      print("Cannot launch WhatsApp");
      // Show a fallback error message
    }
  }

  Future<void> launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'omar.abdullah9825@gmail.com',
      query: 'subject=Hello&body=This%20is%20a%20test',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      print("Cannot launch email");
      // Show a fallback error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('URL Launcher Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: launchWhatsApp,
              child: const Text('Launch WhatsApp'),
            ),
            ElevatedButton(
              onPressed: launchEmail,
              child: const Text('Launch Email'),
            ),
          ],
        ),
      ),
    );
  }
}
