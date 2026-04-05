import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

class SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> transactionData;

  const SuccessScreen({super.key, required this.transactionData});

  @override
  Widget build(BuildContext context) {
    final amount = (transactionData['amount'] ?? 0).toDouble();
    final receiverData = transactionData['receiver'];
    String receiver = 'Unknown';
    if (receiverData is Map) {
      receiver = receiverData['name'] ?? receiverData['user_id'] ?? 'Unknown';
    } else if (receiverData is String) {
      receiver = receiverData;
    }
    return Scaffold(
      backgroundColor: EcoColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated Checkmark Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EcoColors.success.withOpacity(0.1),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle, size: 80, color: EcoColors.success),
                ),
              ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 32),
              
              // Success Text
              Text(
                'Payment Successful',
                style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: EcoColors.primary),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 12),
              
              Text(
                'Your transaction to $receiver has been securely processed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: EcoColors.onSurfaceVariant),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 48),

              // Transaction Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: EcoColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      'AMOUNT SENT',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: EcoColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat('#,##0.00').format(amount)} ECO',
                      style: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms).slideY(begin: 0.2),

              const Spacer(),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop everything and go back to home shell
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EcoColors.primaryContainer,
                    foregroundColor: EcoColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'DONE',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
