/// ECO Wallet — Transaction History Screen
/// Matches the history UI mockup: filter tabs, color-coded transaction list.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

import 'main_shell.dart';
import 'transaction_detail_screen.dart';
import '../providers/notification_provider.dart';
import 'notifications_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _page = 1;
    await context.read<WalletProvider>().fetchTransactions(filter: _filter, page: _page);
  }

  Future<void> _loadMore() async {
    _page++;
    await context.read<WalletProvider>().fetchTransactions(filter: _filter, page: _page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            automaticallyImplyLeading: false,
            backgroundColor: EcoColors.surface.withOpacity(0.8),
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => mainShellKey.currentState?.switchTab(3),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EcoColors.surfaceContainerHighest,
                      border: Border.all(color: EcoColors.primaryContainer.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.person, size: 20, color: EcoColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Text('ECO Wallet', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 3, color: EcoColors.primaryContainer)),
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

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title
                Text('History', style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, color: EcoColors.primary)),
                const SizedBox(height: 4),
                Text('Activity within the digital ether.', style: GoogleFonts.inter(fontSize: 14, color: EcoColors.onSurfaceVariant)),

                const SizedBox(height: 24),

                // Filter tabs
                Row(
                  children: ['all', 'sent', 'received'].map((f) {
                    final isActive = _filter == f;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _filter = f);
                        _load();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? EcoColors.primaryContainer : EcoColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          f.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: isActive ? EcoColors.surface : EcoColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Transaction list
                Consumer<WalletProvider>(
                  builder: (_, wallet, __) {
                    if (wallet.isLoading && wallet.transactions.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: EcoColors.primaryContainer, strokeWidth: 2),
                        ),
                      );
                    }

                    if (wallet.transactions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 48, color: EcoColors.onSurfaceVariant.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('No transactions found', style: GoogleFonts.inter(color: EcoColors.onSurfaceVariant)),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ...wallet.transactions.asMap().entries.map((entry) {
                          return _buildTxnCard(entry.value)
                              .animate(delay: (entry.key * 50).ms)
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.05);
                        }),
                        if (wallet.transactions.length < wallet.totalTransactions) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _loadMore,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(width: 40, height: 1, color: EcoColors.outlineVariant.withOpacity(0.2)),
                                  const SizedBox(width: 12),
                                  Text(
                                    'LOAD MORE ACTIVITY',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3, color: EcoColors.onSurfaceVariant.withOpacity(0.5)),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(width: 40, height: 1, color: EcoColors.outlineVariant.withOpacity(0.2)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxnCard(Map<String, dynamic> txn) {
    final isSent = txn['direction'] == 'sent';
    final amount = (txn['amount'] ?? 0).toDouble();
    final name = isSent
        ? (txn['receiver_name'] ?? txn['receiver_id'] ?? 'Unknown')
        : (txn['sender_name'] ?? txn['sender_id'] ?? 'Unknown');
    final status = txn['status'] ?? 'success';
    final timestamp = txn['timestamp'] != null ? DateTime.tryParse(txn['timestamp'].toString()) : null;
    final dateStr = timestamp != null ? DateFormat('MMM d, yyyy • HH:mm:ss').format(timestamp.toLocal()) : '';

    IconData statusIcon;
    Color statusColor;
    if (status == 'failed') {
      statusIcon = Icons.close;
      statusColor = Colors.orange;
    } else if (isSent) {
      statusIcon = Icons.arrow_outward;
      statusColor = EcoColors.primaryContainer;
    } else {
      statusIcon = Icons.call_received;
      statusColor = EcoColors.primaryContainer;
    }

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
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: EcoColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: EcoColors.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isSent ? "- " : "+ "}${NumberFormat('#,##0.00').format(amount)} ECO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSent ? EcoColors.error : EcoColors.primaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'success' ? Icons.check_circle : Icons.error,
                      size: 12,
                      color: status == 'success' ? EcoColors.success : EcoColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: status == 'success' ? EcoColors.success : EcoColors.error),
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
