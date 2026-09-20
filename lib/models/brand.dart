class BrandModel {
  final int? id;
  final String name;
  final String slug;
  final String? description;
  final String? logo;
  final String iconName;
  final int productCount;
  final String? createdAt;
  final String? updatedAt;

  BrandModel({
    this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logo,
    this.createdAt,
    this.updatedAt,
    required this.iconName,
    required this.productCount,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    print("BRAND JSON DATA: $json");
    return BrandModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      logo: json['image_url'],
      iconName: json['iconName']?.toString() ?? 'grid_view',
      productCount: json['products_count'] is int
          ? json['products_count']
          : int.tryParse(json['products_count']?.toString() ?? '0') ?? 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'logo': logo,
    };
  }
}