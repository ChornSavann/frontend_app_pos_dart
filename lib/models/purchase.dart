class PurchaseModel {
  final dynamic id;
  final String? purchaseNumber;
  final dynamic supplierId;
  final String? supplierName;
  final dynamic userId;
  final String? userName;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final String status;
  final String? notes;
  final List<dynamic>? items;

  PurchaseModel({
    this.id,
    this.purchaseNumber,
    required this.supplierId,
    this.supplierName,
    required this.userId,
    this.userName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.notes,
    this.items,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    String? supName;
    if (json['supplier'] != null && json['supplier'] is Map) {
      supName = json['supplier']['name']?.toString();
    } else {
      supName = json['supplier_name']?.toString();
    }

    String? uName;
    if (json['user'] != null && json['user'] is Map) {
      uName = json['user']['name']?.toString();
    } else {
      uName = json['user_name']?.toString();
    }

    return PurchaseModel(
      id: json['id'],
      purchaseNumber: json['purchase_number']?.toString(),
      supplierId: json['supplier_id'],
      supplierName: supName,
      userId: json['user_id'],
      userName: uName,
      subtotal: parseDouble(json['subtotal']),
      discount: parseDouble(json['discount']),
      tax: parseDouble(json['tax']),
      total: parseDouble(json['total']),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      status: json['status']?.toString() ?? 'completed',
      notes: json['notes']?.toString(),
      items: json['items'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'purchase_number': purchaseNumber,
      'supplier_id': supplierId,
      'user_id': userId,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'payment_method': paymentMethod,
      'status': status,
      'notes': notes,
      'items': items,
    };
  }
}