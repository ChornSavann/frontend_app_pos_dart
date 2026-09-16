class ReportDaily {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String createdAt;
  final CustomerModel? customer;
  final PaymentModel? payment;
  final List<OrderDetailModel> details;

  ReportDaily({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.customer,
    this.payment,
    required this.details,
  });

  factory ReportDaily.fromJson(Map<String, dynamic> json) {
    return ReportDaily(
      id: json['id'] != null ? double.parse(json['id'].toString()).toInt() : 0,
      orderNumber: json['order_number'] ?? '',
      totalAmount: json['total_amount'] != null
          ? double.parse(json['total_amount'].toString())
          : 0.0,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      payment: json['payment'] != null
          ? PaymentModel.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      details: json['details'] != null
          ? (json['details'] as List)
                .map(
                  (item) =>
                      OrderDetailModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}

class CustomerModel {
  final String name;
  CustomerModel({required this.name});

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(name: json['name'] ?? 'Guest');
  }
}

class PaymentModel {
  final String paymentMethod;
  PaymentModel({required this.paymentMethod});

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentMethod: json['payment_method'] ?? json['method'] ?? 'Cash',
    );
  }
}

class OrderDetailModel {
  final int quantity;
  final double price;
  final ProductModel? product;

  OrderDetailModel({required this.quantity, required this.price, this.product});

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    var rawPrice =
        json['price'] ??
        json['unit_price'] ??
        json['selling_price'] ??
        (json['product'] != null ? json['product']['selling_price'] : 0.0) ??
        0.0;

    return OrderDetailModel(
      quantity: json['quantity'] != null
          ? double.parse(json['quantity'].toString()).toInt()
          : 0,
      price: double.parse(rawPrice.toString()),
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ProductModel {
  final String name;
  final double sellingPrice;

  ProductModel({required this.name, required this.sellingPrice});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      name: json['name'] ?? 'Unknown Product',
      sellingPrice: json['selling_price'] != null
          ? double.parse(json['selling_price'].toString())
          : 0.0,
    );
  }
}
