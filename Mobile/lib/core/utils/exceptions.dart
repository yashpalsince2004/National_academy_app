class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, [this.code]);

  @override
  String toString() => message;
}

class UnauthorizedRoleException extends AuthException {
  UnauthorizedRoleException(super.message, [super.code]);
}
