class Expense {
  int? id;
  int? userId;
  int? expenseTypeId;
  String? expenseType;
  String? amount;
  String? paymentMethod;
  String? referenceNo;
  String? expenseDate;
  String? note;

  Expense({
    this.id,
    this.userId,
    this.expenseTypeId,
    this.expenseType,
    this.amount,
    this.paymentMethod,
    this.referenceNo,
    this.expenseDate,
    this.note,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    // 🟢 ពិនិត្យមើលថាតើ expense_type ផ្ញើមកជា Map (Object) ឬយ៉ាងណា
    String? typeName;
    if (json['expense_type'] != null && json['expense_type'] is Map) {
      typeName = json['expense_type']['name'];
    } else {
      typeName = json['expense_type'] ?? json['expenseType'];
    }

    return Expense(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      expenseTypeId: json['expense_type_id'] ?? json['expenseTypeId'],
      expenseType: typeName,
      amount: json['amount']?.toString(),
      paymentMethod: json['payment_method'] ?? json['paymentMethod'],
      referenceNo: json['reference_no'] ?? json['referenceNo'],
      expenseDate: json['expense_date'] ?? json['expenseDate'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'expense_type_id': expenseTypeId,
      'expenseType': expenseType,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference_no': referenceNo,
      'expense_date': expenseDate,
      'note': note,
    };
  }
}
