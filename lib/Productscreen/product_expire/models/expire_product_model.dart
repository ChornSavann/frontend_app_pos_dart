import 'package:pos_inventory/models/Product.dart';

class ExpireProductModel {
  final int id;
  final int productId;
  final String? batchNumber;
  final int productStock;
  final String startDate;
  final String expireDate;
  final String productName;
  final String? productSku;
  final Product? product;

  ExpireProductModel({
    required this.id,
    required this.productId,
    this.batchNumber,
    this.product,
    required this.productStock,
    required this.startDate,
    required this.expireDate,
    required this.productName,
    this.productSku,
  });

  factory ExpireProductModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    Product? parsedProduct;

    if (productJson != null && productJson is Map<String, dynamic>) {
      parsedProduct = Product.fromJson(productJson);
    }

    final productMap = productJson ?? {};
    int stock = 0;
    if (parsedProduct?.stockQuantity != null) {
      stock = (parsedProduct!.stockQuantity).toInt();
    } else {
      stock =
          int.tryParse(productMap['stock_quantity']?.toString() ?? '0') ?? 0;
    }

    return ExpireProductModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      batchNumber: json['batch_number']?.toString(),
      productStock: stock,
      startDate: json['start_date']?.toString() ?? '',
      expireDate: json['expire_date']?.toString() ?? '',
      productName:
          parsedProduct?.name ??
          productMap['name']?.toString() ??
          'Unknown Product',
      productSku: parsedProduct?.sku ?? productMap['sku']?.toString(),
      product: parsedProduct,
    );
  }
}
