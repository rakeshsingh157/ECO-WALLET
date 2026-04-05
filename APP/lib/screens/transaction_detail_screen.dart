import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isSent = transaction['direction'] == 'sent';
    final amount = (transaction['amount'] ?? 0).toDouble();
    
    String extractName(dynamic data, String fallback) {
      if (data is Map) return data['name'] ?? data['user_id'] ?? fallback;
      if (data is String) return data;
      return fallback;
    }
    
    final name = isSent 
        ? (transaction['receiver_name'] ?? extractName(transaction['receiver'], 'Unknown')) 
        : (transaction['sender_name'] ?? extractName(transaction['sender'], 'Unknown'));
    final status = transaction['status'] ?? 'success';
    final timestamp = transaction['timestamp'] != null ? DateTime.tryParse(transaction['timestamp'].toString()) : null;
    final dateStr = timestamp != null ? DateFormat('MMMM d, yyyy • HH:mm:ss').format(timestamp.toLocal()) : 'Unknown Date';
    final String txnId = transaction['transaction_id'] ?? transaction['_id'] ?? 'N/A';
    final String description = transaction['description'] ?? 'No description provided';

    IconData statusIcon;
    Color statusColor;
    if (status == 'failed') {
      statusIcon = Icons.close;
      statusColor = Colors.orange;
    } else if (isSent) {
      statusIcon = Icons.arrow_outward;
      statusColor = EcoColors.error;
    } else {
      statusIcon = Icons.call_received;
      statusColor = EcoColors.primaryContainer;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transaction Details',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: EcoColors.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: EcoColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EcoColors.surfaceContainerHigh,
                border: Border.all(color: statusColor.withOpacity(0.3), width: 3),
              ),
              child: Icon(statusIcon, size: 36, color: statusColor),
            ),
            const SizedBox(height: 24),
            Text(
              '${isSent ? "-" : "+"}${NumberFormat('#,##0.00').format(amount)} ECO',
              style: GoogleFonts.spaceGrotesk(fontSize: 40, fontWeight: FontWeight.w700, color: statusColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status == 'success' ? EcoColors.success.withOpacity(0.1) : EcoColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'success' ? Icons.verified : Icons.error,
                    size: 14,
                    color: status == 'success' ? EcoColors.success : EcoColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: status == 'success' ? EcoColors.success : EcoColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildDetailCard(
              children: [
                _buildInfoRow('To / From', isSent ? 'Sent to $name' : 'Received from $name'),
                _buildInfoRow('Date & Time', dateStr),
                _buildInfoRow('Transaction ID', txnId),
                _buildInfoRow('Description', description),
                _buildInfoRow('Security', 'PIN Verified', icon: Icons.lock_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: EcoColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: EcoColors.primaryContainer),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: EcoColors.primary),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
