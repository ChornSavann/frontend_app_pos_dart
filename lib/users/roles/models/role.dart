
class Role {
  final String id;
  final String name;
  final String description;

  Role({required this.id, required this.name, required this.description});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'].toString(), // ធានាថា ID ត្រូវបានប្តូរជា String ជានិច្ច
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}