import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'add_member_screen.dart';
import 'khata_screen.dart';
import 'eco_payment_screen.dart';
import 'server_config_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/delivery.png',
              width: 32,
              height: 32,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
            const SizedBox(width: 10),
            Text(
              'Settings & Profile',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Card with Shopkeeper Mascot Avatar
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 22,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.warmPeach, width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/shopkeeper.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.store_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.shopName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Owner: ${auth.ownerName}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Shop Management Section
            Text(
              'Shop Management',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              color: AppColors.darkCard,
              child: Column(
                children: [
                  _buildNavTile(
                    context,
                    icon: Icons.person_add_rounded,
                    title: 'Shop Members & Staff',
                    subtitle: 'Manage staff access and roles',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMemberScreen())),
                  ),
                  const Divider(color: AppColors.glassBorder, height: 20),
                  _buildNavTile(
                    context,
                    icon: Icons.menu_book_rounded,
                    title: 'Khata Book & Dues',
                    subtitle: 'Track customer credit & pending payments',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KhataScreen())),
                  ),
                  const Divider(color: AppColors.glassBorder, height: 20),
                  _buildNavTile(
                    context,
                    icon: Icons.stars_rounded,
                    title: 'ECO Payment Hub',
                    subtitle: 'Merchant QR code & transaction logs',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EcoPaymentScreen())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ECO Wallet Integration Status
            Text(
              'ECO Wallet Merchant Connection',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              color: AppColors.darkCard,
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.link_rounded,
                    title: 'Connection Status',
                    subtitle: auth.isConfigured ? 'Active & Configured' : 'Not Configured',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (auth.isConfigured ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        auth.isConfigured ? 'Connected' : 'Offline',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: auth.isConfigured ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.glassBorder, height: 24),
                  _buildSettingRow(
                    icon: Icons.key_rounded,
                    title: 'API Key',
                    subtitle: auth.apiKey.isNotEmpty
                        ? '${auth.apiKey.substring(0, auth.apiKey.length > 10 ? 10 : auth.apiKey.length)}...'
                        : 'None',
                  ),
                  const Divider(color: AppColors.glassBorder, height: 24),
                  _buildSettingRow(
                    icon: Icons.dns_rounded,
                    title: 'Backend Endpoint',
                    subtitle: auth.baseUrl,
                    trailing: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ServerConfigScreen()),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.warmCoral),
                      label: Text(
                        'Change',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warmCoral),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reconfigure Credentials Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.edit_rounded, color: AppColors.warmCoral),
              label: Text(
                'Reconfigure Credentials',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppColors.warmCoral,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.warmCoral, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 12),

            // Log Out Button
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.darkCard,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text(
                      'Confirm Logout',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    content: Text(
                      'Are you sure you want to log out of Dukaan Dost?',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: Text(
                'Log Out',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warmCoral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.warmCoral, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.warmCoral, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
