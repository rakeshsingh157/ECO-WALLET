/// ECO Wallet — Receive Money Screen
/// Shows user QR code, wallet ID, share options.
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/notification_provider.dart';
import 'notifications_screen.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  double? _customAmount;

  @override
  void initState() {
    super.initState();
    context.read<WalletProvider>().fetchQR();
  }

  Future<void> _shareQR() async {
    final wallet = context.read<WalletProvider>();
    if (wallet.qrImage == null) return;
    try {
      final bytes = base64Decode(wallet.qrImage!.split(',').last);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/eco_qr_code.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Scan to pay me on ECO Wallet!');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing QR: $e')));
    }
  }

  void _showSetAmountDialog() {
    final TextEditingController amtCtrl = TextEditingController(text: _customAmount?.toStringAsFixed(2) ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EcoColors.surfaceContainerLow,
        title: Text('Set Amount', style: GoogleFonts.spaceGrotesk(color: EcoColors.primary)),
        content: TextField(
          controller: amtCtrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: EcoColors.primary),
          decoration: const InputDecoration(
            hintText: 'e.g. 50.00',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amtCtrl.text.trim());
              Navigator.pop(ctx);
              setState(() => _customAmount = val);
              context.read<WalletProvider>().fetchQR(amount: val);
            },
            child: const Text('Set'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final userId = auth.userId;
    final truncatedId = userId.length > 8 ? '${userId.substring(0, 4)}...${userId.substring(userId.length - 4)}' : userId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EcoColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Receive Money',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: EcoColors.primaryContainer,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, notif, __) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: EcoColors.primaryContainer), 
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  }
                ),
                if (notif.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: EcoColors.error),
                      child: Center(
                        child: Text(
                          '${notif.unreadCount}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Text(
              'YOUR UNIQUE IDENTIFIER',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: EcoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'eco.wallet/${auth.userName.toLowerCase().replaceAll(' ', '_')}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: EcoColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            // QR Code container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: EcoColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: EcoColors.outlineVariant.withOpacity(0.15),
                ),
              ),
              child: wallet.qrImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(wallet.qrImage!.split(',').last),
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    )
                  : SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: EcoColors.primaryContainer,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),

            if (_customAmount != null && _customAmount! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Amount: ${_customAmount!.toStringAsFixed(2)} ECO',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: EcoColors.primaryContainer),
                ),
              ),

            const SizedBox(height: 24),

            // Wallet ID
            Text(
              'WALLET ID',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: EcoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: userId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wallet ID copied!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: EcoColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      truncatedId,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: EcoColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy, size: 16, color: EcoColors.primaryContainer),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Share QR button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(48),
                  gradient: const LinearGradient(colors: [EcoColors.primaryContainer, EcoColors.primaryFixedDim]),
                  boxShadow: [BoxShadow(color: EcoColors.primaryContainer.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: ElevatedButton.icon(
                  onPressed: _shareQR,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48))),
                  icon: const Icon(Icons.share, color: EcoColors.surface),
                  label: Text('Share QR', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: EcoColors.surface)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Scanning this QR code allows others to send\ndigital assets directly to your ECO Wallet instantly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: EcoColors.onSurfaceVariant,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            // Bottom actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _shareQR();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the Share menu to save the image!')));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: EcoColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.download, color: EcoColors.primaryContainer),
                          const SizedBox(height: 8),
                          Text('SAVE IMAGE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: EcoColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _showSetAmountDialog,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: EcoColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.attach_money, color: EcoColors.primaryContainer),
                          const SizedBox(height: 8),
                          Text('SET AMOUNT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: EcoColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
