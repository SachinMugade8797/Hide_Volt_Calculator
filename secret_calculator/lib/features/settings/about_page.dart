import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.calculate_outlined,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Secret Calculator',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 35),
          _tile(
            Icons.privacy_tip_outlined,
            'Privacy Policy',
            'Read our privacy policy',
                () {
              // Open Privacy Policy
            },
          ),
          const SizedBox(height: 10),
          _tile(
            Icons.description_outlined,
            'Terms of Use',
            'Read terms and conditions',
                () {
              // Open Terms
            },
          ),
          const SizedBox(height: 10),
          _tile(
            Icons.code_outlined,
            'Open Source Licenses',
            'View third-party licenses',
                () {
              // Open licenses
            },
          ),
          const SizedBox(height: 10),
          _tile(
            Icons.support_agent_outlined,
            'Contact Support',
            'Get help with the application',
                () {
              // Contact support
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: const Color(0xFF121212),
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
      ),
    );
  }
}