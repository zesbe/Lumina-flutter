class User {
  final int id;
  final String email;
  final String name;
  final String? avatar;
  final int credits;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.credits,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? '',
      avatar: json['avatar'],
      credits: json['credits'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
