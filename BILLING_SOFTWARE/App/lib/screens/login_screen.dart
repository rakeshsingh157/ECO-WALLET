import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import 'main_shell.dart';
import 'server_config_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginMobileCtrl = TextEditingController();
  final _loginPinCtrl = TextEditingController();

  // Signup form controllers
  final _signupFormKey = GlobalKey<FormState>();
  final _signupShopNameCtrl = TextEditingController();
  final _signupOwnerNameCtrl = TextEditingController();
  final _signupMobileCtrl = TextEditingController();
  final _signupPinCtrl = TextEditingController();
  final _signupConfirmPinCtrl = TextEditingController();

  bool _obscureLoginPin = true;
  bool _obscureSignupPin = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final auth = context.read<AuthProvider>();
    if (auth.mobileNumber.isNotEmpty) {
      _loginMobileCtrl.text = auth.mobileNumber;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginMobileCtrl.dispose();
    _loginPinCtrl.dispose();
    _signupShopNameCtrl.dispose();
    _signupOwnerNameCtrl.dispose();
    _signupMobileCtrl.dispose();
    _signupPinCtrl.dispose();
    _signupConfirmPinCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final phone = _loginMobileCtrl.text.trim();
    final pin = _loginPinCtrl.text.trim();
    final targetBase = auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl;

    setState(() => _isLoading = true);

    final apiService = ApiService(baseUrl: targetBase, apiKey: '');
    final result = await apiService.loginMerchant(mobileNumber: phone, securityPin: pin);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true && result['merchant'] != null) {
      final m = result['merchant'];
      await auth.saveCredentials(
        apiKey: m['api_key'] ?? 'key_mch_${phone}_auto',
        webhookSecret: m['webhook_secret'] ?? 'whsec_auto_$phone',
        merchantId: m['merchant_id'] ?? 'mch_$phone',
        shopName: m['business_name'] ?? 'My Shop',
        ownerName: m['owner_name'] ?? 'Shopkeeper',
        mobileNumber: phone,
        securityPin: pin,
        baseUrl: targetBase,
      );

      // Pre-load catalog products from MongoDB
      if (mounted) {
        context.read<ProductProvider>().fetchProducts(targetBase, m['api_key'] ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login successful!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed. Please check credentials.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    if (_signupPinCtrl.text.trim() != _signupConfirmPinCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security PINs do not match!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final phone = _signupMobileCtrl.text.trim();
    final shopName = _signupShopNameCtrl.text.trim();
    final ownerName = _signupOwnerNameCtrl.text.trim();
    final pin = _signupPinCtrl.text.trim();
    final targetBase = auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl;

    setState(() => _isLoading = true);

    final apiService = ApiService(baseUrl: targetBase, apiKey: '');
    final result = await apiService.signupMerchant(
      mobileNumber: phone,
      shopName: shopName,
      ownerName: ownerName,
      securityPin: pin,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true && result['merchant'] != null) {
      final m = result['merchant'];
      await auth.saveCredentials(
        apiKey: m['api_key'] ?? 'key_mch_${phone}_auto',
        webhookSecret: m['webhook_secret'] ?? 'whsec_auto_$phone',
        merchantId: m['merchant_id'] ?? 'mch_$phone',
        shopName: shopName,
        ownerName: ownerName,
        mobileNumber: phone,
        securityPin: pin,
        baseUrl: targetBase,
      );

      if (mounted) {
        context.read<ProductProvider>().fetchProducts(targetBase, m['api_key'] ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Store registered successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Sign Up failed. Please try again.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Container(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF8C75),
                Color(0xFFE8446D),
                AppColors.darkNavy,
              ],
              stops: [0.0, 0.25, 0.65],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // App Branding Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.darkNavy,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.warmPeach, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.storefront_rounded, color: AppColors.warmCoral, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DUKAAN DOST',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Smart Retail & POS Terminal',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ServerConfigScreen()),
                          );
                        },
                        icon: const Icon(Icons.tune_rounded, color: Colors.white),
                        tooltip: 'Server Settings',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tab Selector: Login vs Sign Up
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.darkCard.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        gradient: AppColors.sunsetGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Register Store'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Form Container
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    borderRadius: 24,
                    color: AppColors.darkCard.withValues(alpha: 0.95),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        return _tabController.index == 0
                            ? _buildLoginForm()
                            : _buildSignupForm();
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Server Connection Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Server: ${auth.baseUrl.isNotEmpty ? auth.baseUrl : "Default (Port 5001)"}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LOGIN FORM ====================
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.login_rounded, color: AppColors.warmPeach, size: 22),
              const SizedBox(width: 8),
              Text(
                'Welcome Back',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.warmPeach),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your registered mobile number and 4-digit PIN.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          // Mobile Number
          TextFormField(
            controller: _loginMobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number *',
              hintText: '10-digit number',
              prefixIcon: Icon(Icons.phone_android_rounded, color: AppColors.warmCoral),
              prefixText: '+91 ',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Mobile number required';
              if (v.trim().length < 10) return 'Enter a valid 10-digit number';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Security PIN
          TextFormField(
            controller: _loginPinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: _obscureLoginPin,
            decoration: InputDecoration(
              labelText: '4-Digit Security PIN *',
              prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.warmCoral),
              counterText: '',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPin ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscureLoginPin = !_obscureLoginPin),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'PIN is required';
              if (v.trim().length != 4) return 'PIN must be 4 digits';
              return null;
            },
          ),

          const SizedBox(height: 24),

          GradientButton(
            text: 'Sign In to Store',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),

          const SizedBox(height: 14),

          Center(
            child: TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text(
                'New merchant? Register your store here',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmCoral, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIGNUP FORM ====================
  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppColors.warmPeach, size: 22),
              const SizedBox(width: 8),
              Text(
                'Register New Store',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.warmPeach),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Create your Dukaan account to start billing and accept ECO Wallet.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),

          // Shop Name
          TextFormField(
            controller: _signupShopNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Store / Shop Name *',
              hintText: 'e.g. Sharma Kirana Store',
              prefixIcon: Icon(Icons.storefront_rounded, color: AppColors.warmCoral),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Shop name is required' : null,
          ),

          const SizedBox(height: 12),

          // Owner Name
          TextFormField(
            controller: _signupOwnerNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Owner / Merchant Name *',
              hintText: 'e.g. Ramesh Sharma',
              prefixIcon: Icon(Icons.person_rounded, color: AppColors.warmCoral),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Owner name is required' : null,
          ),

          const SizedBox(height: 12),

          // Mobile Number
          TextFormField(
            controller: _signupMobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number *',
              hintText: '10-digit number',
              prefixIcon: Icon(Icons.phone_android_rounded, color: AppColors.warmCoral),
              prefixText: '+91 ',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Mobile number required';
              if (v.trim().length < 10) return 'Enter a valid 10-digit number';
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Set 4-Digit PIN
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _signupPinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: _obscureSignupPin,
                  decoration: const InputDecoration(
                    labelText: 'Set 4-Digit PIN *',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_rounded, color: AppColors.warmCoral),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 4) return '4 digits required';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _signupConfirmPinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: _obscureSignupPin,
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN *',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.warmCoral),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 4) return '4 digits required';
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          GradientButton(
            text: 'Create Store Account',
            icon: Icons.check_circle_rounded,
            isLoading: _isLoading,
            onPressed: _handleSignup,
          ),

          const SizedBox(height: 14),

          Center(
            child: TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: Text(
                'Already registered? Sign In here',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmCoral, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
