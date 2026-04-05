/// ECO Wallet — Home Dashboard Screen
/// Matches the dashboard UI mockup: balance card, quick actions, reward banner, recent activity.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/notification_provider.dart';
import 'send_screen.dart';
import 'receive_screen.dart';
import 'scanner_screen.dart';
import 'history_screen.dart';
import 'main_shell.dart';
import 'transaction_detail_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wallet = context.read<WalletProvider>();
    final auth = context.read<AuthProvider>();
    final notif = context.read<NotificationProvider>();
    await Future.wait([
      auth.refreshUser(),
      wallet.fetchTransactions(),
      wallet.fetchBankStatus(),
      notif.fetchUnreadCount(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: EcoColors.primaryContainer,
        backgroundColor: EcoColors.surfaceContainerHigh,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              backgroundColor: EcoColors.surface.withOpacity(0.8),
              title: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => mainShellKey.currentState?.switchTab(3),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EcoColors.surfaceContainerHighest,
                        border: Border.all(
                          color: EcoColors.primaryContainer.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(Icons.person, size: 20, color: EcoColors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ECO Wallet',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: EcoColors.primaryContainer,
                    ),
                  ),
                ],
              ),
              actions: [
                Consumer<NotificationProvider>(
                  builder: (_, notif, __) => Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: EcoColors.primaryContainer),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                        },
                      ),
                      if (notif.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: EcoColors.error,
                            ),
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

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ─── Balance Card ─────────────────
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => _buildBalanceCard(auth),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

                  const SizedBox(height: 28),

                  // ─── Quick Actions ────────────────
                  _buildQuickActions().animate(delay: 100.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // ─── Reward Banner ────────────────
                  _buildRewardBanner().animate(delay: 200.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // ─── Recent Activity ──────────────
                  _buildRecentActivity().animate(delay: 300.ms).fadeIn(duration: 400.ms),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [EcoColors.primaryContainer, EcoColors.onPrimaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: EcoColors.surfaceTint.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dot pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),
          // Decorative glow
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EcoColors.primary.withOpacity(0.15),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'TOTAL BALANCE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: EcoColors.surface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _hideBalance = !_hideBalance),
                    child: Icon(
                      _hideBalance ? Icons.visibility_off : Icons.visibility,
                      color: EcoColors.surface.withOpacity(0.7),
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _hideBalance ? '••••••' : '${NumberFormat('#,##0').format(auth.balance)} ECO',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: EcoColors.surface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: EcoColors.surface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 14, color: EcoColors.surface.withOpacity(0.9)),
                    const SizedBox(width: 4),
                    Text(
                      'Wallet active',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.surface.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(Icons.send, 'SEND', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SendScreen()));
        }),
        _actionButton(Icons.download, 'RECEIVE', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveScreen()));
        }),
        _actionButton(Icons.qr_code_scanner, 'SCAN QR', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
        }),
        _actionButton(Icons.list_alt, 'HISTORY', () {
          mainShellKey.currentState?.switchTab(1);
        }),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EcoColors.surfaceContainerHigh,
              boxShadow: [
                BoxShadow(
                  color: EcoColors.primaryContainer.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(icon, color: EcoColors.primaryContainer, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: EcoColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBanner() {
    return GestureDetector(
      onTap: () => mainShellKey.currentState?.switchTab(2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(color: EcoColors.primaryContainer, width: 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EcoColors.primaryContainer.withOpacity(0.1),
              ),
              child: const Icon(Icons.workspace_premium, color: EcoColors.primaryContainer, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New rewards available',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: EcoColors.primary,
                    ),
                  ),
                  Text(
                    'Complete tasks to earn ECO coins.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: EcoColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'EARN',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: EcoColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<WalletProvider>(
      builder: (_, wallet, __) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: EcoColors.primary,
                  ),
                ),
                GestureDetector(
                  onTap: () => mainShellKey.currentState?.switchTab(1),
                  child: Text(
                    'VIEW ALL',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: EcoColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (wallet.transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 40, color: EcoColors.onSurfaceVariant.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions yet',
                      style: GoogleFonts.inter(fontSize: 14, color: EcoColors.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ...wallet.transactions.take(5).map((txn) => _buildTxnItem(txn)),
          ],
        );
      },
    );
  }

  Widget _buildTxnItem(Map<String, dynamic> txn) {
    final isSent = txn['direction'] == 'sent';
    final amount = (txn['amount'] ?? 0).toDouble();
    final name = isSent ? (txn['receiver_name'] ?? txn['receiver_id']) : (txn['sender_name'] ?? txn['sender_id']);
    final status = txn['status'] ?? 'success';
    final timestamp = txn['timestamp'] != null ? DateTime.tryParse(txn['timestamp'].toString()) : null;
    final dateStr = timestamp != null ? DateFormat('MMM d, h:mm a').format(timestamp.toLocal()) : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: txn)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EcoColors.surfaceContainerHighest,
              ),
              child: Icon(
                isSent ? Icons.arrow_outward : Icons.call_received,
                color: isSent
                    ? (status == 'failed' ? Colors.orange : EcoColors.error)
                    : EcoColors.primaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSent ? 'Sent to $name' : 'Received from $name',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: EcoColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(fontSize: 12, color: EcoColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isSent ? '-' : '+'} ${NumberFormat('#,##0.##').format(amount)} ECO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSent ? EcoColors.error : EcoColors.primaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'success' ? Icons.check_circle : Icons.cancel,
                      size: 12,
                      color: status == 'success' ? EcoColors.success : EcoColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: status == 'success' ? EcoColors.success : EcoColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle dot pattern for the balance card
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
