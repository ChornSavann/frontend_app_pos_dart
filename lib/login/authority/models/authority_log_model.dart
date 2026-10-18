import 'package:pos_inventory/models/user.dart';

class AuthLogModel {
  final int id;
  final String userId;
  final String action;
  final String timestamp;
  final User? user;

  AuthLogModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.timestamp,
    this.user,
  });

  factory AuthLogModel.fromJson(Map<String, dynamic> json) {
    return AuthLogModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'].toString(),
      action: json['action'] ?? 'LOGIN',
      timestamp: json['timestamp'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

// 👤 UserModel សម្រាប់ទាញយកឈ្មោះ និងទិន្នន័យ User ពេញលេញ
// class UserModel {
//   final String id;
//   final String name;
//   final String email;
//   final String? phone;
//   final String? image;
//
//   UserModel({
//     required this.id,
//     required this.name,
//     required this.email,
//     this.phone,
//     this.image,
//   });
//
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'].toString(),
//       name: json['name'] ?? 'Unknown User',
//       email: json['email'] ?? '',
//       phone: json['phone']?.toString(),
//       image: json['image']?.toString(),
//     );
//   }
// }