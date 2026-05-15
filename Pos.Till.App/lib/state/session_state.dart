import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory cashier session. Wiped on idle logout / 401 / manual sign-out.
/// The encrypted JWT blob on disk survives — the cashier just re-enters their
/// PIN next time.
class SessionState {
  const SessionState({
    this.token,
    this.userId,
    this.fullName,
    this.role,
  });

  final String? token;
  final String? userId;
  final String? fullName;
  final String? role;

  bool get isActive => token != null;
}

class SessionStateNotifier extends StateNotifier<SessionState> {
  SessionStateNotifier() : super(const SessionState());

  void signIn({
    required String token,
    required String userId,
    required String fullName,
    required String role,
  }) {
    state = SessionState(
      token: token,
      userId: userId,
      fullName: fullName,
      role: role,
    );
  }

  void signOut() {
    state = const SessionState();
  }
}
