class ProductModelBanner {
  final int? id;
  final String name;
  final String description;
  final String imageUrl;
  final String? stockQuantity;
  ProductModelBanner({
    this.id,
    this.stockQuantity,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  factory ProductModelBanner.fromJson(Map<String, dynamic> json) {
    return ProductModelBanner(
      id: json['id'],
      stockQuantity: json['stock_quantity'],
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? 'No description available',
      imageUrl: json['image_url'] ?? '',
    );
  }
}