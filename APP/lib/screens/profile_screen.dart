/// ECO Wallet — Profile Screen
/// Matches the profile UI mockup: avatar, user info, settings, logout.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../core/api_service.dart';
import 'auth_screen.dart';
import 'notifications_screen.dart';
import 'privacy_policy_screen.dart';
import 'support_screen.dart';
import '../providers/notification_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _requirePin = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchProfile();
    });
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _requirePin = prefs.getBool('require_pin') ?? false;
    });
    
    // Check if backend thinks we have a pin
    final auth = context.read<AuthProvider>();
    if (auth.user?['has_pin'] == true && !_requirePin) {
      setState(() => _requirePin = true);
      await prefs.setBool('require_pin', true);
    }
    
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _handlePinToggle(bool value) async {
    if (value) {
      final pin = await _showPinBottomSheet('Create New PIN');
      if (pin != null) {
        final res = await ApiService.setPin(pin);
        if (res['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('require_pin', true);
          setState(() => _requirePin = true);
          if (mounted) {
            await context.read<AuthProvider>().fetchProfile();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN set successfully')));
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to set PIN')));
        }
      } else {
        // user cancelled toggle
        setState(() => _requirePin = false);
      }
    } else {
      final pinInfo = await _showPinBottomSheet('Enter Current PIN');
      if (pinInfo == null) {
        setState(() => _requirePin = true); 
        return;
      }
      final res = await ApiService.removePin(pinInfo);
      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('require_pin', false);
        setState(() => _requirePin = false);
        if (mounted) {
          await context.read<AuthProvider>().fetchProfile();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN removed')));
        }
      } else {
        setState(() => _requirePin = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Incorrect PIN'), backgroundColor: EcoColors.error));
        }
      }
    }
  }

  Future<String?> _showPinBottomSheet(String title) async {
    String enteredPin = '';
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: EcoColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 24, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: EcoColors.primary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) { // 6 digits
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < enteredPin.length ? EcoColors.primaryContainer : EcoColors.surfaceContainerHighest,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  _buildMiniNumpad((key) {
                    if (key == '⌫') {
                      if (enteredPin.isNotEmpty) setModalState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                    } else if (enteredPin.length < 6) {
                      setModalState(() => enteredPin += key);
                      if (enteredPin.length == 6) {
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (ctx.mounted) Navigator.pop(ctx, enteredPin);
                        });
                      }
                    }
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildMiniNumpad(Function(String) onKey) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 64, height: 64);
              return GestureDetector(
                onTap: () => onKey(k),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: k == '⌫' 
                      ? const Icon(Icons.backspace_outlined, color: EcoColors.onSurfaceVariant) 
                      : Text(k, style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: EcoColors.onSurface)),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  void _showEditProfileDialog() {
    final auth = context.read<AuthProvider>();
    final TextEditingController nameController = TextEditingController(text: auth.userName);
    final TextEditingController phoneController = TextEditingController(text: auth.user?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: EcoColors.surfaceContainerLow,
          title: Text('Edit Profile', style: GoogleFonts.spaceGrotesk(color: EcoColors.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: EcoColors.primary),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.inter(color: EcoColors.onSurfaceVariant),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: EcoColors.primaryContainer)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(color: EcoColors.primary),
                decoration: InputDecoration(
                  labelText: 'Phone',
                  labelStyle: GoogleFonts.inter(color: EcoColors.onSurfaceVariant),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: EcoColors.primaryContainer)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: EcoColors.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                Navigator.pop(context);
                
                final res = await ApiService.updateProfile(name, phone);
                if (res['success'] == true && mounted) {
                  await auth.fetchProfile();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: EcoColors.primaryContainer, foregroundColor: EcoColors.surface),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EcoColors.surfaceContainerHighest,
                    border: Border.all(color: EcoColors.primaryContainer.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.person, size: 20, color: EcoColors.onSurfaceVariant),
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
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
            sliver: Consumer<AuthProvider>(
              builder: (_, auth, __) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: EcoColors.surfaceContainerHigh,
                              border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.15), width: 2),
                            ),
                            child: Icon(Icons.person, size: 60, color: EcoColors.onSurfaceVariant.withOpacity(0.5)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showEditProfileDialog,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: EcoColors.primaryContainer,
                                  border: Border.all(color: EcoColors.surface, width: 3),
                                ),
                                child: const Icon(Icons.edit, size: 14, color: EcoColors.surface),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 20),

                    // Name
                    Center(
                      child: Text(
                        auth.userName,
                        style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: EcoColors.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: auth.userId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID copied to clipboard')));
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ID: ${auth.userId}',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 3, color: EcoColors.onSurfaceVariant),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy, size: 14, color: EcoColors.primaryContainer),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Stats Grid
                    if (auth.user?['stats'] != null) ...[
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Total Earned', '${auth.user!['stats']['total_earned']} ECO', Icons.emoji_events)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('Wallet Balance', '${auth.balance} ECO', Icons.account_balance_wallet)),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Total Sent', '${auth.user!['stats']['total_sent']} ECO', Icons.arrow_outward)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('Total Received', '${auth.user!['stats']['total_received']} ECO', Icons.call_received)),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 32),
                    ],

                    // Settings items
                    _buildSettingTile(
                      icon: Icons.verified_user,
                      title: 'Require PIN for Transactions',
                      subtitle: 'Extra security before sending money',
                      trailing: Switch(
                        value: _requirePin,
                        onChanged: _handlePinToggle,
                        activeColor: EcoColors.primaryContainer,
                      ),
                      onTap: () async {
                        if (_requirePin) {
                           final currentPin = await _showPinBottomSheet('Enter Current PIN');
                           if (currentPin != null) {
                             final newPin = await _showPinBottomSheet('Enter New PIN');
                             if (newPin != null) {
                               final res = await ApiService.setPin(newPin, currentPin: currentPin);
                               if (res['success'] == true && mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed successfully')));
                               } else if (mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to change PIN'), backgroundColor: EcoColors.error));
                               }
                             }
                           }
                        } else {
                           _handlePinToggle(true);
                        }
                      },
                    ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideX(begin: 0.05),

                    const SizedBox(height: 12),

                    _buildSettingTile(
                      icon: Icons.notifications_active,
                      title: 'Notifications',
                      subtitle: 'Alerts & Weekly Insights',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      },
                    ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideX(begin: 0.05),

                    const SizedBox(height: 24),

                    // Small cards row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallCard(Icons.privacy_tip, 'Privacy Policy', () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSmallCard(Icons.help, 'Support', () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                          }),
                        ),
                      ],
                    ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: 40),

                    // Logout
                    GestureDetector(
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, color: EcoColors.onSurfaceVariant, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'LOGOUT',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: EcoColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 400.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: 32),
                    
                    if (_appVersion.isNotEmpty)
                      Center(
                        child: Text(
                          'Version v$_appVersion',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: EcoColors.onSurfaceVariant.withOpacity(0.5)),
                        ),
                      ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              child: Icon(icon, color: EcoColors.primaryContainer, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: EcoColors.primary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: EcoColors.onSurfaceVariant)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: EcoColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: EcoColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EcoColors.surfaceContainerHighest,
              ),
              child: Icon(icon, color: EcoColors.primaryContainer, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: EcoColors.primary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EcoColors.primaryContainer, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: EcoColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: EcoColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
