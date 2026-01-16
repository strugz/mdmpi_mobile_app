import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/repositories/i_authentication_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/usecases/login_request.dart';

/// Use case for logging in a user with email and password.
///
/// Responsibilities:
/// - Validates input (email format, password strength)
/// - Checks network connectivity
/// - Calls authentication repository
/// - Handles "remember me" functionality
/// - Returns Result<AuthUser> (no exceptions thrown)
///
/// Example:
/// ```dart
/// final useCase = Get.find<LoginWithEmailPasswordUseCase>();
/// final request = LoginRequest(
///   email: 'user@example.com',
///   password: 'password123',
///   rememberMe: true,
/// );
/// final result = await useCase.execute(request);
///
/// if (result.isSuccess) {
///   print('Logged in: ${result.value.email}');
/// } else {
///   print('Error: ${result.error}');
/// }
/// ```
class LoginWithEmailPasswordUseCase {
  final IAuthenticationRepository _authRepository;
  final NetworkManager _networkManager;
  final GetStorage _localStorage;

  LoginWithEmailPasswordUseCase({
    required IAuthenticationRepository authRepository,
    required NetworkManager networkManager,
    required GetStorage localStorage,
  })  : _authRepository = authRepository,
        _networkManager = networkManager,
        _localStorage = localStorage;

  /// Executes the login use case.
  Future<Result<AuthUser>> execute(LoginRequest request) async {
    // ========================================================================
    // STEP 1: Input Validation
    // ========================================================================
    final validationError = request.validate();
    if (validationError != null) {
      return Result.failure(validationError);
    }

    // ========================================================================
    // STEP 2: Network Connectivity Check
    // ========================================================================
    final isConnected = await _networkManager.isConnected();
    if (!isConnected) {
      return Result.failure('No internet connection. Please check your network.');
    }

    // ========================================================================
    // STEP 3: Authentication via Repository
    // ========================================================================
    final authResult = await _authRepository.loginWithEmailPassword(
      email: request.email.trim(),
      password: request.password.trim(),
    );

    // If login failed, return error immediately
    if (authResult.isFailure) {
      return Result.failure(authResult.error);
    }

    final user = authResult.value;

    // ========================================================================
    // STEP 4: Handle "Remember Me" Feature
    // ========================================================================
    if (request.rememberMe) {
      _saveCredentials(request.email, request.password);
    } else {
      _clearSavedCredentials();
    }

    // ========================================================================
    // STEP 5: Return Success
    // ========================================================================
    return Result.success(user);
  }

  // ========================================================================
  // PRIVATE HELPERS
  // ========================================================================

  void _saveCredentials(String email, String password) {
    _localStorage.write('REMEMBER_ME_EMAIL', email);
    _localStorage.write('REMEMBER_ME_PASSWORD', password);
  }

  void _clearSavedCredentials() {
    _localStorage.remove('REMEMBER_ME_EMAIL');
    _localStorage.remove('REMEMBER_ME_PASSWORD');
  }
}
