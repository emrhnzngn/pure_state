/// User model representing an authenticated user.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;

  User copyWith({int? id, String? name, String? email, UserRole? role}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role.name};
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.user,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, name, email, role);

  @override
  String toString() => 'User(id: $id, name: $name, email: $email, role: $role)';
}

/// User roles for authorization.
enum UserRole {
  admin,
  user,
  guest;

  bool get isAdmin => this == UserRole.admin;
  bool get canCreateTasks => this == UserRole.admin || this == UserRole.user;
  bool get canDeleteOthersTasks => this == UserRole.admin;
}

