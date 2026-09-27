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
  final String orderType;
  final String? deliveryAddress;
  final double deliveryFee;

  final double? storeLat;
  final double? storeLng;
  final double? customerLat;
  final double? customerLng;

  final Map<String, dynamic>? deliveryData;

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
    this.storeLat,
    this.storeLng,
    this.customerLat,
    this.customerLng,
    this.deliveryData,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // 🔍 ត្រួតពិនិត្យមើលថាតើ Laravel ផ្ញើមកទម្រង់ Relation 'delivery' ឬអត់
    final delivery = json['delivery'] is Map<String, dynamic>
        ? json['delivery']
        : null;

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
      orderType: json['order_type'] ?? 'dine_in',
      deliveryAddress:
          json['delivery_address'] ?? delivery?['delivery_address'],
      deliveryFee: json['delivery_fee'] != null
          ? double.parse(json['delivery_fee'].toString())
          : (delivery?['delivery_fee'] != null
                ? double.parse(delivery!['delivery_fee'].toString())
                : 0.00),

      // 🗺️ ទាញយក Lat/Lng ពី Database (ទោះបីវស្ថិតក្នុង Object មេ ឬ Object 'delivery')
      storeLat: json['store_lat'] != null
          ? double.parse(json['store_lat'].toString())
          : (delivery?['store_lat'] != null
                ? double.parse(delivery!['store_lat'].toString())
                : null),
      storeLng: json['store_lng'] != null
          ? double.parse(json['store_lng'].toString())
          : (delivery?['store_lng'] != null
                ? double.parse(delivery!['store_lng'].toString())
                : null),
      customerLat: json['customer_lat'] != null
          ? double.parse(json['customer_lat'].toString())
          : (delivery?['customer_lat'] != null
                ? double.parse(delivery!['customer_lat'].toString())
                : null),
      customerLng: json['customer_lng'] != null
          ? double.parse(json['customer_lng'].toString())
          : (delivery?['customer_lng'] != null
                ? double.parse(delivery!['customer_lng'].toString())
                : null),

      deliveryData: delivery,
    );
  }
}
