import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

class SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> transactionData;
  final String? fallbackReceiverName;

  const SuccessScreen({
    super.key,
    required this.transactionData,
    this.fallbackReceiverName,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (transactionData['amount'] ?? 0).toDouble();
    
    String receiver = '';
    if (fallbackReceiverName != null && fallbackReceiverName!.trim().isNotEmpty && fallbackReceiverName != 'Unknown') {
      receiver = fallbackReceiverName!.trim();
    }
    
    if (receiver.isEmpty || receiver == 'Unknown') {
      final recName = transactionData['receiver_name'];
      if (recName != null && recName.toString().trim().isNotEmpty && recName.toString() != 'Unknown') {
        receiver = recName.toString().trim();
      }
    }

    if (receiver.isEmpty || receiver == 'Unknown') {
      final rec = transactionData['receiver'];
      if (rec is Map && rec['name'] != null && rec['name'].toString().trim().isNotEmpty) {
        receiver = rec['name'].toString().trim();
      } else if (rec is String && rec.trim().isNotEmpty && rec != 'Unknown') {
        receiver = rec.trim();
      }
    }

    if (receiver.isEmpty || receiver == 'Unknown') {
      final shop = transactionData['shop_name'] ?? transactionData['receiver_id'];
      if (shop != null && shop.toString().trim().isNotEmpty) {
        receiver = shop.toString().trim();
      }
    }

    if (receiver.isEmpty || receiver == 'Unknown') {
      receiver = 'Merchant Store';
    }

    final txnId = transactionData['transaction_id'] ?? transactionData['payment_id'] ?? '';

    return Scaffold(
      backgroundColor: EcoColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EcoColors.success.withValues(alpha: 0.12),
                  border: Border.all(color: EcoColors.success.withValues(alpha: 0.3), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded, size: 64, color: EcoColors.success),
                ),
              ).animate().scale(delay: 150.ms, duration: 500.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 24),
              
              Text(
                'Payment Successful',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: EcoColors.onSurface,
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: EcoColors.primaryContainer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EcoColors.primaryContainer.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'PAID TO',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: EcoColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      receiver,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: EcoColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: EcoColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: EcoColors.outlineVariant.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      'AMOUNT TRANSFERRED',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: EcoColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${NumberFormat('#,##0.00').format(amount)} ECO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: EcoColors.primaryContainer,
                      ),
                    ),
                    if (txnId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'TXN ID: $txnId',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: EcoColors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 650.ms, duration: 400.ms).slideY(begin: 0.2),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
