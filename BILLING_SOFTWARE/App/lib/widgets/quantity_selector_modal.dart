import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../core/theme.dart';
import '../core/localization.dart';

class QuantitySelectorModal extends StatefulWidget {
  final Product product;
  final double initialQuantity;
  final Function(double quantity) onConfirmed;

  const QuantitySelectorModal({
    super.key,
    required this.product,
    this.initialQuantity = 1.0,
    required this.onConfirmed,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    double initialQuantity = 1.0,
    required Function(double quantity) onConfirmed,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuantitySelectorModal(
        product: product,
        initialQuantity: initialQuantity,
        onConfirmed: onConfirmed,
      ),
    );
  }

  @override
  State<QuantitySelectorModal> createState() => _QuantitySelectorModalState();
}

class _QuantitySelectorModalState extends State<QuantitySelectorModal> {
  int _selectedTab = 0;
  late String _selectedSubUnit;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  double _computedQuantity = 1.0;
  double _computedPrice = 0.0;

  bool get _isWeightProduct {
    final u = widget.product.unit.toLowerCase().trim();
    return u == 'kg' || u == 'g' || u == 'gm' || u == 'gram';
  }

  bool get _isVolumeProduct {
    final u = widget.product.unit.toLowerCase().trim();
    return u == 'ltr' || u == 'l' || u == 'liter' || u == 'ml';
  }

  @override
  void initState() {
    super.initState();
    if (_isWeightProduct) {
      if (widget.initialQuantity < 1.0) {
        _selectedSubUnit = 'g';
        _qtyCtrl.text = (widget.initialQuantity * 1000).round().toString();
      } else {
        _selectedSubUnit = 'kg';
        _qtyCtrl.text = widget.initialQuantity.toStringAsFixed(widget.initialQuantity.truncateToDouble() == widget.initialQuantity ? 0 : 2);
      }
    } else if (_isVolumeProduct) {
      if (widget.initialQuantity < 1.0) {
        _selectedSubUnit = 'ml';
        _qtyCtrl.text = (widget.initialQuantity * 1000).round().toString();
      } else {
        _selectedSubUnit = 'L';
        _qtyCtrl.text = widget.initialQuantity.toStringAsFixed(widget.initialQuantity.truncateToDouble() == widget.initialQuantity ? 0 : 2);
      }
    } else {
      _selectedSubUnit = widget.product.unit;
      _qtyCtrl.text = widget.initialQuantity.toStringAsFixed(widget.initialQuantity.truncateToDouble() == widget.initialQuantity ? 0 : 1);
    }

    _computedQuantity = widget.initialQuantity;
    _computedPrice = widget.product.price * _computedQuantity;
    _amountCtrl.text = _computedPrice.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _recalculateFromQty(String text) {
    final val = double.tryParse(text.trim()) ?? 0.0;
    double baseQty = val;

    if (_isWeightProduct) {
      if (_selectedSubUnit == 'g') {
        baseQty = val / 1000.0;
      }
    } else if (_isVolumeProduct) {
      if (_selectedSubUnit == 'ml') {
        baseQty = val / 1000.0;
      }
    }

    setState(() {
      _computedQuantity = baseQty;
      _computedPrice = widget.product.price * _computedQuantity;
      if (_selectedTab == 0) {
        _amountCtrl.text = _computedPrice > 0 ? _computedPrice.toStringAsFixed(2) : '';
      }
    });
  }

  void _recalculateFromAmount(String text) {
    final amountVal = double.tryParse(text.trim()) ?? 0.0;
    if (widget.product.price <= 0) return;

    final baseQty = amountVal / widget.product.price;

    setState(() {
      _computedQuantity = baseQty;
      _computedPrice = amountVal;

      if (_isWeightProduct) {
        if (baseQty < 1.0) {
          _selectedSubUnit = 'g';
          _qtyCtrl.text = (baseQty * 1000).round().toString();
        } else {
          _selectedSubUnit = 'kg';
          _qtyCtrl.text = baseQty.toStringAsFixed(3);
        }
      } else if (_isVolumeProduct) {
        if (baseQty < 1.0) {
          _selectedSubUnit = 'ml';
          _qtyCtrl.text = (baseQty * 1000).round().toString();
        } else {
          _selectedSubUnit = 'L';
          _qtyCtrl.text = baseQty.toStringAsFixed(3);
        }
      } else {
        _qtyCtrl.text = baseQty.toStringAsFixed(2);
      }
    });
  }

  void _applyPreset(double qtyInBaseUnits, String subUnit, String displayVal) {
    setState(() {
      _selectedSubUnit = subUnit;
      _qtyCtrl.text = displayVal;
      _computedQuantity = qtyInBaseUnits;
      _computedPrice = widget.product.price * _computedQuantity;
      _amountCtrl.text = _computedPrice.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '₹${widget.product.price.toStringAsFixed(0)} / ${widget.product.unit}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTab = 0);
                          _recalculateFromQty(_qtyCtrl.text);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? AppColors.terracotta : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isWeightProduct ? 'BY WEIGHT (वजन)' : (_isVolumeProduct ? 'BY VOLUME (मात्रा)' : 'BY QUANTITY (मात्रा)'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTab = 1);
                          _recalculateFromAmount(_amountCtrl.text);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? AppColors.terracotta : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'BY RUPEES (रुपये)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_selectedTab == 0) ...[
                Text(
                  'QUICK PRESETS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildPresetChips(),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: _isWeightProduct ? 'Enter Weight' : (_isVolumeProduct ? 'Enter Volume' : 'Enter Quantity'),
                          hintText: 'e.g. 150',
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        onChanged: _recalculateFromQty,
                      ),
                    ),
                    if (_isWeightProduct || _isVolumeProduct) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _isWeightProduct
                              ? [
                                  _buildUnitButton('g'),
                                  _buildUnitButton('kg'),
                                ]
                              : [
                                  _buildUnitButton('ml'),
                                  _buildUnitButton('L'),
                                ],
                        ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                Text(
                  context.tr('enter_amount').toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAmountChip(10),
                    _buildAmountChip(20),
                    _buildAmountChip(50),
                    _buildAmountChip(100),
                    _buildAmountChip(200),
                    _buildAmountChip(500),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: context.tr('amount'),
                    hintText: 'e.g. 20',
                    prefixText: '₹ ',
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onChanged: _recalculateFromAmount,
                ),
              ],

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.terracotta.withAlpha(80)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('quantity').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          _formatComputedDisplay(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.tr('total').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '₹${_computedPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _computedQuantity <= 0
                      ? null
                      : () {
                          widget.onConfirmed(_computedQuantity);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    '${context.tr('add_to_bill').toUpperCase()} - ₹${_computedPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitButton(String unit) {
    final isSelected = _selectedSubUnit == unit;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubUnit = unit;
          _recalculateFromQty(_qtyCtrl.text);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.terracotta : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          unit,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPresetChips() {
    if (_isWeightProduct) {
      return [
        _buildChip('100 g', () => _applyPreset(0.100, 'g', '100')),
        _buildChip('250 g', () => _applyPreset(0.250, 'g', '250')),
        _buildChip('500 g', () => _applyPreset(0.500, 'g', '500')),
        _buildChip('1 kg', () => _applyPreset(1.0, 'kg', '1')),
        _buildChip('2 kg', () => _applyPreset(2.0, 'kg', '2')),
        _buildChip('5 kg', () => _applyPreset(5.0, 'kg', '5')),
      ];
    } else if (_isVolumeProduct) {
      return [
        _buildChip('100 ml', () => _applyPreset(0.100, 'ml', '100')),
        _buildChip('250 ml', () => _applyPreset(0.250, 'ml', '250')),
        _buildChip('500 ml', () => _applyPreset(0.500, 'ml', '500')),
        _buildChip('1 L', () => _applyPreset(1.0, 'L', '1')),
        _buildChip('2 L', () => _applyPreset(2.0, 'L', '2')),
        _buildChip('5 L', () => _applyPreset(5.0, 'L', '5')),
      ];
    } else {
      return [
        _buildChip('1', () => _applyPreset(1.0, widget.product.unit, '1')),
        _buildChip('2', () => _applyPreset(2.0, widget.product.unit, '2')),
        _buildChip('3', () => _applyPreset(3.0, widget.product.unit, '3')),
        _buildChip('5', () => _applyPreset(5.0, widget.product.unit, '5')),
        _buildChip('10', () => _applyPreset(10.0, widget.product.unit, '10')),
        _buildChip('12', () => _applyPreset(12.0, widget.product.unit, '12')),
      ];
    }
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
    );
  }

  Widget _buildAmountChip(int amount) {
    return ActionChip(
      label: Text('₹$amount'),
      onPressed: () {
        _amountCtrl.text = amount.toString();
        _recalculateFromAmount(amount.toString());
      },
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.terracotta,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
    );
  }

  String _formatComputedDisplay() {
    if (_isWeightProduct) {
      if (_computedQuantity < 1.0) {
        final g = (_computedQuantity * 1000).round();
        return '$g g (${_computedQuantity.toStringAsFixed(3)} kg)';
      }
      return '${_computedQuantity.toStringAsFixed(3)} kg';
    } else if (_isVolumeProduct) {
      if (_computedQuantity < 1.0) {
        final ml = (_computedQuantity * 1000).round();
        return '$ml ml (${_computedQuantity.toStringAsFixed(3)} L)';
      }
      return '${_computedQuantity.toStringAsFixed(3)} L';
    }
    return '${_computedQuantity.toStringAsFixed(2)} ${widget.product.unit}';
  }
}
