class Store {
  final dynamic id;
  final String name;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? logo; // Path ដើម ឬ Full URL ពី Backend
  final String? description;
  final String? imageUrl; // 🟢 បន្ថែម Property សម្រាប់ទទួល image_url ស្រាប់ពី Laravel Appends

  Store({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.logo,
    this.description,
    this.imageUrl,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      address: json['address'],
      logo: json['logo'],
      description: json['description'],
      // 🟢 ទាញយក image_url ផ្ទាល់ពី Laravel accessor (appends)
      imageUrl: json['image_url'] ?? json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'logo': logo,
      'description': description,
    };
  }
}