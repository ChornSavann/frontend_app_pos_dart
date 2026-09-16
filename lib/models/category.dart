class CategoryModel {
  final int id;
  final String name;
  final String? iconName;
  final String? image;
  final int productsCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.iconName,
    this.productsCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      iconName: json['icon'],
      // ទទួលតម្លៃ products_count ពី Laravel (បើមានប្រើ withCount('products'))
      productsCount: json['products_count'] ?? (json['products'] != null ? (json['products'] as List).length : 0),
    );
  }
}