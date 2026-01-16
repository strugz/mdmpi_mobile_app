import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/repositories/i_authentication_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_repository.dart';

/// Use case for logging in a user with Google OAuth.
///
/// Responsibilities:
/// - Checks network connectivity
/// - Calls Google sign-in flow via repository
/// - Saves user profile to Firestore (if needed)
/// - Returns Result<AuthUser>
///
/// Example:
/// ```dart
/// final useCase = Get.find<LoginWithGoogleUseCase>();
/// final result = await useCase.execute();
///
/// if (result.isSuccess) {
///   print('Logged in with Google: ${result.value.email}');
/// } else {
///   print('Error: ${result.error}');
/// }
/// ```
class LoginWithGoogleUseCase {
  final IAuthenticationRepository _authRepository;
  final UserRepository _userRepository;
  final NetworkManager _networkManager;

  LoginWithGoogleUseCase({
    required IAuthenticationRepository authRepository,
    required UserRepository userRepository,
    required NetworkManager networkManager,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        _networkManager = networkManager;

  /// Executes Google login.
  Future<Result<AuthUser>> execute() async {
    // ========================================================================
    // STEP 1: Network Connectivity Check
    // ========================================================================
    final isConnected = await _networkManager.isConnected();
    if (!isConnected) {
      return Result.failure('No internet connection. Please check your network.');
    }

    // ========================================================================
    // STEP 2: Google Sign-In
    // ========================================================================
    final authResult = await _authRepository.loginWithGoogle();

    if (authResult.isFailure) {
      return Result.failure(authResult.error);
    }

    final user = authResult.value;

    // ========================================================================
    // STEP 3: Save User Profile to Firestore (if new user)
    // Note: This is best-effort - we don't fail the login if it fails
    // ========================================================================
    try {
      // Convert AuthUser to UserCredential-like structure for saving
      // This may need adjustment based on your UserModel structure
      await _userRepository.saveUserGoogleRecord(user);
    } catch (e) {
      // Log error but don't fail the login
      // The user is authenticated even if profile save fails
      print('Warning: Failed to save user record: $e');
    }

    // ========================================================================
    // STEP 4: Return Success
    // ========================================================================
    return Result.success(user);
  }
}

/// Extension to UserRepository for saving Google user
extension GoogleUserSave on UserRepository {
  /// Saves Google user profile (best effort)
  Future<void> saveUserGoogleRecord(AuthUser authUser) async {
    // This is a simplified version - adjust based on your actual implementation
    // You may need to create a UserModel from AuthUser
    try {
      // Check if user already exists
      final existingUser = await fetchUserDetails();
      if (existingUser.id.isEmpty) {
        // New user - save their basic profile
        // Implementation depends on your UserModel structure
      }
    } catch (e) {
      // Silently fail - not critical
      rethrow;
    }
  }
}
