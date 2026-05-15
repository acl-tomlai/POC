import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Mirror of Pos.Api `Roles` constants.
class Roles {
  static const String admin = 'Admin';
  static const String manager = 'Manager';
  static const String cashier = 'Cashier';

  static bool isAdminOrManager(String role) => role == admin || role == manager;
}

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String fullName,
    required String email,
    required String role,
    required bool isActive,
    required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
