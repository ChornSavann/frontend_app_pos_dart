class Delivery {
  final int? id;
  final int orderId;
  final String pickupAddress;
  final String deliveryAddress;
  final double deliveryFee;
  final String deliveryPartner;
  final String receiverName;
  final String receiverPhone;
  final String? note;
  final String status;

  Delivery({
    this.id,
    required this.orderId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.deliveryFee,
    required this.deliveryPartner,
    required this.receiverName,
    required this.receiverPhone,
    this.note,
    required this.status,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      orderId: json['order_id'] ?? 0,
      pickupAddress: json['pickup_address'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      deliveryFee: double.tryParse(json['delivery_fee'].toString()) ?? 0.0,
      deliveryPartner: json['delivery_partner'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      receiverPhone: json['receiver_phone'] ?? '',
      note: json['note'],
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'delivery_fee': deliveryFee,
      'delivery_partner': deliveryPartner,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'note': note,
      'status': status,
    };
  }
}