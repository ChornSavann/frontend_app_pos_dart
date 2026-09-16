class Supplier {
  final int? id;
  final String name;
  final String? company;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  Supplier({
    this.id,
    required this.name,
    this.company,
    this.contactName,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // 📥 សម្រាប់បម្លែង JSON (ពី API Response) មកជា Object របស់ Supplier
  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'] ?? '',
      company: json['company'],
      contactName: json['contact_name'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      address: json['address'],
      // ដោះស្រាយបញ្ហា Boolean ឬ Integer (0/1) ពី Database
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // 📤 សម្រាប់បម្លែង Object ទៅជា Map/JSON ពេលផ្ញើទៅកាន់ API (POST/PUT)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'company': company,
      'contact_name': contactName,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'is_active': isActive,
    };
  }
}