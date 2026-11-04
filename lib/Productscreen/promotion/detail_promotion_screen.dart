import 'package:flutter/material.dart';
import 'package:pos_inventory/Productscreen/models/product_promotion_model.dart';
import 'package:pos_inventory/Productscreen/promotion/update_promotion_screen.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';
import '../../api/promotion/api_promotion.dart';

class DetailPromotionScreen extends StatefulWidget {
  final ProductPromotionModel promotion;

  const DetailPromotionScreen({super.key, required this.promotion});

  @override
  State<DetailPromotionScreen> createState() => _DetailPromotionScreenState();
}

class _DetailPromotionScreenState extends State<DetailPromotionScreen> {
  final ApiPromotion _apiPromotion = ApiPromotion();

  // 🗑️ Delete Confirmation Dialog
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Delete Promotion",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to delete this promotion? Remaining stock will be returned to the product.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            bool success = await _apiPromotion.deletePromotion(widget.promotion.id);
                            if (success && mounted) {
                              Navigator.pop(context, true); // Return and refresh list
                            } else {
                              AppSnackBar.showError(context, "Failed to delete promotion.");
                            }
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = widget.promotion.product?.imageUrl;
    final double originalPrice = widget.promotion.product?.sellingPrice ?? 0.0;

    double discountAmount = widget.promotion.discountType == 'percentage'
        ? (originalPrice * widget.promotion.discountValue) / 100
        : widget.promotion.discountValue;
    double finalPrice = (originalPrice - discountAmount).clamp(
      0.0,
      double.infinity,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "ព័ត៌មានលម្អិតប្រូម៉ូសិន",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ✏️ Edit Button
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpdatePromotionScreen(
                    promotion: widget.promotion,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          // 🗑️ Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Colors.white),
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Big Banner Image Card
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF0F766E),
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🏷️ Title & Final Price Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.promotion.isActive
                              ? Colors.teal.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.promotion.isActive
                                ? Colors.teal.shade200
                                : Colors.red.shade200,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          widget.promotion.isActive ? "Active" : "Inactive",
                          style: TextStyle(
                            color: widget.promotion.isActive
                                ? const Color(0xFF0F766E)
                                : Colors.redAccent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "CODE: ${widget.promotion.promotionCode}",
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.promotion.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Final Price Highlight Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "តំលៃលក់ (Final Price):",
                          style: TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "\$${finalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 📋 General Information Section
            _buildSectionContainer(
              title: "ព័ត៌មានទូទៅ (General Information)",
              icon: Icons.info_outline_rounded,
              children: [
                _buildInfoRow(
                  icon: Icons.shopping_bag_outlined,
                  iconBg: Colors.blue.shade50,
                  iconColor: Colors.blue,
                  label: "ឈ្មោះផលិតផល (Product)",
                  value: widget.promotion.product?.name ?? "Product ID: ${widget.promotion.productId}",
                ),
                const Divider(height: 24, thickness: 0.5, color: Color(0xFFF1F5F9)),
                _buildInfoRow(
                  icon: Icons.description_outlined,
                  iconBg: Colors.orange.shade50,
                  iconColor: Colors.orange,
                  label: "បរិយាយ (Description)",
                  value: widget.promotion.description ?? "No description provided",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 💵 Pricing & Discount Section
            _buildSectionContainer(
              title: "តម្លៃ និងការបញ្ចុះ (Pricing & Discount)",
              icon: Icons.local_offer_outlined,
              children: [
                _buildInfoRow(
                  icon: Icons.attach_money_rounded,
                  iconBg: Colors.green.shade50,
                  iconColor: Colors.green,
                  label: "តំលៃដើម (Original Price)",
                  value: "\$${originalPrice.toStringAsFixed(2)}",
                ),
                const Divider(height: 24, thickness: 0.5, color: Color(0xFFF1F5F9)),
                _buildInfoRow(
                  icon: Icons.category_outlined,
                  iconBg: Colors.purple.shade50,
                  iconColor: Colors.purple,
                  label: "ប្រភេទបញ្ចុះ (Discount Type)",
                  value: widget.promotion.discountType == 'percentage' ? "Percentage (%)" : "Fixed Amount (\$)",
                ),
                const Divider(height: 24, thickness: 0.5, color: Color(0xFFF1F5F9)),
                _buildInfoRow(
                  icon: Icons.discount_outlined,
                  iconBg: Colors.deepOrange.shade50,
                  iconColor: Colors.deepOrange,
                  label: "ចំនួនបញ្ចុះ (Discount Value)",
                  value: widget.promotion.discountType == 'percentage'
                      ? "${widget.promotion.discountValue}%"
                      : "\$${widget.promotion.discountValue.toStringAsFixed(2)}",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🕒 Stock & Schedule Section
            _buildSectionContainer(
              title: "ស្តុក និងកាលវិភាគ (Stock & Schedule)",
              icon: Icons.calendar_today_outlined,
              children: [
                _buildInfoRow(
                  icon: Icons.inventory_2_outlined,
                  iconBg: Colors.teal.shade50,
                  iconColor: const Color(0xFF0F766E),
                  label: "ស្តុកប្រូម៉ូសិន (Promo Stock)",
                  value: widget.promotion.quantity?.toString() ?? "Unlimited",
                ),
                const Divider(height: 24, thickness: 0.5, color: Color(0xFFF1F5F9)),
                _buildInfoRow(
                  icon: Icons.date_range_outlined,
                  iconBg: Colors.indigo.shade50,
                  iconColor: Colors.indigo,
                  label: "ថ្ងៃចាប់ផ្តើម (Start Date)",
                  value: widget.promotion.startDate ?? "Not specified",
                ),
                const Divider(height: 24, thickness: 0.5, color: Color(0xFFF1F5F9)),
                _buildInfoRow(
                  icon: Icons.event_busy_outlined,
                  iconBg: Colors.red.shade50,
                  iconColor: Colors.redAccent,
                  label: "ថ្ងៃបញ្ចប់ (End Date)",
                  value: widget.promotion.endDate ?? "Not specified",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
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

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}