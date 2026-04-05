import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: EcoColors.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: EcoColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Terms',
              style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: EcoColors.primary),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Data Collection',
              'ECO Wallet collects minimal data required to process your tasks and transactions securely. We store your encrypted PIN and balance logs in a secure, audited backend structure.',
            ),
            _buildSection(
              '2. Usage of Information',
              'Your information is used strictly to power peer-to-peer transfers, issue rewards for verified tasks, and show relevant Google Mobile Ads (using generic Admob standards).',
            ),
            _buildSection(
              '3. Security',
              'We employ bank-grade security and full atomic database transactions to ensure your balance is never duplicated or lost during transfers.',
            ),
            _buildSection(
              '4. Third-Party Services',
              'We use Google AdMob for rendering rewarded advertisements. Please refer to Google\'s privacy policies to see how they handle advertising IDs.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last updated: April 2026',
                style: GoogleFonts.inter(fontSize: 12, color: EcoColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: EcoColors.primaryContainer),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(fontSize: 14, color: EcoColors.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}
