part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent extends Equatable {}

class InitAuthEvent extends AuthEvent {
  final String apiKey;
  final LMSdkCallback callback;

  InitAuthEvent({
    required this.apiKey,
    required this.callback,
  });

  @override
  List<Object?> get props => [apiKey, callback];
}

class LoginEvent extends AuthEvent {
  final String userId;
  final String username;

  LoginEvent({
    required this.userId,
    required this.username,
  });

  @override
  List<Object?> get props => [userId, username];
}

class LogoutEvent extends AuthEvent {
  final String refreshToken;

  LogoutEvent({
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [refreshToken];
}
