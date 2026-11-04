import '../../models/Product.dart';

class ProductPromotionModel {
  final int id;
  final int productId;
  final String title;
  final String? description;
  final String promotionCode;
  final int? quantity;
  final String discountType;
  final double discountValue;
  final double finalPrice;
  final double discountAmount;
  final bool isActive;
  final String? startDate;
  final String? endDate;
  final Product? product;

  ProductPromotionModel({
    required this.id,
    required this.productId,
    required this.title,
    this.description,
    required this.promotionCode,
    this.quantity,
    required this.discountType,
    required this.discountValue,
    required this.finalPrice,
    required this.discountAmount,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.product,
  });

  factory ProductPromotionModel.fromJson(Map<String, dynamic> json) {
    return ProductPromotionModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      promotionCode: json['promotion_code'] ?? '',
      quantity: json['quantity'],
      discountType: json['discount_type'] ?? 'percentage',
      discountValue: double.tryParse(json['discount_value'].toString()) ?? 0.0,
      finalPrice: double.tryParse(json['final_price']?.toString() ?? '0.0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0.0') ?? 0.0,
      startDate: json['start_date'],
      endDate: json['end_date'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}