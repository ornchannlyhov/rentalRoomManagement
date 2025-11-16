class User {
  final String id;
  final String? username;
  final String? email;
  final String? fcmToken; 
  final String? token;

  User({
    required this.id,
    this.username,
    this.email,
    this.fcmToken,
    this.token,
  });
}