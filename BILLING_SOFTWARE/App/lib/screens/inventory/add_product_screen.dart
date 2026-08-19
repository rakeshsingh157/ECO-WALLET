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
  final _lowStockCtrl = TextEditingController(text: '5');
  final _barcodeCtrl = TextEditingController();

  String _selectedCategory = 'Groceries';
  String _selectedUnit = 'pcs';
  bool _isLoading = false;

  final List<String> _units = ['pcs', 'kg', 'g', 'ltr', 'ml', 'pack', 'box', 'dozen'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _lowStockCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameCtrl.clear();
    _priceCtrl.clear();
    _stockCtrl.text = '10';
    _lowStockCtrl.text = '5';
    _barcodeCtrl.clear();
    setState(() {
      _selectedCategory = 'Groceries';
      _selectedUnit = 'pcs';
    });
  }

  void _adjustStock(int delta) {
    final current = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, 99999);
    setState(() {
      _stockCtrl.text = next.toString();
    });
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

  void _saveProduct() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    final parsedStock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final parsedAlert = int.tryParse(_lowStockCtrl.text.trim()) ?? 5;

    final newProduct = Product(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
      category: _selectedCategory,
      unit: _selectedUnit,
      stock: parsedStock < 0 ? 0 : parsedStock,
      lowStockAlert: parsedAlert < 0 ? 0 : parsedAlert,
      barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
    );

    final success = await productProvider.createProduct(
      auth.baseUrl,
      auth.apiKey,
      newProduct,
    );

    if (mounted) {
      setState(() => _isLoading = false);
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

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppColors.textPrimary,
            ),
          ),
          if (isRequired)
            Text(
              ' *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.terracotta,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF263345) : const Color(0xFFE8E4DC),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: AppColors.terracotta),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? const Color(0xFFBAC7D5) : const Color(0xFF4A5568),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;
    final categories = context.watch<ProductProvider>().categories.where((c) => c != 'All').toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('add_product').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Clear Form',
            onPressed: _isLoading ? null : _clearForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'Basic Information',
                      icon: Icons.inventory_2_rounded,
                      children: [
                        _buildFieldLabel(context.tr('product_name'), isRequired: true),
                        TextFormField(
                          controller: _nameCtrl,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Basmati Rice 1kg, Milk 500ml',
                            prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppColors.terracotta, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter product name' : null,
                        ),

                        const SizedBox(height: 16),

                        _buildFieldLabel('Category', isRequired: true),
                        DropdownButtonFormField<String>(
                          initialValue: categories.contains(_selectedCategory)
                              ? _selectedCategory
                              : (categories.isNotEmpty ? categories.first : 'Groceries'),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.grid_view_rounded, color: AppColors.terracotta, size: 20),
                          ),
                          items: categories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      context.trCategory(c),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),

                        const SizedBox(height: 16),

                        _buildFieldLabel(context.tr('barcode')),
                        TextFormField(
                          controller: _barcodeCtrl,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Scan or type EAN / UPC / QR code',
                            prefixIcon: Icon(Icons.qr_code_2_rounded, color: AppColors.textSecondary, size: 20),
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.terracotta.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.terracotta, size: 20),
                                tooltip: 'Scan Barcode',
                                onPressed: _scanBarcode,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    _buildSectionCard(
                      title: 'Pricing & Units',
                      icon: Icons.currency_rupee_rounded,
                      children: [
                        _buildFieldLabel(context.tr('selling_price'), isRequired: true),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: Text(
                                '₹',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.forestMint,
                                ),
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter price';
                            final numVal = double.tryParse(v.trim());
                            if (numVal == null || numVal < 0) return 'Price cannot be negative';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildFieldLabel('Unit of Measurement', isRequired: true),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _units.map((u) {
                            final isSelected = _selectedUnit == u;
                            return ChoiceChip(
                              label: Text(
                                u,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.terracotta,
                              backgroundColor: isDark ? const Color(0xFF1E2838) : const Color(0xFFF3EFEA),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.terracotta
                                    : (isDark ? const Color(0xFF2E3D52) : const Color(0xFFE0DACF)),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (_) => setState(() => _selectedUnit = u),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    _buildSectionCard(
                      title: 'Inventory & Stock Alert',
                      icon: Icons.inventory_rounded,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Stock Quantity', isRequired: true),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _adjustStock(-1),
                                        icon: const Icon(Icons.remove_circle_outline_rounded),
                                        color: AppColors.textSecondary,
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _stockCtrl,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return 'Enter stock';
                                            final s = int.tryParse(v.trim());
                                            if (s == null || s < 0) return 'Invalid';
                                            return null;
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _adjustStock(1),
                                        icon: const Icon(Icons.add_circle_outline_rounded),
                                        color: AppColors.terracotta,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Alert Limit'),
                                  TextFormField(
                                    controller: _lowStockCtrl,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Required';
                                      final alert = int.tryParse(v.trim());
                                      if (alert == null || alert < 0) return 'Invalid';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF263345) : const Color(0xFFE8E4DC),
                    width: 1.2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveProduct,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.add_circle_rounded, size: 20),
                    label: Text(
                      _isLoading ? 'SAVING PRODUCT...' : 'SAVE PRODUCT TO INVENTORY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      shadowColor: AppColors.terracotta.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
