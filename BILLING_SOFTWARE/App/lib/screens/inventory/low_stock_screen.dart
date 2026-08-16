import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'edit_product_screen.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  String _selectedFilter = 'All';

  void _showQuickRestockDialog(Product product) {
    final qtyCtrl = TextEditingController(text: '10');
    final auth = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Quick Restock: ${product.name}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current stock: ${product.stock} ${product.unit} (Alert threshold: ${product.lowStockAlert})',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Quantity to Add (${product.unit})',
                prefixIcon: Icon(Icons.add_circle_outline_rounded, color: AppColors.forestMint),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [5, 10, 25, 50, 100].map((preset) {
                return ActionChip(
                  label: Text('+$preset'),
                  onPressed: () {
                    qtyCtrl.text = preset.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final toAdd = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (toAdd <= 0) return;
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              final newStock = product.stock + toAdd;
              final updated = product.copyWith(stock: newStock);
              await productProvider.updateProduct(auth.baseUrl, auth.apiKey, updated);
              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${product.name} restocked! New stock: $newStock ${product.unit}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta, foregroundColor: Colors.white),
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Product',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}" from inventory?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    await productProvider.removeProduct(auth.baseUrl, auth.apiKey, product.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} deleted from inventory'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final productProvider = context.watch<ProductProvider>();
    final allLowStock = productProvider.lowStockProducts;

    final filteredItems = allLowStock.where((p) {
      if (_selectedFilter == 'Out of Stock') return p.isOutOfStock;
      if (_selectedFilter == 'Critical (<= 2)') return p.stock > 0 && p.stock <= 2;
      if (_selectedFilter == 'Moderate') return p.stock > 2 && p.isLowStock;
      return true;
    }).toList();

    final outCount = allLowStock.where((p) => p.isOutOfStock).length;
    final criticalCount = allLowStock.where((p) => p.stock > 0 && p.stock <= 2).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'LOW STOCK ALERTS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('All', 'All (${allLowStock.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Out of Stock', 'Out of Stock ($outCount)', isError: true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Critical (<= 2)', 'Critical ($criticalCount)', isWarning: true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Moderate', 'Moderate'),
                ],
              ),
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(MascotAssets.box, width: 90, height: 90),
                          const SizedBox(height: 16),
                          Text(
                            'Sab Badhiya Hai!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedFilter == 'All'
                                ? 'All products have sufficient inventory stock.'
                                : 'No products found matching the "$_selectedFilter" filter.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = filteredItems[index];
                      final isOut = product.isOutOfStock;
                      final isCritical = product.stock > 0 && product.stock <= 2;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOut
                                ? AppColors.error.withAlpha(80)
                                : (isCritical ? AppColors.error.withAlpha(50) : AppColors.warning.withAlpha(50)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isOut
                                    ? AppColors.error.withAlpha(30)
                                    : (isCritical ? AppColors.error.withAlpha(20) : AppColors.warning.withAlpha(20)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isOut ? Icons.block_rounded : Icons.warning_amber_rounded,
                                color: isOut ? AppColors.error : (isCritical ? AppColors.error : AppColors.warning),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOut
                                        ? 'Out of stock (Alert at <= ${product.lowStockAlert})'
                                        : 'Only ${product.stock} ${product.unit} left (Alert at <= ${product.lowStockAlert})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isOut ? AppColors.error : (isCritical ? AppColors.error : AppColors.warning),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                              tooltip: 'Edit Product Details',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: AppColors.error.withAlpha(180), size: 20),
                              tooltip: 'Delete Product',
                              onPressed: () => _confirmDelete(product),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: () => _showQuickRestockDialog(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracotta,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                'Restock',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {bool isError = false, bool isWarning = false}) {
    final isSelected = _selectedFilter == key;
    Color activeColor = AppColors.terracotta;
    if (isError) activeColor = AppColors.error;
    if (isWarning) activeColor = AppColors.chaiGold;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
      selectedColor: activeColor.withAlpha(40),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? activeColor : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.borderSubtle,
      ),
    );
  }
}
