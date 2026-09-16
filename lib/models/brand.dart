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

  // 📥 Convert JSON ពី API មកជា BrandModel Object
  // factory BrandModel.fromJson(Map<String, dynamic> json) {
  //   return BrandModel(
  //     id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
  //     name: json['name'] ?? '',
  //     slug: json['slug'] ?? '',
  //     description: json['description'],
  //     logo: json['logo'],
  //     iconName: json['iconName']?.toString() ?? 'grid_view',
  //     productCount: json['products_count'] ?? (json['products'] != null ? (json['products'] as List).length : 0),
  //     createdAt: json['created_at'],
  //     updatedAt: json['updated_at'],
  //   );
  // }
  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      logo: json['logo'],
      // 🟢 ដាក់ Default ព្រោះ API មិនមានផ្ញើ iconName មកទេ
      iconName: json['iconName']?.toString() ?? 'grid_view',

      // 🟢 ឆែកមើល products_count ប្រសិនបើគ្មាន គឺកំណត់ឱ្យតម្លៃ 0 ឬ 1 (เพื่อให้វាបង្ហាញលើ UI)
      productCount: json['products_count'] is int
          ? json['products_count']
          : int.tryParse(json['products_count']?.toString() ?? '0') ?? 1,

      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
  // 📤 Convert BrandModel Object ទៅជា JSON (ពេលត្រូវការផ្ញើទៅ API)
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
