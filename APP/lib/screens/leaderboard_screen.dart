/// ECO Wallet — Global Leaderboard Screen
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/wallet_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.surface,
      appBar: AppBar(
        backgroundColor: EcoColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EcoColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Global Leaderboard',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: EcoColors.primary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<WalletProvider>(
        builder: (_, wallet, __) {
          final leaders = wallet.leaderboard;
          if (leaders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_outlined, size: 64, color: EcoColors.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No leaderboard data yet',
                    style: GoogleFonts.inter(fontSize: 16, color: EcoColors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: leaders.length,
            itemBuilder: (context, index) {
              final leader = leaders[index];
              final rank = leader['rank'] ?? (index + 1);
              final isTopThree = rank <= 3;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isTopThree
                      ? EcoColors.primaryContainer.withOpacity(0.08)
                      : EcoColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: isTopThree
                      ? Border.all(color: EcoColors.primaryContainer.withOpacity(0.2), width: 1)
                      : null,
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 36,
                      child: rank <= 3
                          ? Icon(
                              Icons.emoji_events,
                              color: rank == 1
                                  ? const Color(0xFFFFD700)
                                  : rank == 2
                                      ? const Color(0xFFC0C0C0)
                                      : const Color(0xFFCD7F32),
                              size: 24,
                            )
                          : Text(
                              '${rank < 10 ? '0' : ''}$rank',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: EcoColors.primaryContainer,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            EcoColors.primaryContainer.withOpacity(0.5),
                            EcoColors.onPrimaryContainer,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (leader['name'] ?? 'U').substring(0, 1).toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: EcoColors.surface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leader['name'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: EcoColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rank #$rank',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: EcoColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Balance
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat('#,##0').format((leader['balance'] ?? 0).toDouble()),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: EcoColors.primaryContainer,
                          ),
                        ),
                        Text(
                          'ECO',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: EcoColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate(delay: (index * 50).ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05);
            },
          );
        },
      ),
    );
  }
}
