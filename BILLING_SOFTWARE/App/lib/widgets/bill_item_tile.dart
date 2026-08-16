import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bill_item.dart';
import '../core/theme.dart';
import 'quantity_selector_modal.dart';

class BillItemTile extends StatelessWidget {
  final BillItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final Function(double newQty)? onQtyChanged;

  const BillItemTile({
    super.key,
    required this.item,
    required this.onAdd,
    required this.onRemove,
    this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.product.price.toStringAsFixed(0)} / ${item.product.unit}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.remove_rounded, color: AppColors.error, size: 18),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    QuantitySelectorModal.show(
                      context,
                      product: item.product,
                      initialQuantity: item.quantity,
                      onConfirmed: (newQty) {
                        if (onQtyChanged != null) {
                          onQtyChanged!(newQty);
                        }
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      item.formattedQuantity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.add_rounded, color: AppColors.terracotta, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Text(
            '₹${item.totalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.terracotta,
            ),
          ),
        ],
      ),
    );
  }
}
