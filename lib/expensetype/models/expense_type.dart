class ExpenseType {
  int ?id;
  String? name;
  String? description;

  ExpenseType({
    this.id,
    this.name,
    this.description,
  });


  factory ExpenseType.fromJson(Map<String, dynamic> json) {
    return ExpenseType(
      id:json['id'],
      name: json['name'],
      description: json['description'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id':id,
      'name': name,
      'description': description,
    };
  }
}