class ProductModelBanner {
  final int? id;
  final String name;
  final String description;
  final String? sellingPrice;
  final String imageUrl;
  final String? stockQuantity;
  final int? alertQuantity;
  ProductModelBanner({
    this.id,
    this.stockQuantity,
    required this.name,
    required this.description,
    this.sellingPrice,
    required this.imageUrl,
    this.alertQuantity,
  });

  factory ProductModelBanner.fromJson(Map<String, dynamic> json) {
    return ProductModelBanner(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      stockQuantity: json['stock_quantity'],
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? 'No description available',
      sellingPrice: json['selling_price'],
      imageUrl: json['image_url'] ?? '',
      alertQuantity: json['alert_quantity'] != null
          ? int.tryParse(json['alert_quantity'].toString())
          : null,
    );
  }
}


