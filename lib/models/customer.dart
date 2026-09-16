class Customer {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final int points;
  final String? address;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.points,
    this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      points: json['points'] is String ? int.parse(json['points']) : (json['points'] as int? ?? 0),
      address: json['address'] as String?,
    );
  }

  Object? toJson() {}
}