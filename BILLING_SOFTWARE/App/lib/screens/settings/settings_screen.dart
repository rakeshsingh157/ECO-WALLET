import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../add_member_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../expenses/expenses_screen.dart';
import 'shop_profile_screen.dart';
import 'language_selection_screen.dart';
import 'backup_restore_screen.dart';
import 'help_support_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('settings_title'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopProfileScreen())),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Image.asset(MascotAssets.shopkeeper, width: 48, height: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.shopName.isNotEmpty ? auth.shopName : 'My Retail Store',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            auth.isStaff
                                ? 'Logged in as ${auth.staffName} (${auth.staffRole})'
                                : '${context.tr('proprietor')}: ${auth.ownerName.isNotEmpty ? auth.ownerName : 'Store Admin'}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: auth.isStaff ? AppColors.forestMint : AppColors.textSecondary,
                              fontWeight: auth.isStaff ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              context.tr('business_operations'),
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildNavRow(
                    context,
                    icon: Icons.store_rounded,
                    title: context.tr('shop_profile'),
                    subtitle: context.tr('shop_profile_sub'),
                    color: AppColors.terracotta,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopProfileScreen())),
                  ),
                  Divider(color: AppColors.borderSubtle, height: 20),
                  _buildNavRow(
                    context,
                    icon: Icons.qr_code_2_rounded,
                    title: 'Store UPI & QR Code',
                    subtitle: auth.upiId.isNotEmpty ? auth.upiId : 'Scan standee or set UPI ID for bill QR',
                    color: AppColors.info,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopProfileScreen())),
                  ),
                  Divider(color: AppColors.borderSubtle, height: 20),
                  _buildNavRow(
                    context,
                    icon: Icons.groups_rounded,
                    title: context.tr('staff_pins'),
                    subtitle: context.tr('staff_pins_sub'),
                    color: AppColors.warmNavy,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMemberScreen())),
                  ),
                  Divider(color: AppColors.borderSubtle, height: 20),
                  _buildNavRow(
                    context,
                    icon: Icons.local_shipping_rounded,
                    title: context.tr('suppliers'),
                    subtitle: context.tr('suppliers_sub'),
                    color: AppColors.chaiGold,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen())),
                  ),
                  Divider(color: AppColors.borderSubtle, height: 20),
                  _buildNavRow(
                    context,
                    icon: Icons.receipt_long_rounded,
                    title: context.tr('store_expenses'),
                    subtitle: context.tr('expenses_sub'),
                    color: AppColors.error,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              context.tr('preferences_system'),
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warmNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: AppColors.warmNavy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('dark_mode'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                themeProvider.isDarkMode ? context.tr('dark_mode_on') : context.tr('dark_mode_off'),
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (val) => themeProvider.toggleTheme(val),
                          activeThumbColor: AppColors.terracotta,
                        ),
                      ],
                    ),
                  ),
                  Divider(color: AppColors.borderSubtle, height: 20),
                  _buildNavRow(
                    context,
                    icon: Icons.language_rounded,
                    title: context.tr('app_language'),
                    subtitle: context.tr('app_language_sub'),
                    color: AppColors.forestMint,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen())),
                  ),
                  Divider(color: AppColors.borderSubtle, height: 20),
                  _buildNavRow(
                    context,
                    icon: Icons.cloud_sync_rounded,
                    title: context.tr('backup_restore'),
                    subtitle: context.tr('backup_restore_sub'),
                    color: AppColors.info,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen())),
                  ),
                  Divider(color: AppColors.borderSubtle, height: 20),
                  _buildNavRow(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: context.tr('help_support'),
                    subtitle: context.tr('help_support_sub'),
                    color: AppColors.warmNavy,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(context.tr('logout')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
