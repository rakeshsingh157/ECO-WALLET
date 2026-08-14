import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '10');
  String _selectedCategory = 'Beverages';
  String _selectedUnit = 'pcs';
  bool _isSaving = false;

  final List<String> _units = ['pcs', 'kg', 'pack', 'L', 'bottle', 'pouch', 'box', 'gram'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final targetBase = auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl;

    setState(() => _isSaving = true);

    final newProduct = Product(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      category: _selectedCategory,
      unit: _selectedUnit,
      stock: int.tryParse(_stockCtrl.text) ?? 10,
      icon: 'box',
    );

    await context.read<ProductProvider>().createProduct(targetBase, auth.apiKey, newProduct);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newProduct.name} saved to MongoDB Atlas!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories.where((c) => c != 'All').toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.add_box_rounded, color: AppColors.warmCoral, size: 24),
            const SizedBox(width: 10),
            Text(
              'Add New Product',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          color: AppColors.darkCard.withValues(alpha: 0.95),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/boxie.png',
                      width: 44,
                      height: 44,
                      errorBuilder: (c, e, s) => const SizedBox(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fill product details to save directly into MongoDB Atlas catalog',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g. Basmati Rice 1kg',
                    prefixIcon: Icon(Icons.shopping_bag_rounded, color: AppColors.warmCoral),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Product name required' : null,
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.warmCoral),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Price required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                        ),
                        items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded, color: AppColors.warmCoral),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                    prefixIcon: Icon(Icons.inventory_rounded, color: AppColors.warmCoral),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Stock required' : null,
                ),

                const SizedBox(height: 24),

                GradientButton(
                  text: 'Save Product to Database',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isSaving,
                  onPressed: _saveProduct,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
