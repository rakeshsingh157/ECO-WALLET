import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';

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
    _apiKeyCtrl = TextEditingController(text: auth.apiKey);
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

    final targetUrl = _baseUrlCtrl.text.trim();
    final healthUri = Uri.parse(targetUrl.endsWith('/api') ? '$targetUrl/health' : '$targetUrl/api/health');

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
        const SnackBar(
          content: Text('Backend API URL updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Backend Server Config',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 22,
              color: AppColors.darkCard.withValues(alpha: 0.95),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warmCoral.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.dns_rounded, color: AppColors.warmCoral, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API Endpoint Settings',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Change base URL to connect to your custom local or cloud server.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Preset Buttons
            Text(
              'Quick Presets',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _baseUrlCtrl.text = 'http://10.0.2.2:5001/api'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.warmCoral),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Android Emulator', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warmCoral)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _baseUrlCtrl.text = 'http://localhost:5001/api'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.warmPeach),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Desktop Local', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warmPeach)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Input Fields Form
            TextFormField(
              controller: _baseUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Backend API Base URL',
                hintText: 'http://10.0.2.2:5001/api',
                prefixIcon: Icon(Icons.link_rounded, color: AppColors.warmCoral),
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _apiKeyCtrl,
              decoration: const InputDecoration(
                labelText: 'ECO Merchant API Key',
                hintText: 'mch_live_key_xyz',
                prefixIcon: Icon(Icons.key_rounded, color: AppColors.warmCoral),
              ),
            ),

            const SizedBox(height: 20),

            // Test Connection Button & Result
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warmPeach))
                  : const Icon(Icons.wifi_find_rounded, color: AppColors.warmPeach),
              label: Text(
                _isTesting ? 'Testing Endpoint...' : 'Test Server Connection',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.warmPeach),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.warmPeach),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
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
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _isSuccess ? AppColors.success : AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Save Configuration Button
            GradientButton(
              text: 'Save Endpoint Config',
              icon: Icons.save_rounded,
              onPressed: _saveConfig,
            ),
          ],
        ),
      ),
    );
  }
}
