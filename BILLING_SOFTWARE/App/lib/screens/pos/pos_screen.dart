import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../providers/product_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/product_grid_item.dart';
import '../../widgets/camera_scanner_modal.dart';
import '../inventory/add_product_screen.dart';
import 'cart_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBarcodeScanner() async {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: true,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.itf,
        BarcodeFormat.qrCode,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.pdf417,
        BarcodeFormat.aztec,
      ],
    );

    String? lastScannedCode;
    DateTime? lastScanTime;
    String? lastAddedMessage;
    bool isSuccess = true;
    bool torchOn = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final billProvider = context.watch<BillProvider>();
          final productProvider = context.read<ProductProvider>();

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BARCODE / QR SCANNER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'Cart: ₹${billProvider.currentTotal.toStringAsFixed(0)} (${billProvider.itemCount} items)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: torchOn ? AppColors.chaiGold : Colors.white,
                            ),
                            onPressed: () {
                              controller.toggleTorch();
                              setSheetState(() => torchOn = !torchOn);
                            },
                          ),
                          if (billProvider.currentItems.isNotEmpty)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracotta,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('View Cart'),
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (lastAddedMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSuccess ? AppColors.forestMint.withAlpha(40) : AppColors.error.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSuccess ? AppColors.forestMint : AppColors.error,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          size: 18,
                          color: isSuccess ? AppColors.forestMint : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lastAddedMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (!isSuccess && lastScannedCode != null)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddProductScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.chaiGold,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),

                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      const boxW = 240.0;
                      const boxH = 140.0;
                      final scanWindow = Rect.fromCenter(
                        center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                        width: boxW,
                        height: boxH,
                      );

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: controller,
                            scanWindow: scanWindow,
                            errorBuilder: (ctx, err, child) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.terracotta),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Camera Access Issue (${err.errorCode.name})',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          controller.start();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.terracotta,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('RETRY CAMERA'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final rawValue = barcode.rawValue;
                                if (rawValue != null && rawValue.trim().isNotEmpty) {
                                  final trimmed = rawValue.trim();
                                  final now = DateTime.now();
                                  if (lastScannedCode == trimmed &&
                                      lastScanTime != null &&
                                      now.difference(lastScanTime!).inMilliseconds < 1500) {
                                    continue;
                                  }

                                  lastScannedCode = trimmed;
                                  lastScanTime = now;

                                  final product = productProvider.findProductByBarcode(trimmed);
                                  if (product != null) {
                                    billProvider.addItem(product);
                                    setSheetState(() {
                                      isSuccess = true;
                                      lastAddedMessage = 'Added 1x ${product.name} (₹${product.price.toStringAsFixed(0)}) to cart';
                                    });
                                  } else {
                                    setSheetState(() {
                                      isSuccess = false;
                                      lastAddedMessage = 'No product with barcode "$trimmed" found in inventory';
                                    });
                                  }
                                  break;
                                }
                              }
                            },
                          ),

                          CustomPaint(
                            painter: ScannerOverlayPainter(scanWindow: scanWindow),
                          ),

                          Center(
                            child: Container(
                              width: boxW,
                              height: boxH,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.terracotta, width: 2.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Align barcode / QR inside frame to auto-add',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddProductScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add New Product'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.chaiGold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final productProvider = context.watch<ProductProvider>();
    final billProvider = context.watch<BillProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('billing').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.terracotta),
            onPressed: _openBarcodeScanner,
            tooltip: 'Scan Barcode / QR',
          ),
          if (billProvider.currentItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              onPressed: () => billProvider.clearCart(),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => productProvider.setSearchQuery(q),
              style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: context.tr('search_placeholder'),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.terracotta),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          productProvider.setSearchQuery('');
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.terracotta),
                      onPressed: _openBarcodeScanner,
                      tooltip: 'Scan Barcode',
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(
            height: 40,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: productProvider.categories.length,
              itemBuilder: (context, index) {
                final category = productProvider.categories[index];
                final isSelected = productProvider.selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(category == 'All' ? context.tr('all_categories') : category),
                    selected: isSelected,
                    onSelected: (_) => productProvider.setCategory(category),
                    selectedColor: AppColors.primaryContainer,
                    backgroundColor: AppColors.surface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.terracotta : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? AppColors.terracotta : AppColors.borderSubtle),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: productProvider.products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(MascotAssets.box, width: 80, height: 80),
                        const SizedBox(height: 12),
                        Text(
                          'No products available',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _openBarcodeScanner,
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                          label: const Text('SCAN BARCODE TO ADD'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.only(left: 18, right: 18, top: 4, bottom: 120),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      final cartItemIndex = billProvider.currentItems.indexWhere(
                        (item) => item.product.id == product.id,
                      );
                      final countInCart = cartItemIndex >= 0 ? billProvider.currentItems[cartItemIndex].quantity : 0;

                      return ProductGridItem(
                        product: product,
                        countInCart: countInCart,
                        onAdd: () => billProvider.addItem(product),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: billProvider.currentItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${billProvider.itemCount} ${context.tr('cart')}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${billProvider.currentTotal.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                        label: Text(context.tr('cart').toUpperCase()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
