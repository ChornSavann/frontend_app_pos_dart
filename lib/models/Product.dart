class Product {
  final int id;
  final int categoryId;
  final int brandId;
  final int unitId;
  final String name;
  final String slug;
  final String sku;
  final String? barcode;
  final String? description;
  final double costPrice;
  final double sellingPrice;
  final double stockQuantity;
  final double? alertQuantity;
  final String? imageUrl;
  final int isActive;
  bool isFavorite;

  final String? categoryName;
  final String? brandName;
  final String? unitName;

  Product({
    required this.id,
    required this.categoryId,
    required this.brandId,
    required this.unitId,
    required this.name,
    required this.slug,
    required this.sku,
    this.barcode,
    this.description,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.alertQuantity,
    this.imageUrl,
    required this.isActive,
    this.categoryName,
    this.brandName,
    this.unitName,
    this.isFavorite=false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    const String serverUrl = "http://10.0.2.2:8000/";
    String? rawImagePath = json['image'] as String?;

    return Product(
      id: json['id'] as int,
      categoryId: json['category_id'] is String ? int.parse(json['category_id']) : json['category_id'] as int,
      brandId: json['brand_id'] is String ? int.parse(json['brand_id']) : json['brand_id'] as int,
      unitId: json['unit_id'] is String ? int.parse(json['unit_id']) : json['unit_id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,

      costPrice: json['cost_price'] is String
          ? double.parse(json['cost_price'])
          : (json['cost_price'] as num).toDouble(),

      sellingPrice: json['selling_price'] is String
          ? double.parse(json['selling_price'])
          : (json['selling_price'] as num).toDouble(),

      stockQuantity: json['stock_quantity'] is String
          ? double.parse(json['stock_quantity'])
          : (json['stock_quantity'] as num).toDouble(),

      alertQuantity: json['alert_quantity'] != null
          ? (json['alert_quantity'] is String ? double.parse(json['alert_quantity']) : (json['alert_quantity'] as num).toDouble())
          : null,

      imageUrl: (rawImagePath != null && rawImagePath.isNotEmpty) ? "$serverUrl$rawImagePath" : null,

      isActive: json['is_active'] is String ? int.parse(json['is_active']) : (json['is_active'] as int? ?? 1),

      // 🔍 ទាញយកឈ្មោះពី Relation មកប្រើប្រាស់បានយ៉ាងស្រួល
      categoryName: json['category'] != null ? json['category']['name'] : null,
      brandName: json['brand'] != null ? json['brand']['name'] : null,
      unitName: json['unit'] != null ? json['unit']['name'] : null,
      isFavorite: json['is_favorite'] ?? false, // បើទិន្នន័យមកពី Database
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'brand_id': brandId,
      'unit_id': unitId,
      'name': name,
      'slug': slug,
      'sku': sku,
      'barcode': barcode,
      'description': description,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'alert_quantity': alertQuantity,
      'image': imageUrl,
      'is_active': isActive,
    };
  }
}