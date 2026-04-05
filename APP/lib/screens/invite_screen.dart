/// ECO Wallet — Invite Friends Screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../core/api_service.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _referrals = [];

  @override
  void initState() {
    super.initState();
    _fetchReferrals();
  }

  Future<void> _fetchReferrals() async {
    try {
      final res = await ApiService.get('/rewards/referrals');
      if (res['success'] == true && mounted) {
        setState(() {
          _referrals = List<Map<String, dynamic>>.from(res['data']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final code = auth.user?['user_id'] ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: EcoColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            EcoColors.primaryContainer.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: EcoColors.primaryContainer.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.group_add, color: EcoColors.primaryContainer, size: 32),
                          ).animate().fadeIn().slideY(begin: 0.2),
                          const SizedBox(height: 16),
                          Text(
                            'Invite Friends,\nEarn 500 ECO',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: EcoColors.primary,
                              height: 1.1,
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                          const SizedBox(height: 12),
                          Text(
                            'Share your referral code. When a friend signs up and makes their first transaction, you both earn rewards.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: EcoColors.onSurfaceVariant,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Referral Code Box
                Text('YOUR REFERRAL CODE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: EcoColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: EcoColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          code,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: EcoColors.primaryContainer,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Referral Code Copied to Clipboard')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: EcoColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.copy, color: EcoColors.surface, size: 20),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 32),

                // Rules
                Text('HOW IT WORKS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: EcoColors.onSurfaceVariant)),
                const SizedBox(height: 16),
                _buildRuleStep(
                  '1', 
                  'Share Your Code', 
                  'Give your unique referral code to a friend who hasn\'t joined ECO Wallet yet.'
                ),
                _buildRuleStep(
                  '2', 
                  'They Sign Up', 
                  'Your friend enters your code during registration to link their account to yours.'
                ),
                _buildRuleStep(
                  '3', 
                  'First Transaction', 
                  'Once your friend successfully completes their first peer-to-peer transfer, you get 500 ECO instantly!'
                ),

                const SizedBox(height: 40),

                // Invited Friends List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invited Friends',
                      style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: EcoColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                         color: EcoColors.surfaceContainerHighest,
                         borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_referrals.length}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: EcoColors.primaryContainer),
                    ),
                  )
                else if (_referrals.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 64, color: EcoColors.onSurfaceVariant.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No friends invited yet',
                            style: GoogleFonts.inter(fontSize: 16, color: EcoColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._referrals.map((friend) => _buildFriendCard(friend)),
                  
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EcoColors.surfaceContainerHighest,
            ),
            alignment: Alignment.center,
            child: Text(number, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: EcoColors.primary)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: EcoColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final bool hasCompleted = friend['hasCompletedTransaction'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCompleted ? EcoColors.success.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasCompleted ? EcoColors.success.withOpacity(0.1) : EcoColors.surfaceContainerHighest,
            ),
            child: Icon(
              Icons.person,
              color: hasCompleted ? EcoColors.success : EcoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'] ?? 'Unknown',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: EcoColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCompleted ? 'Verified User' : 'Pending First Transaction',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: hasCompleted ? EcoColors.success : EcoColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (hasCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: EcoColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+500',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: EcoColors.success),
              ),
            )
          else
            Icon(Icons.hourglass_empty, size: 18, color: EcoColors.onSurfaceVariant.withOpacity(0.5)),
        ],
      ),
    );
  }
}
