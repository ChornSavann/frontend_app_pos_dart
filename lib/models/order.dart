class Order {
  final int id;
  final String orderNumber;
  final int? customerId;
  final int userId;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String status;
  final String orderType;         // 👈 បន្ថែម Field ប្រភេទនៃការកុម្ម៉ង់ (dine_in, take_away, delivery)
  final String? deliveryAddress;  // 👈 បន្ថែម Field អាសយដ្ឋានដឹកជញ្ជូន
  final double deliveryFee;       // 👈 បន្ថែម Field ថ្លៃសេវាដឹកជញ្ជូន

  Order({
    required this.id,
    required this.orderNumber,
    this.customerId,
    required this.userId,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.orderType,
    this.deliveryAddress,
    required this.deliveryFee,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      customerId: json['customer_id'],
      userId: json['user_id'],
      subtotal: double.parse(json['subtotal'].toString()),
      discountAmount: double.parse(json['discount_amount'].toString()),
      taxAmount: double.parse(json['tax_amount'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'] ?? 'completed',
      // 🚚 맵តម្លៃថ្មីៗពី JSON Response របស់ Laravel
      orderType: json['order_type'] ?? 'dine_in',
      deliveryAddress: json['delivery_address'],
      deliveryFee: json['delivery_fee'] != null
          ? double.parse(json['delivery_fee'].toString())
          : 0.00,
    );
  }
}