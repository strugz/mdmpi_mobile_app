/// Request object for login with email and password use case.
///
/// Encapsulates all input data needed for the login operation.
class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  /// Validates the login request data.
  /// Returns null if valid, otherwise returns an error message.
  String? validate() {
    if (email.isEmpty) {
      return 'Email is required';
    }

    if (!email.contains('@')) {
      return 'Invalid email format';
    }

    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null; // Valid
  }

  /// Returns true if the request data is valid.
  bool isValid() => validate() == null;

  @override
  String toString() {
    return 'LoginRequest(email: $email, rememberMe: $rememberMe)';
  }
}
