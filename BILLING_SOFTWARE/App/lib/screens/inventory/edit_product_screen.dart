import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _barcodeCtrl;
  late String _selectedCategory;
  late String _selectedUnit;
  bool _isLoading = false;

  final List<String> _units = ['pcs', 'kg', 'gm', 'ltr', 'ml', 'pack', 'bottle'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _priceCtrl = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _stockCtrl = TextEditingController(text: widget.product.stock.toString());
    _barcodeCtrl = TextEditingController(text: widget.product.barcode ?? '');
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    final updatedProduct = Product(
      id: widget.product.id,
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? widget.product.price,
      category: _selectedCategory,
      stock: int.tryParse(_stockCtrl.text.trim()) ?? widget.product.stock,
      unit: _selectedUnit,
      barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
      icon: widget.product.icon,
    );

    final success = await productProvider.updateProduct(
      auth.baseUrl,
      auth.apiKey,
      updatedProduct,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, updatedProduct);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage ?? 'Failed to update product'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final categories = context.watch<ProductProvider>().categories.where((c) => c != 'All').toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('update_product').toUpperCase(),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: context.tr('product_name'),
                        prefixIcon: Icon(Icons.shopping_bag_rounded, color: AppColors.terracotta),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter product name' : null,
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              labelText: context.tr('selling_price'),
                              prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.forestMint),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter price' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedUnit,
                            decoration: InputDecoration(
                              labelText: context.tr('unit'),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            items: _units
                                .map((u) => DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedUnit = v!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: categories.contains(_selectedCategory) ? _selectedCategory : (categories.isNotEmpty ? categories.first : 'Groceries'),
                      decoration: InputDecoration(
                        labelText: context.tr('expense_category'),
                        prefixIcon: Icon(Icons.category_rounded, color: AppColors.terracotta),
                      ),
                      items: categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: context.tr('stock_qty'),
                        prefixIcon: Icon(Icons.inventory_rounded, color: AppColors.chaiGold),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter stock quantity' : null,
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _barcodeCtrl,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: context.tr('barcode'),
                        prefixIcon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveChanges,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_isLoading ? 'SAVING...' : context.tr('update_product')),
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
      ),
    );
  }
}
