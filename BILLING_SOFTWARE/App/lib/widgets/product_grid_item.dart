import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../core/theme.dart';
import '../core/localization.dart';

class ProductGridItem extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  final VoidCallback? onLongPress;
  final String? cartQuantityLabel;
  final bool isInCart;

  const ProductGridItem({
    super.key,
    required this.product,
    required this.onAdd,
    this.onLongPress,
    this.cartQuantityLabel,
    this.isInCart = false,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'beverages':
        return Icons.local_cafe_rounded;
      case 'snacks':
        return Icons.cookie_rounded;
      case 'bakery':
        return Icons.bakery_dining_rounded;
      case 'grains':
        return Icons.grain_rounded;
      case 'spices':
        return Icons.flare_rounded;
      case 'oil & ghee':
        return Icons.opacity_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;
    final isLowStock = product.isLowStock;

    return InkWell(
      onTap: isOutOfStock ? null : onAdd,
      onLongPress: isOutOfStock ? null : onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isInCart ? AppColors.primaryContainer.withAlpha(128) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInCart ? AppColors.terracotta : AppColors.borderSubtle,
            width: isInCart ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(product.category),
                    size: 20,
                    color: AppColors.terracotta,
                  ),
                ),
                if (isInCart)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.tr('in_cart'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isOutOfStock ? AppColors.textMuted : AppColors.textPrimary,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 4),

            if (isOutOfStock)
              Text(
                context.tr('out_of_stock'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              )
            else if (isLowStock)
              Text(
                '${context.tr('low_stock')} (${product.formattedStockQtyOnly})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              )
            else
              Text(
                product.unit.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isOutOfStock ? AppColors.textMuted : AppColors.terracotta,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? AppColors.surfaceElevated
                        : (isInCart ? AppColors.terracotta : AppColors.primaryContainer),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOutOfStock ? Icons.block_rounded : Icons.add_rounded,
                    color: isOutOfStock
                        ? AppColors.textMuted
                        : (isInCart ? Colors.white : AppColors.terracotta),
                    size: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
