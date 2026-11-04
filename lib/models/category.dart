class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final String? iconName;
  final String? image;
  final String? imageUrl;
  final int productsCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.imageUrl,
    this.iconName,
    this.productsCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      imageUrl: json['image_url'],
      iconName: json['icon'],
      productsCount:
          json['products_count'] ??
          (json['products'] != null ? (json['products'] as List).length : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': iconName,
      'image': image,
    };
  }
}
