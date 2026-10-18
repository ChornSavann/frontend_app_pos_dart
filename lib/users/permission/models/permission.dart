class Permission {
  final int? id;
  final String? name;
  final String? description;
  Permission({
    this.id,
    this.name,
    this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] as String?,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}