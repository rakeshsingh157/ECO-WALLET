/// ECO Wallet — Rewards & Tasks Screen
/// Matches rewards UI mockup: weekly momentum, tasks, leaderboard.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/notification_provider.dart';
import 'main_shell.dart';
import 'notifications_screen.dart';
import 'leaderboard_screen.dart';
import 'invite_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isProcessing = false;
  
  // Use test ad in debug mode; replace with real ad unit ID for release
  final String _adUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/5224354917' // Test dummy ad unit ID
      : 'ca-app-pub-3940256099942544/5224354917'; // TODO: Provide Real Ad Unit ID for Production

  @override
  void initState() {
    super.initState();
    _load();
    _loadAd();
  }

  void _loadAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          if (mounted) setState(() => _isAdLoaded = true);
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (mounted) setState(() {
                _isAdLoaded = false;
                _isProcessing = false;
              });
              _loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (mounted) setState(() {
                _isAdLoaded = false;
                _isProcessing = false;
              });
              _loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          if (mounted) setState(() => _isAdLoaded = false);
          // Retry after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _loadAd();
          });
        },
      ),
    );
  }

  Future<void> _load() async {
    final wallet = context.read<WalletProvider>();
    await Future.wait([
      wallet.fetchTasks(),
      wallet.fetchLeaderboard(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            color: EcoColors.primaryContainer,
            backgroundColor: EcoColors.surfaceContainerHigh,
            onRefresh: _load,
            child: CustomScrollView(
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
              sliver: Consumer<WalletProvider>(
                builder: (_, wallet, __) {
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // Weekly momentum
                      Text('WEEKLY MOMENTUM', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3, color: EcoColors.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            NumberFormat('#,##0').format(wallet.weeklyEarnings),
                            style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, color: EcoColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Text('ECO', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep earning to reach your weekly milestone.',
                        style: GoogleFonts.inter(fontSize: 13, color: EcoColors.onSurfaceVariant),
                      ),

                      const SizedBox(height: 20),

                      // Progress bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: EcoColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Goal: 1,000 ECO', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: EcoColors.primary)),
                                Text(
                                  '${((wallet.weeklyEarnings / 1000) * 100).clamp(0, 100).toInt()}% COMPLETE',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: EcoColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (wallet.weeklyEarnings / 1000).clamp(0, 1),
                                backgroundColor: EcoColors.surfaceContainerHighest,
                                color: EcoColors.primaryContainer,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Available tasks
                      Text('Available Tasks', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: EcoColors.primary)),
                      const SizedBox(height: 16),

                      if (wallet.isLoading && wallet.tasks.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: EcoColors.primaryContainer, strokeWidth: 2)))
                      else
                        ...wallet.tasks.asMap().entries.map((entry) {
                          return _buildTaskCard(entry.value, wallet)
                              .animate(delay: (entry.key * 80).ms)
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.05);
                        }),

                      const SizedBox(height: 32),

                      // Leaderboard
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Network Leaders', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: EcoColors.primary)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                            },
                            child: Text('VIEW ALL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: EcoColors.primaryContainer)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ...wallet.leaderboard.take(5).map((leader) => _buildLeaderRow(leader)),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      if (_isProcessing)
        Container(
          color: Colors.black54,
          child: const Center(
            child: CircularProgressIndicator(color: EcoColors.primaryContainer),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTaskCard(Map<String, dynamic> task, WalletProvider wallet) {
    final completed = task['completed'] == true;
    final iconName = task['icon'] ?? 'star';
    final reward = (task['reward_amount'] ?? 0).toDouble();
    final category = task['category'] ?? 'general';
    final isAdTask = category == 'ad';
    final isInvite = task['title'] == 'Invite Friends';
    final buttonText = isAdTask ? 'WATCH AD' : (isInvite ? 'COPY CODE' : 'COMPLETE');
    final iconMap = {
      'group_add': Icons.group_add,
      'play_circle': Icons.play_circle,
      'login': Icons.login,
      'account_balance_wallet': Icons.account_balance_wallet,
      'eco': Icons.eco,
      'badge': Icons.badge,
      'send': Icons.send,
      'star': Icons.star,
    };

    return Container(
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
              color: completed
                  ? EcoColors.primaryContainer.withOpacity(0.1)
                  : EcoColors.surfaceContainerHighest,
            ),
            child: Icon(
              iconMap[iconName] ?? Icons.star,
              color: EcoColors.primaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task['title'] ?? '', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: EcoColors.primary)),
                const SizedBox(height: 2),
                Text(task['description'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: EcoColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (!completed || task['repeatable'] == true) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      if (_isProcessing) return;

                      if (isInvite) {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const InviteScreen()),
                        );
                        return;
                      }

                      setState(() {
                         _isProcessing = true;
                      });

                      if (isAdTask) {
                        try {
                          if (!_isAdLoaded || _rewardedAd == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Loading Ad, please wait...')),
                            );
                            _loadAd();
                            setState(() { _isProcessing = false; });
                            return;
                          }

                          // Call start task
                          final startRes = await wallet.startTask(task['task_id']);
                          if (startRes['success'] != true) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(startRes['message'] ?? 'Failed to start task')),
                              );
                              setState(() { _isProcessing = false; });
                            }
                            return;
                          }

                          // Show the rewarded ad
                          _rewardedAd!.show(
                            onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) async {
                              // Call backend to verify and complete
                              final res = await wallet.completeTask(task['task_id']);
                              if (res['success'] == true && mounted) {
                                final auth = context.read<AuthProvider>();
                                auth.updateBalance((res['data']['new_balance'] ?? auth.balance).toDouble());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Earned ${res['data']['reward']} ECO!')),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'] ?? 'Failed')),
                                );
                              }
                              if (mounted) {
                                setState(() {
                                  _isProcessing = false;
                                });
                              }
                            },
                          );
                        } catch (e) {
                          if (mounted) setState(() { _isProcessing = false; });
                        }
                      } else {
                        try {
                          // Logic for non-ad tasks (e.g. daily claim, general tasks)
                          final startRes = await wallet.startTask(task['task_id']);
                          if (startRes['success'] != true) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(startRes['message'] ?? 'Failed to start task')),
                              );
                              setState(() { _isProcessing = false; });
                            }
                            return;
                          }

                          // For automated claim tasks, we can complete immediately after starting
                          final res = await wallet.completeTask(task['task_id']);
                          if (res['success'] == true && mounted) {
                            final auth = context.read<AuthProvider>();
                            auth.updateBalance((res['data']['new_balance'] ?? auth.balance).toDouble());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Earned ${res['data']['reward']} ECO!')),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] ?? 'Failed')),
                            );
                          }
                          if (mounted) setState(() { _isProcessing = false; });
                        } catch (e) {
                          if (mounted) setState(() { _isProcessing = false; });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: EcoColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        buttonText,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: EcoColors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${reward.toInt()} ECO',
                style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer),
              ),
              if (completed && task['repeatable'] != true) ...[
                const SizedBox(height: 4),
                Text('COMPLETE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: EcoColors.success)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderRow(Map<String, dynamic> leader) {
    final rank = leader['rank'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '${rank < 10 ? '0' : ''}$rank',
            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [EcoColors.primaryContainer.withOpacity(0.5), EcoColors.onPrimaryContainer],
              ),
            ),
            child: const Icon(Icons.person, size: 18, color: EcoColors.surface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(leader['name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: EcoColors.primary)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat('#,##0').format((leader['balance'] ?? 0).toDouble()),
                style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer),
              ),
              Text('ECO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer)),
            ],
          ),
        ],
      ),
    );
  }


}
