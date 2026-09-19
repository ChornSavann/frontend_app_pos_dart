class Store {
  final dynamic id;
  final String name;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? logo;
  final String? description;

  Store({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.logo,
    this.description,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      website: json['website'], // 🟢 ទទួលតម្លៃពី JSON
      address: json['address'],
      logo: json['logo'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'website': website, // 🟢 បញ្ជូនទៅ API វិញ
      'address': address,
      'logo': logo,
      'description': description,
    };
  }
}