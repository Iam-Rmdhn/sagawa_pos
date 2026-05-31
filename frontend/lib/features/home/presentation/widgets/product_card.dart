import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
import 'package:sagawa_pos/features/home/domain/models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onAdd});

  final Product product;
  final VoidCallback onAdd;

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF1F2F4),
      child: Icon(Icons.restaurant_rounded, size: 46, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveHelper.isTabletLandscape(context);
    final borderRadius = isCompact ? 16.0 : 22.0;
    final cardPadding = isCompact ? 10.0 : 14.0;
    final titleFontSize = isCompact ? 12.0 : 14.0;
    final priceFontSize = isCompact ? 12.0 : 14.0;
    final stockFontSize = isCompact ? 10.0 : 11.0;
    final addButtonSize = isCompact ? 28.0 : 36.0;
    final addIconSize = isCompact ? 18.0 : 22.0;

    return GestureDetector(
      onTap: product.stock > 0 ? onAdd : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: isCompact ? 10 : 18,
              offset: Offset(0, isCompact ? 5 : 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(borderRadius),
                    ),
                    child: Builder(
                      builder: (ctx) {
                        final img = product.imageAsset.trim();
                        if (img.isEmpty) {
                          return _buildImagePlaceholder();
                        }

                        if (img.startsWith('http') || img.startsWith('https')) {
                          return Image.network(
                            img,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          );
                        }

                        if (img.startsWith('data:')) {
                          try {
                            final comma = img.indexOf(',');
                            if (comma < 0) {
                              return _buildImagePlaceholder();
                            }
                            final base64Part = img.substring(comma + 1);
                            final bytes = base64Decode(base64Part);
                            return Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _buildImagePlaceholder(),
                            );
                          } catch (_) {
                            return _buildImagePlaceholder();
                          }
                        }

                        return Image.asset(
                          img,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              _buildImagePlaceholder(),
                        );
                      },
                    ),
                  ),
                  // Sold Out Banner
                  if (product.stock == 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(borderRadius),
                          ),
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 16 : 24,
                                vertical: isCompact ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4B4B),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCompact ? 14 : 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: titleFontSize,
                    ),
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isCompact ? 4 : 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.priceLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: priceFontSize,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: isCompact ? 2 : 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: isCompact ? 10 : 12,
                                  color: product.stock > 0
                                      ? Colors.grey.shade600
                                      : Colors.red.shade400,
                                ),
                                SizedBox(width: isCompact ? 2 : 4),
                                Text(
                                  'Stok: ${product.stock}',
                                  style: TextStyle(
                                    fontSize: stockFontSize,
                                    color: product.stock > 0
                                        ? Colors.grey.shade600
                                        : Colors.red.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Add indicator icon
                      Container(
                        height: addButtonSize,
                        width: addButtonSize,
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? const Color(0xFFFFB000)
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isCompact ? 8 : 12),
                            bottomRight: Radius.circular(isCompact ? 8 : 12),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: addIconSize,
                          color: product.stock > 0
                              ? Colors.white
                              : Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
