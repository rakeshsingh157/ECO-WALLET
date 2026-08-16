import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/bill.dart';
import '../../models/bill_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/camera_scanner_modal.dart';
import '../../widgets/quantity_selector_modal.dart';
import '../../core/pdf_invoice_service.dart';

class ReturnOrderScreen extends StatefulWidget {
  final Bill? initialBill;

  const ReturnOrderScreen({super.key, this.initialBill});

  @override
  State<ReturnOrderScreen> createState() => _ReturnOrderScreenState();
}

class _ReturnOrderScreenState extends State<ReturnOrderScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Bill? _selectedBill;
  bool _isFullReturn = true;
  String _selectedReason = 'Customer Changed Mind';
  String _refundMode = 'cash';
  bool _isProcessing = false;

  final Map<String, double> _selectedItemQuantities = {};
  final List<String> _returnReasons = [
    'Customer Changed Mind',
    'Defective / Damaged',
    'Expired Product',
    'Wrong Item Billed',
    'Price Issue',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialBill != null) {
      _selectBill(widget.initialBill!);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectBill(Bill bill) {
    setState(() {
      _selectedBill = bill;
      _searchCtrl.text = bill.billId;
      _isFullReturn = true;
      _selectedItemQuantities.clear();
      for (final item in bill.items) {
        _selectedItemQuantities[item.product.id] = item.quantity;
      }
      _refundMode = bill.paymentMode == PaymentMode.ecoWallet ? 'wallet' : 'cash';
    });
  }

  void _scanInvoiceQr() async {
    final scanned = await CameraScannerModal.show(
      context,
      title: 'SCAN INVOICE BARCODE / QR',
      subtitle: 'Point camera at receipt QR code or barcode',
    );

    if (scanned != null && scanned.isNotEmpty && mounted) {
      String cleanId = scanned.trim();
      if (cleanId.contains('INVOICE:')) {
        final parts = cleanId.split('|');
        for (final p in parts) {
          if (p.startsWith('INVOICE:')) {
            cleanId = p.replaceFirst('INVOICE:', '').trim();
            break;
          }
        }
      }

      _searchCtrl.text = cleanId;
      _findBillById(cleanId);
    }
  }

  void _findBillById(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return;

    final billProvider = context.read<BillProvider>();
    final matched = billProvider.completedBills.firstWhere(
      (b) =>
          b.billId.toLowerCase() == clean ||
          b.billId.toLowerCase().contains(clean) ||
          (b.customerPhone != null && b.customerPhone!.toLowerCase().contains(clean)) ||
          (b.customerName != null && b.customerName!.toLowerCase().contains(clean)),
      orElse: () => Bill(
        billId: '',
        items: [],
        totalAmount: 0,
        timestamp: DateTime.now(),
      ),
    );

    if (matched.billId.isNotEmpty) {
      _selectBill(matched);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No completed bill found matching "$query"'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  double _calculateRefundAmount() {
    if (_selectedBill == null) return 0.0;
    if (_isFullReturn) {
      return _selectedBill!.netAmount;
    }

    double total = 0.0;
    for (final item in _selectedBill!.items) {
      final returnQty = _selectedItemQuantities[item.product.id] ?? 0.0;
      if (returnQty > 0) {
        total += returnQty * item.product.price;
      }
    }
    return total;
  }

  void _processReturn() async {
    if (_selectedBill == null) return;
    final refundAmount = _calculateRefundAmount();
    if (refundAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least 1 item or quantity to return'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final billProvider = context.read<BillProvider>();
    final productProvider = context.read<ProductProvider>();
    final apiService = auth.apiService;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Confirm Order Return & Refund',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill ID: ${_selectedBill!.billId}',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Refund Amount: ₹${refundAmount.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.terracotta),
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: $_selectedReason',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textPrimary),
            ),
            Text(
              'Refund Mode: ${_refundMode.toUpperCase()}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.forestMint, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'This will restock returned inventory and update today\'s sales.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta, foregroundColor: Colors.white),
            child: const Text('Confirm Refund'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    List<Map<String, dynamic>> returnedItemsList = [];
    if (!_isFullReturn) {
      for (final item in _selectedBill!.items) {
        final returnQty = _selectedItemQuantities[item.product.id] ?? 0.0;
        if (returnQty > 0) {
          returnedItemsList.add({
            'product_id': item.product.id,
            'name': item.product.name,
            'quantity': returnQty,
            'price': item.product.price,
          });
        }
      }
    }

    final response = await apiService.returnBill(
      billId: _selectedBill!.billId,
      returnType: _isFullReturn ? 'full' : 'partial',
      returnedItems: returnedItemsList,
      reason: _selectedReason,
      refundMode: _refundMode,
    );

    if (response['success'] == true) {
      _selectedBill!.refundedAmount += refundAmount;
      if (_selectedBill!.refundedAmount >= _selectedBill!.totalAmount) {
        _selectedBill!.status = BillStatus.returned;
      } else {
        _selectedBill!.status = BillStatus.partiallyReturned;
      }

      await billProvider.fetchBills(apiService);
      await productProvider.fetchProducts(auth.baseUrl, auth.apiKey);

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessReturnDialog(_selectedBill!, refundAmount);
      }
    } else {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to process return'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessReturnDialog(Bill bill, double refundedAmount) {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.forestMint, size: 28),
            const SizedBox(width: 10),
            Text(
              'Return Processed',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refund of ₹${refundedAmount.toStringAsFixed(2)} completed successfully.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Bill #${bill.billId} has been updated in records and stock has been restored.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              PdfInvoiceService.printOrShareInvoice(
                context,
                bill,
                shopName: auth.shopName,
                ownerName: auth.ownerName,
                phone: auth.phone,
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Updated Invoice PDF'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta, foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final refundAmount = _calculateRefundAmount();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'ORDER RETURNS & REFUNDS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SEARCH OR SCAN BILL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter Bill ID, customer name or phone...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _selectedBill = null);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderSubtle)),
                    ),
                    onSubmitted: _findBillById,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _scanInvoiceQr,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_selectedBill == null) ...[
              Text(
                'RECENT COMPLETED BILLS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (billProvider.completedBills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      'No completed bills found to return.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...billProvider.completedBills.take(8).map((b) => _buildRecentBillCard(b)),
            ] else ...[
              _buildBillDetailsCard(_selectedBill!),
              const SizedBox(height: 16),

              Text(
                'RETURN TYPE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isFullReturn = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isFullReturn ? AppColors.terracotta : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isFullReturn ? AppColors.terracotta : AppColors.borderSubtle),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Full Order Return',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _isFullReturn ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isFullReturn = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isFullReturn ? AppColors.terracotta : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: !_isFullReturn ? AppColors.terracotta : AppColors.borderSubtle),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Select Specific Items',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: !_isFullReturn ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!_isFullReturn) ...[
                Text(
                  'SELECT ITEMS & QUANTITY TO RETURN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._selectedBill!.items.map((item) => _buildItemReturnSelector(item)),
                const SizedBox(height: 16),
              ],

              Text(
                'RETURN REASON',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _returnReasons.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return ChoiceChip(
                    label: Text(reason),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedReason = reason),
                    selectedColor: AppColors.primaryContainer,
                    backgroundColor: AppColors.surface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.terracotta : AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? AppColors.terracotta : AppColors.borderSubtle),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Original Bill Total', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
                        Text('₹${_selectedBill!.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                    if (_selectedBill!.refundedAmount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Previously Refunded', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.error)),
                          Text('-₹${_selectedBill!.refundedAmount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Divider(color: AppColors.borderSubtle),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Refund Amount', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('₹${refundAmount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.terracotta)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing || refundAmount <= 0 ? null : _processReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          'CONFIRM RETURN & REFUND ₹${refundAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBillCard(Bill bill) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        onTap: () => _selectBill(bill),
        title: Text(
          bill.billId,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          '$dateStr • ${bill.customerName ?? "Counter Customer"}',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${bill.totalAmount.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.terracotta),
            ),
            Text(
              bill.paymentMode.name.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.forestMint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillDetailsCard(Bill bill) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.terracotta.withAlpha(128), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.billId, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bill.paymentMode.name.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forestMint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 8),
          Text(
            'Customer: ${bill.customerName ?? "Counter Customer"}${bill.customerPhone != null ? " (${bill.customerPhone})" : ""}',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Items: ${bill.items.length}',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildItemReturnSelector(BillItem item) {
    final returnQty = _selectedItemQuantities[item.product.id] ?? 0.0;
    final isSelected = returnQty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryContainer.withAlpha(80) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? AppColors.terracotta : AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: AppColors.terracotta,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedItemQuantities[item.product.id] = item.quantity;
                } else {
                  _selectedItemQuantities[item.product.id] = 0.0;
                }
              });
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  'Original: ${item.formattedQuantity} • ₹${item.product.price.toStringAsFixed(2)} / ${item.product.unit}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isSelected)
            GestureDetector(
              onTap: () {
                QuantitySelectorModal.show(
                  context,
                  product: item.product,
                  initialQuantity: returnQty,
                  onConfirmed: (newQty) {
                    setState(() {
                      _selectedItemQuantities[item.product.id] = newQty > item.quantity ? item.quantity : newQty;
                    });
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.terracotta),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ret: ${returnQty.toStringAsFixed(returnQty.truncateToDouble() == returnQty ? 0 : 2)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_rounded, size: 14, color: AppColors.terracotta),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '₹${(returnQty * item.product.price).toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
