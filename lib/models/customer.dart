class Customer {
  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final int? points;
  final String? address;
  final int?
  ordersCount; // 🟢 1. បន្ថែម Variable សម្រាប់ទទួលចំនួន Order/Invoice

  Customer({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.points,
    this.address,
    this.ordersCount, // 🟢 2. បញ្ចូលក្នុង Constructor
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      points: json['points'] is String
          ? int.tryParse(json['points']) ?? 0
          : (json['points'] as int? ?? 0),
      address: json['address'] as String?,
      ordersCount: json['orders_count'] is String
          ? int.tryParse(json['orders_count']) ?? 0
          : (json['orders_count'] as int? ?? 0),
    );
  }
}
