class UnitModel {
  final int? id;
  final String name;
  final String shortName;
  final int? baseUnitId;
  final String? operator;
  final double? value;
  final UnitModel? baseUnit; // សម្រាប់ Relation ជាមួយ Base Unit (បើមាន)

  UnitModel({
    this.id,
    required this.name,
    required this.shortName,
    this.baseUnitId,
    this.operator,
    this.value,
    this.baseUnit,
  });

  // 🔄 1. Convert JSON from Laravel API to Dart Object
  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      shortName: json['short_name']?.toString() ?? '',
      baseUnitId: json['base_unit_id'] != null ? int.tryParse(json['base_unit_id'].toString()) : null,
      operator: json['operator']?.toString(),
      value: json['value'] != null ? double.tryParse(json['value'].toString()) : null,
      baseUnit: json['base_unit'] != null ? UnitModel.fromJson(json['base_unit']) : null,
    );
  }

  // 📤 2. Convert Dart Object to JSON for API Request (POST/PUT)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'short_name': shortName,
      'base_unit_id': baseUnitId,
      'operator': operator,
      'value': value,
    };
  }

  // 📋 3. CopyWith helper method for updating state or local objects easily
  UnitModel copyWith({
    int? id,
    String? name,
    String? shortName,
    int? baseUnitId,
    String? operator,
    double? value,
    UnitModel? baseUnit,
  }) {
    return UnitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      baseUnitId: baseUnitId ?? this.baseUnitId,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      baseUnit: baseUnit ?? this.baseUnit,
    );
  }
}