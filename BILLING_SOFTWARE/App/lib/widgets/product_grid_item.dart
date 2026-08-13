import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../core/theme.dart';

class ProductGridItem extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  final int countInCart;

  const ProductGridItem({
    super.key,
    required this.product,
    required this.onAdd,
    this.countInCart = 0,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'beverages':
        return Icons.coffee_rounded;
      case 'snacks':
        return Icons.cookie_rounded;
      case 'bakery':
        return Icons.bakery_dining_rounded;
      case 'grains':
        return Icons.rice_bowl_rounded;
      case 'spices':
        return Icons.outdoor_grill_rounded;
      case 'oil & ghee':
        return Icons.water_drop_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stock <= 5;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      onTap: onAdd,
      color: countInCart > 0
          ? AppColors.warmCoral.withValues(alpha: 0.15)
          : AppColors.darkCard,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon + Badge Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warmCoral.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(product.category),
                      color: AppColors.warmCoral,
                      size: 22,
                    ),
                  ),
                  if (countInCart > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.sunsetGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x$countInCart',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 4),

              // Stock warning if low
              if (isLowStock)
                Text(
                  'Only ${product.stock} left!',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),

              const SizedBox(height: 6),

              // Price + Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmPeach,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      gradient: AppColors.sunsetGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
