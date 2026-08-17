import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isProcessing = false;
  String _lastSyncedText = 'Today at 04:30 AM';

  void _triggerCloudSync() async {
    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final res = await auth.apiService.cloudSync();
    setState(() => _isProcessing = false);

    if (res['success'] == true) {
      setState(() {
        _lastSyncedText = 'Just now (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})';
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Cloud backup verified and synced!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Cloud sync failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _exportJsonBackup() async {
    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final res = await auth.apiService.exportBackup();
    setState(() => _isProcessing = false);

    if (res['success'] == true && res['backup'] != null) {
      final jsonStr = jsonEncode(res['backup']);
      Share.share(jsonStr, subject: 'Dukaan_Dost_Backup_${DateTime.now().millisecondsSinceEpoch}.json');
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to export backup'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _restoreFromLocal() async {
    final restoreCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('restore_store_data'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('restore_store_data_sub'),
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: restoreCtrl,
              maxLines: 4,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '{"export_version": "1.0", "data": {...}}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel'), style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = restoreCtrl.text.trim();
              if (raw.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final auth = context.read<AuthProvider>();
                final failMsg = context.tr('action_failed');
                try {
                  final parsed = jsonDecode(raw);
                  Navigator.pop(ctx);
                  setState(() => _isProcessing = true);
                  final res = await auth.apiService.restoreBackup(parsed);
                  if (!mounted) return;
                  setState(() => _isProcessing = false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? failMsg),
                      backgroundColor: res['success'] == true ? AppColors.success : AppColors.error,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  setState(() => _isProcessing = false);
                  messenger.showSnackBar(
                    SnackBar(content: Text(failMsg), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta, foregroundColor: Colors.white),
            child: Text(context.tr('restore_data_btn')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('backup_restore').toUpperCase(),
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
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Image.asset(MascotAssets.calculator, width: 56, height: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('auto_cloud_backup_active'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.forestMint),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${context.tr('last_synced')}: $_lastSyncedText',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.cloud_upload_rounded, color: AppColors.terracotta),
                    title: Text(context.tr('sync_backup_cloud'), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    subtitle: Text(context.tr('sync_backup_cloud_sub'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _isProcessing ? null : _triggerCloudSync,
                  ),
                  Divider(color: AppColors.borderSubtle),
                  ListTile(
                    leading: Icon(Icons.table_chart_rounded, color: AppColors.forestMint),
                    title: Text(context.tr('export_backup'), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    subtitle: Text(context.tr('export_backup_sub'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _isProcessing ? null : _exportJsonBackup,
                  ),
                  Divider(color: AppColors.borderSubtle),
                  ListTile(
                    leading: Icon(Icons.settings_backup_restore_rounded, color: AppColors.warmNavy),
                    title: Text(context.tr('restore_backup'), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    subtitle: Text(context.tr('restore_backup_sub'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _isProcessing ? null : _restoreFromLocal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
