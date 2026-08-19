import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/localization.dart';
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
          content: Text(context.tr('backend_url_updated_success')),
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
          context.tr('server_configuration').toUpperCase(),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.forestMint.withValues(alpha: 0.15),
                    AppColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.forestMint.withValues(alpha: 0.25), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.forestMint,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forestMint.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.dns_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('backend_endpoint_host'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr('backend_endpoint_desc'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.warmNavy.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.speed_rounded, size: 15, color: AppColors.warmNavy),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('quick_presets').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _baseUrlCtrl.text = 'http://10.0.2.2:5001/api'),
                          icon: const Icon(Icons.phone_android_rounded, size: 16),
                          label: Text(context.tr('android_emulator'), overflow: TextOverflow.ellipsis),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            side: BorderSide(
                              color: _baseUrlCtrl.text.contains('10.0.2.2') ? AppColors.forestMint : AppColors.borderSubtle,
                              width: _baseUrlCtrl.text.contains('10.0.2.2') ? 1.8 : 1.0,
                            ),
                            backgroundColor: _baseUrlCtrl.text.contains('10.0.2.2') ? AppColors.forestMint.withValues(alpha: 0.12) : Colors.transparent,
                            foregroundColor: _baseUrlCtrl.text.contains('10.0.2.2') ? AppColors.forestMint : AppColors.textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _baseUrlCtrl.text = 'http://localhost:5001/api'),
                          icon: const Icon(Icons.laptop_rounded, size: 16),
                          label: Text(context.tr('desktop_local'), overflow: TextOverflow.ellipsis),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            side: BorderSide(
                              color: _baseUrlCtrl.text.contains('localhost') ? AppColors.info : AppColors.borderSubtle,
                              width: _baseUrlCtrl.text.contains('localhost') ? 1.8 : 1.0,
                            ),
                            backgroundColor: _baseUrlCtrl.text.contains('localhost') ? AppColors.info.withValues(alpha: 0.12) : Colors.transparent,
                            foregroundColor: _baseUrlCtrl.text.contains('localhost') ? AppColors.info : AppColors.textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${context.tr('backend_api_base_url')} *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _baseUrlCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'http://10.0.2.2:5001/api',
                      prefixIcon: Icon(Icons.link_rounded, color: AppColors.forestMint, size: 20),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      context.tr('eco_merchant_api_key'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _apiKeyCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'key_mch_...',
                      prefixIcon: Icon(Icons.key_rounded, color: AppColors.terracotta, size: 20),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestMint))
                        : Icon(Icons.wifi_find_rounded, color: AppColors.forestMint, size: 18),
                    label: Text(
                      _isTesting ? context.tr('testing_connectivity') : context.tr('test_host_connectivity').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppColors.forestMint.withValues(alpha: 0.15),
                      foregroundColor: AppColors.forestMint,
                      elevation: 0,
                      side: BorderSide(color: AppColors.forestMint.withValues(alpha: 0.4), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  if (_testResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (_isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _isSuccess ? AppColors.success : AppColors.error, width: 1.2),
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.terracotta.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _saveConfig,
                icon: const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  context.tr('save_server_configuration').toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
