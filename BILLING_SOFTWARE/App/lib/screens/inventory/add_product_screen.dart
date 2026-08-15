import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  String _selectedCategory = 'Groceries';
  String _selectedUnit = 'pcs';
  bool _isLoading = false;

  final List<String> _units = ['pcs', 'kg', 'gm', 'ltr', 'ml', 'pack', 'bottle'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  void _scanBarcode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: 480,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SCAN PRODUCT BARCODE / QR',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final rawValue = barcode.rawValue;
                      if (rawValue != null && rawValue.isNotEmpty) {
                        setState(() {
                          _barcodeCtrl.text = rawValue.trim();
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Scanned Code: ${rawValue.trim()}'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Point camera at product barcode (EAN, UPC) or QR code',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    final newProduct = Product(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
      category: _selectedCategory,
      unit: _selectedUnit,
      stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
    );

    final success = await productProvider.createProduct(
      auth.baseUrl,
      auth.apiKey,
      newProduct,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameCtrl.text.trim()} added to inventory!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, newProduct);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage ?? 'Failed to create product'),
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
          context.tr('add_product').toUpperCase(),
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
                        hintText: 'e.g. Basmati Rice 1kg',
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
                              hintText: '0.00',
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
                        hintText: 'e.g. 50',
                        prefixIcon: Icon(Icons.inventory_rounded, color: AppColors.chaiGold),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter stock quantity' : null,
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _barcodeCtrl,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: context.tr('barcode'),
                        hintText: 'Scan or type EAN / UPC / QR',
                        prefixIcon: Icon(Icons.qr_code_2_rounded, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.terracotta),
                          tooltip: 'Scan Barcode with Camera',
                          onPressed: _scanBarcode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProduct,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_circle_rounded, size: 18),
                  label: Text(_isLoading ? 'CREATING PRODUCT...' : context.tr('save_product')),
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
