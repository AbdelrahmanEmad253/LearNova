class AuthSession {
  final String userId;
  final String? email;

  const AuthSession({
    required this.userId,
    this.email,
  });
}
