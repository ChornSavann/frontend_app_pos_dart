class User {
  int? id;
  String? name;
  String? email;
  String? phone;
  String?password;
  int?roleid;
  String? image;

  User({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.password,
    this.roleid,
    this.image,
  });


  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      roleid: json['role_id'],
      image: json['image_url'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password':password,
      'image': image,
    };
  }
}