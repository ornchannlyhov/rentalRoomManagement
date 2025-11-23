class User {
  final String id;
  final String? username;
  final String? phoneNumber;
  final bool? phoneVerified;
  final String? email;
  final String? fcmToken;
  final String? token;

  User({
    required this.id,
    this.username,
    this.phoneNumber,
    this.phoneVerified,
    this.email,
    this.fcmToken,
    this.token,
  });
}
