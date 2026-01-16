import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';

/// Repository contract for authentication operations.
///
/// Use cases depend on this interface, not the concrete implementation.
/// This enables:
/// - Easy mocking for tests
/// - Ability to swap implementations
/// - Clear contract definition
///
/// Implementation: AuthenticationRepository
abstract class IAuthenticationRepository {
  /// Logs in user with email and password.
  ///
  /// Returns [Result<AuthUser>] with authenticated user or error message.
  ///
  /// Possible errors:
  /// - 'No user found with this email address'
  /// - 'Incorrect password'
  /// - 'Invalid email address'
  /// - 'This account has been disabled'
  /// - 'Too many failed attempts. Please try again later'
  /// - 'Network error. Please check your connection'
  Future<Result<AuthUser>> loginWithEmailPassword({
    required String email,
    required String password,
  });

  /// Logs in user with Google OAuth.
  ///
  /// Triggers Google Sign-In flow and returns authenticated user.
  ///
  /// Returns [Result<AuthUser>] with authenticated user or error message.
  ///
  /// Possible errors:
  /// - 'Google sign-in was cancelled'
  /// - 'Google sign-in failed: [error details]'
  Future<Result<AuthUser>> loginWithGoogle();

  /// Registers new user with email and password.
  ///
  /// Returns [Result<AuthUser>] with created user or error message.
  ///
  /// Possible errors:
  /// - 'The email address is already in use'
  /// - 'The password is too weak'
  /// - 'Invalid email address'
  Future<Result<AuthUser>> registerWithEmailPassword({
    required String email,
    required String password,
  });

  /// Sends email verification to current user.
  ///
  /// Returns [Result<void>] indicating success or failure.
  Future<Result<void>> sendEmailVerification();

  /// Sends password reset email to the provided email address.
  ///
  /// Returns [Result<void>] indicating success or failure.
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Logs out current user.
  ///
  /// Clears Firebase authentication and Google sign-in session.
  ///
  /// Returns [Result<void>] indicating success or failure.
  Future<Result<void>> logout();

  /// Gets currently logged-in user, if any.
  ///
  /// Returns [Result<AuthUser?>] with user or null if not logged in.
  Future<Result<AuthUser?>> getCurrentUser();

  /// Re-authenticates user with email and password.
  ///
  /// Required for sensitive operations like:
  /// - Changing email
  /// - Changing password
  /// - Deleting account
  ///
  /// Returns [Result<void>] indicating success or failure.
  Future<Result<void>> reAuthenticate({
    required String email,
    required String password,
  });

  /// Deletes current user account.
  ///
  /// Returns [Result<void>] indicating success or failure.
  Future<Result<void>> deleteAccount();
}
