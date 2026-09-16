class User {
  int? id;
  String? name;
  String? email;
  String? phone;
  String?password;
  String? image;

  User({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.password,
    this.image,
  });

  // 📥 แปลง JSON មកជា User Object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      image: json['image'],
    );
  }

  // 📤 แปลง User Object ទៅជា JSON
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