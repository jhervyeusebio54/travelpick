class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.isGuest = false,
  });

  final String id;
  final String name;
  final String email;
  final bool isGuest;

  String get displayLabel {
    if (isGuest) {
      return 'Guest Explorer';
    }
    return name.trim().isNotEmpty ? name : email;
  }
}
