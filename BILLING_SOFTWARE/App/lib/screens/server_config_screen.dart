import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  bool _isTesting = false;
  String? _testResult;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _baseUrlCtrl = TextEditingController(
      text: auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl,
    );
    _apiKeyCtrl = TextEditingController(text: auth.apiKey.isNotEmpty ? auth.apiKey : 'merchant_live_demo_123');
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final base = _baseUrlCtrl.text.trim();
    final cleanBase = base.endsWith('/api') ? base : '$base/api';
    final healthUri = Uri.parse('$cleanBase/health');

    try {
      final response = await http.get(healthUri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isSuccess = true;
          _testResult = 'Online! Server: ${data['app'] ?? 'Dukaan Dost'}\nDatabase: ${data['database'] ?? 'MongoDB Atlas'}';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _testResult = 'Server returned HTTP status ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _testResult = 'Connection Failed: ${e.toString().replaceAll('Instance of ', '')}';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  void _saveConfig() async {
    final auth = context.read<AuthProvider>();
    final newUrl = _baseUrlCtrl.text.trim();
    final newApiKey = _apiKeyCtrl.text.trim();

    await auth.saveCredentials(
      apiKey: newApiKey.isNotEmpty ? newApiKey : 'merchant_live_demo_123',
      webhookSecret: auth.webhookSecret.isNotEmpty ? auth.webhookSecret : 'whsec_demo',
      merchantId: auth.merchantId.isNotEmpty ? auth.merchantId : 'mch_9876543210',
      shopName: auth.shopName,
      ownerName: auth.ownerName,
      mobileNumber: auth.mobileNumber,
      securityPin: auth.securityPin,
      baseUrl: newUrl,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Backend API URL updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'SERVER CONFIGURATION',
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.dns_rounded, color: AppColors.forestMint, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backend Endpoint Host',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Connect terminal to local or remote microservice.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'QUICK PRESETS',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _baseUrlCtrl.text = 'http://10.0.2.2:5001/api'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Android Emulator', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forestMint)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _baseUrlCtrl.text = 'http://localhost:5001/api'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Desktop Local', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warmNavy)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _baseUrlCtrl,
              style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Backend API Base URL',
                hintText: 'http://10.0.2.2:5001/api',
                prefixIcon: Icon(Icons.link_rounded, color: AppColors.forestMint),
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _apiKeyCtrl,
              style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'ECO Merchant API Key',
                hintText: 'key_mch_...',
                prefixIcon: Icon(Icons.key_rounded, color: AppColors.terracotta),
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestMint))
                  : Icon(Icons.wifi_find_rounded, color: AppColors.forestMint, size: 18),
              label: Text(
                _isTesting ? 'Testing Connectivity...' : 'TEST HOST CONNECTIVITY',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.forestMint),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: AppColors.forestMint),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isSuccess ? AppColors.success : AppColors.error),
                ),
                child: Row(
                  children: [
                    Icon(_isSuccess ? Icons.check_circle_rounded : Icons.error_rounded, color: _isSuccess ? AppColors.success : AppColors.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _isSuccess ? AppColors.success : AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveConfig,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('SAVE SERVER CONFIGURATION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
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
}
