/// ECO Wallet — Main Navigation Shell
/// Bottom nav bar with 4 tabs: Home, History, Rewards, Profile
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/update_service.dart';
import '../providers/wallet_provider.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'rewards_screen.dart';
import 'profile_screen.dart';

final GlobalKey<MainShellState> mainShellKey = GlobalKey<MainShellState>();

class MainShell extends StatefulWidget {
  MainShell({Key? key}) : super(key: key ?? mainShellKey);

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().startPolling();
      UpdateService.checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    // Cannot easily call stopPolling without context, usually MainShell is always active
    super.dispose();
  }

  void switchTab(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  final _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const RewardsScreen(),
    const ProfileScreen(),
  ];

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EcoColors.surfaceContainerLow,
        title: Text('Exit App', style: GoogleFonts.spaceGrotesk(color: EcoColors.primary)),
        content: Text('Do you really want to exit ECO Wallet?', style: GoogleFonts.inter(color: EcoColors.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('NO', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: EcoColors.primaryContainer)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: EcoColors.error),
            child: Text('YES, EXIT', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          final exit = await _showExitDialog(context);
          if (exit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: EcoColors.surface.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: EcoColors.surfaceTint.withOpacity(0.06),
                blurRadius: 40,
                offset: const Offset(0, -20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: [
                _buildNavItem(Icons.home_rounded, 'HOME', 0),
                _buildNavItem(Icons.history, 'HISTORY', 1),
                _buildNavItem(Icons.workspace_premium, 'REWARDS', 2),
                _buildNavItem(Icons.person, 'PROFILE', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: isActive
          ? Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [EcoColors.primaryContainer, EcoColors.onPrimaryContainer],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, color: EcoColors.surface, size: 22),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 22),
            ),
      label: label,
    );
  }
}
