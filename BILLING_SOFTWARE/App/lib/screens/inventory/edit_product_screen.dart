import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/camera_scanner_modal.dart';

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
  late TextEditingController _lowStockCtrl;
  late TextEditingController _barcodeCtrl;

  late String _selectedCategory;
  late String _selectedUnit;
  bool _isLoading = false;
  bool _isDeleting = false;

  final List<String> _units = ['pcs', 'kg', 'g', 'ltr', 'ml', 'pack', 'box', 'dozen'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _priceCtrl = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _stockCtrl = TextEditingController(text: widget.product.stock.toString());
    _lowStockCtrl = TextEditingController(text: widget.product.lowStockAlert.toString());
    _barcodeCtrl = TextEditingController(text: widget.product.barcode ?? '');
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _lowStockCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  void _scanBarcode() async {
    final scannedCode = await CameraScannerModal.show(
      context,
      title: 'SCAN PRODUCT BARCODE / QR',
      subtitle: 'Point camera at product barcode (EAN, UPC) or QR code',
    );

    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      setState(() {
        _barcodeCtrl.text = scannedCode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned Code: $scannedCode'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    final parsedStock = int.tryParse(_stockCtrl.text.trim()) ?? widget.product.stock;
    final parsedAlert = int.tryParse(_lowStockCtrl.text.trim()) ?? widget.product.lowStockAlert;

    final updatedProduct = widget.product.copyWith(
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? widget.product.price,
      category: _selectedCategory,
      stock: parsedStock < 0 ? 0 : parsedStock,
      lowStockAlert: parsedAlert < 0 ? 0 : parsedAlert,
      unit: _selectedUnit,
      barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
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

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Product',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${widget.product.name}" from your store inventory? This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);

    final auth = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    final success = await productProvider.removeProduct(
      auth.baseUrl,
      auth.apiKey,
      widget.product.id,
    );

    setState(() => _isDeleting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} deleted from inventory'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context, null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage ?? 'Failed to delete product'),
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
          context.tr('edit_product').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete Product',
            onPressed: (_isLoading || _isDeleting) ? null : _confirmDelete,
          ),
        ],
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
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter price';
                              final p = double.tryParse(v.trim());
                              if (p == null || p < 0) return 'Price cannot be negative';
                              return null;
                            },
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
                          .map((c) => DropdownMenuItem(value: c, child: Text(context.trCategory(c), style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              labelText: context.tr('stock_qty'),
                              prefixIcon: Icon(Icons.inventory_rounded, color: AppColors.chaiGold),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter stock';
                              final s = int.tryParse(v.trim());
                              if (s == null || s < 0) return 'Stock cannot be negative';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _lowStockCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              labelText: context.tr('alert_when_threshold'),
                              prefixIcon: Icon(Icons.warning_amber_rounded, color: AppColors.error),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter alert limit';
                              final a = int.tryParse(v.trim());
                              if (a == null || a < 0) return 'Cannot be negative';
                              return null;
                            },
                          ),
                        ),
                      ],
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
                  onPressed: (_isLoading || _isDeleting) ? null : _saveChanges,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(_isLoading ? 'SAVING...' : 'SAVE CHANGES'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_isLoading || _isDeleting) ? null : _confirmDelete,
                  icon: _isDeleting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                        )
                      : Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.error),
                  label: Text(
                    _isDeleting ? 'DELETING...' : 'DELETE PRODUCT',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withAlpha(128)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
