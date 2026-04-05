import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Support',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: EcoColors.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: EcoColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: EcoColors.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EcoColors.primaryContainer.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.help_outline, size: 48, color: EcoColors.primaryContainer),
                  const SizedBox(height: 16),
                  Text(
                    'How can we help?',
                    style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: EcoColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reach out to our support team for any issues regarding rewards or transactions.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: EcoColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening email client...')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoColors.primaryContainer,
                      foregroundColor: EcoColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Email Support', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: EcoColors.primary),
            ),
            const SizedBox(height: 16),
            _buildFaqItem('My rewards are not adding up?', 'Ensure you watch the entire video ad. Rewards are processed via our backend in real-time. If there is a delay, please refresh your home screen.'),
            _buildFaqItem('How do I reset my PIN?', 'You can change your PIN natively in your profile settings toggles by turning it off and on again.'),
            _buildFaqItem('Is there a limit on transfers?', 'Transfers are limited to your total earned ECO coin pool. Currently, maximum one-time transfer allowed is 50,000 ECO.'),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: EcoColors.primaryContainer,
          collapsedIconColor: EcoColors.onSurfaceVariant,
          title: Text(
            question,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: EcoColors.primary),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.inter(fontSize: 13, color: EcoColors.onSurfaceVariant, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
