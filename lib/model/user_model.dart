

class UserModel {
  final String id;
  final String username;
  final String email;
  final String name;
  final String avatar;
  final String bio;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.avatar,
    required this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(), 
      username: json['username'] ?? '', 
      email: json['email'] ?? '', 
      name: json['name'] ?? '', 
      avatar: json['avatar'] ?? '', 
      bio: json['bio'] ?? '',
      );
  }
}