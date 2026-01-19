# Use Cases Layer - Login Module Example

**Version:** 1.0  
**Date:** January 16, 2026  
**Purpose:** Detailed illustration of implementing Use Cases pattern for Login Module

---

## 📚 Table of Contents
1. [Current Architecture (Before)](#current-architecture-before)
2. [Clean Architecture with Use Cases (After)](#clean-architecture-with-use-cases-after)
3. [Layer-by-Layer Breakdown](#layer-by-layer-breakdown)
4. [Data Flow Diagrams](#data-flow-diagrams)
5. [File Structure](#file-structure)
6. [Key Concepts](#key-concepts)

---

## Current Architecture (Before)

### 🔴 Problem: Controller Does Too Much

```dart
// lib/features/authentication/controllers/login/login_controller.dart
class LoginController extends GetxController {
  final rememberMe = false.obs;
  final hidePassword = true.obs;
  final email = TextEditingController();
  final password = TextEditingController();
  
  Future<void> emailAndPasswordSignIn() async {
    // ❌ Network check in controller
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      BLoaders.errorSnackBar(title: 'Internet', message: 'No Internet Connection');
      return;
    }

    // ❌ Form validation in controller
    if (!loginFormKey.currentState!.validate()) {
      BLoaders.errorSnackBar(title: 'Authentication', message: 'Invalid Credentials');
      return;
    }

    try {
      // ❌ UI concerns (loading dialog)
      BFullScreenLoader.openLoadingDialog('Logging you in...', BImages.docerAnimation);

      // ❌ Business logic (remember me)
      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      }

      // ❌ Direct repository call
      await AuthenticationRepository.instance
          .loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      // ❌ UI concerns (stop loading)
      BFullScreenLoader.stopLoading();

      // ❌ Navigation logic
      await loadingController.loadInitialData();
      
    } catch (e) {
      // ❌ Error handling mixed with UI
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }
}
```

### Issues with Current Approach

| Issue | Description | Impact |
|-------|-------------|--------|
| **Mixed Responsibilities** | Controller handles UI, validation, business logic, data access | 🔴 Hard to test |
| **No Clear Contracts** | No explicit input/output types | 🔴 Unclear API |
| **Tight Coupling** | Direct dependency on repository | 🔴 Hard to mock |
| **Exception-based Errors** | Uses try-catch for error handling | 🟡 Implicit failures |
| **Hard to Reuse** | Login logic tied to this controller | 🔴 Can't reuse in other contexts |

---

## Clean Architecture with Use Cases (After)

### 🟢 Solution: Separate Concerns with Use Cases

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                               │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │              LoginController (GetX)                        │   │
│  │  • Manages UI state (loading, error messages)              │   │
│  │  • Handles user interactions                               │   │
│  │  • Delegates business logic to Use Cases                   │   │
│  │  • Shows loaders, snackbars, navigates                     │   │
│  └────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              │ execute(request)                     │
│                              ▼                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER (USE CASES)                    │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │           LoginWithEmailPasswordUseCase                    │   │
│  │  ✅ ONE responsibility: Login user with email/password     │   │
│  │  ✅ Clear input: LoginRequest (email, password, rememberMe)│   │
│  │  ✅ Clear output: Result<AuthUser>                         │   │
│  │  ✅ Validates input                                         │   │
│  │  ✅ Checks connectivity                                     │   │
│  │  ✅ Calls repository                                        │   │
│  │  ✅ Handles "remember me" logic                            │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │           LoginWithGoogleUseCase                           │   │
│  │  ✅ ONE responsibility: Login user with Google OAuth       │   │
│  │  ✅ Clear input: No parameters (Google handles prompt)     │   │
│  │  ✅ Clear output: Result<AuthUser>                         │   │
│  └────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              │ depends on interfaces                │
│                              ▼                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        DOMAIN LAYER                                 │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │         IAuthenticationRepository (Interface)              │   │
│  │  • loginWithEmailPassword(email, password)                 │   │
│  │  • loginWithGoogle()                                       │   │
│  │  • logout()                                                 │   │
│  │  • getCurrentUser()                                         │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │         AuthUser Entity (Pure Domain Model)                │   │
│  │  • id, email, displayName, isEmailVerified                 │   │
│  │  • isAuthenticated(), needsEmailVerification()             │   │
│  └────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              │ implements interface                 │
│                              ▼                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                                 │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │    AuthenticationRepository (Implementation)               │   │
│  │  • Implements IAuthenticationRepository                    │   │
│  │  • Talks to Firebase Auth                                  │   │
│  │  • Handles error mapping                                   │   │
│  │  • Converts Firebase User → AuthUser Entity                │   │
│  └────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│                     Firebase Auth SDK                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Layer-by-Layer Breakdown

### 1️⃣ Domain Layer (Pure Business Logic)

#### 📦 Entity: AuthUser

```dart
// lib/features/authentication/domain/entities/auth_user.dart

/// Pure domain entity representing an authenticated user.
/// Contains NO framework dependencies, NO serialization logic.
class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final DateTime createdAt;
  
  AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.isEmailVerified,
    required this.createdAt,
  });
  
  // ========================================================================
  // DOMAIN METHODS (Business Rules)
  // ========================================================================
  
  /// Checks if user is fully authenticated (logged in + email verified).
  bool isAuthenticated() {
    return id.isNotEmpty && isEmailVerified;
  }
  
  /// Checks if user needs email verification.
  bool needsEmailVerification() {
    return id.isNotEmpty && !isEmailVerified;
  }
  
  /// Returns display name or email as fallback.
  String getDisplayNameOrEmail() {
    return displayName?.isNotEmpty == true ? displayName! : email;
  }
  
  /// Creates a copy with updated fields.
  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  static AuthUser empty() => AuthUser(
    id: '',
    email: '',
    isEmailVerified: false,
    createdAt: DateTime.now(),
  );
}
```

#### 🔌 Repository Interface

```dart
// lib/features/authentication/domain/repositories/i_authentication_repository.dart

import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';

/// Contract for authentication operations.
/// Use cases depend on this interface, not concrete implementation.
abstract class IAuthenticationRepository {
  /// Logs in user with email and password.
  /// Returns [Result<AuthUser>] with authenticated user or error.
  Future<Result<AuthUser>> loginWithEmailPassword({
    required String email,
    required String password,
  });
  
  /// Logs in user with Google OAuth.
  /// Returns [Result<AuthUser>] with authenticated user or error.
  Future<Result<AuthUser>> loginWithGoogle();
  
  /// Registers new user with email and password.
  /// Returns [Result<AuthUser>] with created user or error.
  Future<Result<AuthUser>> registerWithEmailPassword({
    required String email,
    required String password,
  });
  
  /// Sends email verification to current user.
  Future<Result<void>> sendEmailVerification();
  
  /// Sends password reset email.
  Future<Result<void>> sendPasswordResetEmail(String email);
  
  /// Logs out current user.
  Future<Result<void>> logout();
  
  /// Gets currently logged-in user, if any.
  Future<Result<AuthUser?>> getCurrentUser();
  
  /// Re-authenticates user (for sensitive operations).
  Future<Result<void>> reAuthenticate({
    required String email,
    required String password,
  });
}
```

---

### 2️⃣ Application Layer (Use Cases)

#### 📋 Request/Response Objects

```dart
// lib/features/authentication/domain/usecases/login_with_email_password_usecase.dart

/// Input data for login use case.
class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;
  
  LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
  
  // Validation helper
  bool isValid() {
    return email.isNotEmpty && 
           email.contains('@') && 
           password.isNotEmpty && 
           password.length >= 6;
  }
  
  // Validation error message
  String? getValidationError() {
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Invalid email format';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
```

#### 🎯 Use Case: Login with Email/Password

```dart
// lib/features/authentication/domain/usecases/login_with_email_password_usecase.dart

import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/repositories/i_authentication_repository.dart';

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
    final validationError = request.getValidationError();
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
```

#### 🎯 Use Case: Login with Google

```dart
// lib/features/authentication/domain/usecases/login_with_google_usecase.dart

import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/repositories/i_authentication_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/i_user_repository.dart';

/// Use case for logging in a user with Google OAuth.
/// 
/// Responsibilities:
/// - Checks network connectivity
/// - Calls Google sign-in flow via repository
/// - Saves user profile to Firestore (if needed)
/// - Returns Result<AuthUser>
class LoginWithGoogleUseCase {
  final IAuthenticationRepository _authRepository;
  final IUserRepository _userRepository;
  final NetworkManager _networkManager;
  
  LoginWithGoogleUseCase({
    required IAuthenticationRepository authRepository,
    required IUserRepository userRepository,
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
    // ========================================================================
    final saveResult = await _userRepository.saveUserRecord(user);
    
    if (saveResult.isFailure) {
      // Log error but don't fail the login
      logDebug('Failed to save user record: ${saveResult.error}');
    }
    
    // ========================================================================
    // STEP 4: Return Success
    // ========================================================================
    return Result.success(user);
  }
}
```

#### 🎯 Use Case: Get Saved Credentials

```dart
// lib/features/authentication/domain/usecases/get_saved_credentials_usecase.dart

import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';

/// Saved credentials from "Remember Me" feature.
class SavedCredentials {
  final String email;
  final String password;
  
  SavedCredentials({required this.email, required this.password});
  
  bool get hasCredentials => email.isNotEmpty && password.isNotEmpty;
}

/// Use case for retrieving saved login credentials.
/// Used to populate login form when "Remember Me" was checked.
class GetSavedCredentialsUseCase {
  final GetStorage _localStorage;
  
  GetSavedCredentialsUseCase({required GetStorage localStorage})
      : _localStorage = localStorage;
  
  /// Gets saved credentials if they exist.
  Result<SavedCredentials> execute() {
    final email = _localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    final password = _localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    
    return Result.success(SavedCredentials(
      email: email,
      password: password,
    ));
  }
}
```

---

### 3️⃣ Presentation Layer (Controller)

#### 🎮 Updated LoginController

```dart
// lib/features/authentication/controllers/login/login_controller.dart

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/usecases/login_with_email_password_usecase.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/usecases/login_with_google_usecase.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/usecases/get_saved_credentials_usecase.dart';
import 'package:mdmpi_mobile_app/features/authentication/controllers/loading_screen/loading_screen_controller.dart';

/// Controller for login screen.
/// 
/// Responsibilities:
/// ✅ Manages UI state (loading, form values)
/// ✅ Handles user interactions (button taps)
/// ✅ Delegates business logic to Use Cases
/// ✅ Shows UI feedback (loaders, snackbars)
/// ✅ Handles navigation
/// 
/// Does NOT:
/// ❌ Validate business rules (use case does this)
/// ❌ Talk to repositories directly
/// ❌ Handle network checks (use case does this)
/// ❌ Implement "remember me" logic (use case does this)
class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // ========================================================================
  // DEPENDENCIES (Injected via DI)
  // ========================================================================
  late final LoginWithEmailPasswordUseCase _loginWithEmailUseCase;
  late final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  late final GetSavedCredentialsUseCase _getSavedCredentialsUseCase;
  late final LoadingScreenController _loadingController;
  
  // ========================================================================
  // UI STATE
  // ========================================================================
  final rememberMe = false.obs;
  final hidePassword = true.obs;
  final email = TextEditingController();
  final password = TextEditingController();
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    
    // Resolve dependencies
    _loginWithEmailUseCase = Get.find<LoginWithEmailPasswordUseCase>();
    _loginWithGoogleUseCase = Get.find<LoginWithGoogleUseCase>();
    _getSavedCredentialsUseCase = Get.find<GetSavedCredentialsUseCase>();
    _loadingController = Get.find<LoadingScreenController>();
    
    // Load saved credentials
    _loadSavedCredentials();
  }

  // ========================================================================
  // PUBLIC METHODS (Called from UI)
  // ========================================================================
  
  /// Handles email/password login button tap.
  Future<void> emailAndPasswordSignIn() async {
    // Form validation (UI-level validation)
    if (!loginFormKey.currentState!.validate()) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please fill in all required fields',
      );
      return;
    }

    // Show loading dialog
    BFullScreenLoader.openLoadingDialog(
      'Logging you in...',
      BImages.docerAnimation,
    );

    try {
      // Build request object
      final request = LoginRequest(
        email: email.text,
        password: password.text,
        rememberMe: rememberMe.value,
      );
      
      // Execute use case
      final result = await _loginWithEmailUseCase.execute(request);
      
      // Hide loading dialog
      BFullScreenLoader.stopLoading();
      
      // Handle result
      if (result.isSuccess) {
        _handleLoginSuccess(result.value);
      } else {
        _handleLoginFailure(result.error);
      }
      
    } catch (e) {
      // Catch unexpected errors
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(
        title: 'Unexpected Error',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Handles Google sign-in button tap.
  Future<void> googleSignIn() async {
    // Show loading dialog
    BFullScreenLoader.openLoadingDialog(
      'Logging you in...',
      BImages.docerAnimation,
    );

    try {
      // Execute use case (no parameters needed)
      final result = await _loginWithGoogleUseCase.execute();
      
      // Hide loading dialog
      BFullScreenLoader.stopLoading();
      
      // Handle result
      if (result.isSuccess) {
        _handleLoginSuccess(result.value);
      } else {
        _handleLoginFailure(result.error);
      }
      
    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(
        title: 'Unexpected Error',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // ========================================================================
  // PRIVATE HELPERS (UI Logic Only)
  // ========================================================================
  
  void _loadSavedCredentials() {
    final result = _getSavedCredentialsUseCase.execute();
    
    if (result.isSuccess && result.value.hasCredentials) {
      email.text = result.value.email;
      password.text = result.value.password;
      rememberMe.value = true;
    }
  }
  
  void _handleLoginSuccess(AuthUser user) {
    // Show success message
    BLoaders.successSnackBar(
      title: 'Welcome!',
      message: 'Logged in as ${user.email}',
    );
    
    // Load initial data (user profile, app data, etc.)
    _loadingController.loadInitialData();
    
    // Navigation is handled by authentication repository's screenRedirect
  }
  
  void _handleLoginFailure(String error) {
    BLoaders.errorSnackBar(
      title: 'Login Failed',
      message: error,
    );
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
```

---

### 4️⃣ Data Layer (Repository Implementation)

#### 🗄️ Repository Implementation

```dart
// lib/data/repositories/authentication/authentication_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/repositories/i_authentication_repository.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/firebase_auth_exceptions.dart';

/// Concrete implementation of authentication repository.
/// Implements the domain interface and talks to Firebase.
class AuthenticationRepository implements IAuthenticationRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  
  AuthenticationRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<Result<AuthUser>> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Call Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Convert Firebase User to Domain Entity
      final authUser = _mapFirebaseUserToEntity(userCredential.user);
      
      return Result.success(authUser);
      
    } on FirebaseAuthException catch (e) {
      // Map Firebase errors to user-friendly messages
      final message = _mapFirebaseAuthError(e.code);
      return Result.failure(message);
      
    } catch (e) {
      return Result.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<Result<AuthUser>> loginWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return Result.failure('Google sign-in was cancelled');
      }
      
      // Get authentication details
      final googleAuth = await googleUser.authentication;
      
      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with Google credentials
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Convert to domain entity
      final authUser = _mapFirebaseUserToEntity(userCredential.user);
      
      return Result.success(authUser);
      
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseAuthError(e.code);
      return Result.failure(message);
      
    } catch (e) {
      return Result.failure('Google sign-in failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      
      if (firebaseUser == null) {
        return Result.success(null);
      }
      
      final authUser = _mapFirebaseUserToEntity(firebaseUser);
      return Result.success(authUser);
      
    } catch (e) {
      return Result.failure('Failed to get current user: ${e.toString()}');
    }
  }

  // ... other methods (registerWithEmailPassword, sendEmailVerification, etc.)

  // ========================================================================
  // PRIVATE HELPERS (Mapping)
  // ========================================================================
  
  /// Converts Firebase User to Domain Entity.
  AuthUser _mapFirebaseUserToEntity(User? firebaseUser) {
    if (firebaseUser == null) {
      return AuthUser.empty();
    }
    
    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }
  
  /// Maps Firebase error codes to user-friendly messages.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}
```

---

## Data Flow Diagrams

### Flow 1: Email/Password Login

```
┌────────────────────────────────────────────────────────────────────┐
│                         USER ACTION                                │
│  User taps "Login" button after entering email & password         │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│                    LoginController                                 │
│  • Validates form (UI-level check)                                 │
│  • Shows loading dialog                                            │
│  • Builds LoginRequest(email, password, rememberMe)                │
│  • Calls: await _loginWithEmailUseCase.execute(request)            │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│           LoginWithEmailPasswordUseCase                            │
│  1. Validates input (email format, password length)                │
│  2. Checks network connectivity                                    │
│  3. Calls: await _authRepository.loginWithEmailPassword(...)       │
│  4. If success: handles "remember me" (saves credentials)          │
│  5. Returns: Result<AuthUser>                                      │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│            IAuthenticationRepository (Interface)                   │
│  Contract method: loginWithEmailPassword(email, password)          │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│         AuthenticationRepository (Implementation)                  │
│  1. Calls Firebase: _auth.signInWithEmailAndPassword(...)          │
│  2. Handles Firebase exceptions                                    │
│  3. Maps Firebase User → AuthUser Entity                           │
│  4. Returns: Result<AuthUser>                                      │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│                      Firebase Auth SDK                             │
│  Authenticates user and returns UserCredential                     │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
         ┌─────────────────┴──────────────────┐
         │                                    │
    Success                               Failure
         │                                    │
         ▼                                    ▼
┌─────────────────────┐           ┌─────────────────────┐
│ Result.success(     │           │ Result.failure(     │
│   AuthUser          │           │   'Error message'   │
│ )                   │           │ )                   │
└──────┬──────────────┘           └──────┬──────────────┘
       │                                  │
       └──────────────┬───────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────────────────┐
│                  Back to LoginController                           │
│  • Hides loading dialog                                            │
│  • If success: Shows success snackbar, loads initial data          │
│  • If failure: Shows error snackbar                                │
└────────────────────────────────────────────────────────────────────┘
```

### Flow 2: Google Sign-In

```
User taps "Sign in with Google"
         │
         ▼
   LoginController
         │ calls loginWithGoogleUseCase.execute()
         ▼
   LoginWithGoogleUseCase
         │ 1. Check network
         │ 2. Call repository.loginWithGoogle()
         │ 3. Save user record to Firestore
         ▼
   IAuthenticationRepository (interface)
         │
         ▼
   AuthenticationRepository
         │ 1. Trigger Google Sign-In flow
         │ 2. Get Google credentials
         │ 3. Sign in to Firebase with credentials
         │ 4. Map Firebase User → AuthUser
         ▼
   Result<AuthUser>
         │
         ▼
   Back to Controller
         │ Show success/error
         │ Navigate to home
```

---

## File Structure

### 📁 Proposed Folder Organization

```
lib/
  features/
    authentication/
      domain/                           # ← NEW: Domain layer
        entities/
          auth_user.dart                # Pure domain entity
        repositories/
          i_authentication_repository.dart  # Repository interface
        usecases/
          login_with_email_password_usecase.dart
          login_with_google_usecase.dart
          get_saved_credentials_usecase.dart
          logout_usecase.dart
          register_with_email_password_usecase.dart
          send_email_verification_usecase.dart
          send_password_reset_usecase.dart
      
      application/                      # ← RENAMED: was "controllers"
        login/
          login_controller.dart         # Updated to use use cases
        signup/
          signup_controller.dart
        forget_password/
          forget_password_controller.dart
      
      presentation/                     # ← RENAMED: was "screens"
        screens/
          login/
            login.dart
            widgets/
              login_form.dart
              login_header.dart
        signup/
          signup.dart
        forget_password/
          forget_password.dart
  
  data/
    repositories/
      authentication/
        authentication_repository.dart  # Implements IAuthenticationRepository
  
  base/
    utils/
      result.dart                       # Result<T> type for error handling
```

**Note:** Folder restructure is optional! You can keep current structure and just add:
- `features/authentication/domain/` folder
- Use cases inside `domain/usecases/`
- Keep controllers where they are, just update them to use use cases

---

## Key Concepts

### 🎯 What is a Use Case?

**Definition:** A use case represents **one specific business operation** that a user wants to perform.

**Characteristics:**
- ✅ **Single Responsibility**: Does ONE thing (e.g., "Login with email")
- ✅ **Clear Input**: Explicit request object (e.g., `LoginRequest`)
- ✅ **Clear Output**: Explicit result type (e.g., `Result<AuthUser>`)
- ✅ **Reusable**: Can be called from controller, CLI, test, background job
- ✅ **Testable**: Easy to test with mocked dependencies
- ✅ **Framework-Agnostic**: No GetX, no Flutter dependencies (business logic only)

### 📊 Comparison Table

| Aspect | Current (Controller) | With Use Cases |
|--------|---------------------|----------------|
| **Where is business logic?** | In controller | In use case |
| **How many responsibilities?** | Many (UI + validation + network + data) | One per use case |
| **Input/Output** | Implicit (text controllers) | Explicit (request/result objects) |
| **Error handling** | Exceptions (try-catch) | Result<T> (explicit) |
| **Testing** | Hard (need GetX setup) | Easy (just mock repository) |
| **Reusability** | Tied to controller | Can be used anywhere |
| **Dependency** | Concrete repositories | Abstract interfaces |

### ✅ Benefits of Use Cases

1. **Testability** 🎯
   ```dart
   test('should login successfully with valid credentials', () async {
     // Arrange
     when(mockAuthRepo.loginWithEmailPassword(
       email: 'user@test.com',
       password: 'password123',
     )).thenAnswer((_) async => Result.success(mockUser));
     
     // Act
     final result = await useCase.execute(validRequest);
     
     // Assert
     expect(result.isSuccess, true);
     expect(result.value.email, 'user@test.com');
   });
   ```

2. **Clarity** 📖
   - Input: `LoginRequest` (clear what's needed)
   - Output: `Result<AuthUser>` (clear what you get back)
   - No surprises, no hidden side effects

3. **Reusability** ♻️
   - Same use case can be called from:
     - UI controller (current)
     - Background job (auto-login)
     - CLI tool (admin scripts)
     - Another use case (composition)

4. **Maintainability** 🛠️
   - Change validation rules? Update use case only
   - Add logging? Update use case only
   - Controller stays simple

### ❓ When to Use Use Cases

**Use use cases when:**
- ✅ Operation is complex (multiple steps, validations)
- ✅ Operation needs thorough testing
- ✅ Operation may be reused
- ✅ Business rules may change

**Skip use cases when:**
- ❌ Simple getter (e.g., `getCurrentUser()` - just call repository)
- ❌ Pure UI logic (e.g., toggle password visibility)
- ❌ One-time operation unlikely to change

---

## Summary: Before vs After

### Before (Current)

```dart
// ❌ Controller does everything
class LoginController extends GetxController {
  Future<void> emailAndPasswordSignIn() async {
    // Network check
    if (!await NetworkManager.instance.isConnected()) { ... }
    
    // Form validation
    if (!loginFormKey.currentState!.validate()) { ... }
    
    // Show loader
    BFullScreenLoader.openLoadingDialog(...);
    
    // Save credentials
    if (rememberMe.value) { localStorage.write(...) }
    
    // Call repository directly
    await AuthenticationRepository.instance.loginWithEmailAndPassword(...);
    
    // Hide loader
    BFullScreenLoader.stopLoading();
    
    // Navigate
    await loadingController.loadInitialData();
  }
}
```

**Issues:** Mixed responsibilities, hard to test, not reusable

---

### After (With Use Cases)

```dart
// ✅ Controller delegates to use case
class LoginController extends GetxController {
  Future<void> emailAndPasswordSignIn() async {
    // Validate form (UI concern)
    if (!loginFormKey.currentState!.validate()) { ... }
    
    // Show loader (UI concern)
    BFullScreenLoader.openLoadingDialog(...);
    
    // Build request
    final request = LoginRequest(
      email: email.text,
      password: password.text,
      rememberMe: rememberMe.value,
    );
    
    // Execute use case (business logic)
    final result = await _loginUseCase.execute(request);
    
    // Hide loader (UI concern)
    BFullScreenLoader.stopLoading();
    
    // Handle result (UI concern)
    if (result.isSuccess) {
      _handleSuccess(result.value);
    } else {
      _handleFailure(result.error);
    }
  }
}

// ✅ Use case handles business logic
class LoginWithEmailPasswordUseCase {
  Future<Result<AuthUser>> execute(LoginRequest request) async {
    // Validate input
    if (!request.isValid()) { return Result.failure(...) }
    
    // Check network
    if (!await _networkManager.isConnected()) { return Result.failure(...) }
    
    // Authenticate
    final result = await _authRepository.loginWithEmailPassword(...);
    
    // Handle "remember me"
    if (request.rememberMe) { _saveCredentials(...) }
    
    return result;
  }
}
```

**Benefits:** Clear separation, easy to test, reusable

---

## 📚 Next Steps

1. **Read this illustration** to understand the pattern
2. **Review the [Migration Examples](./CLEAN_ARCHITECTURE_MIGRATION_EXAMPLES.md)** for code templates
3. **Discuss with your team** whether this pattern adds value
4. **Start small**: Implement one use case (e.g., `LoginWithEmailPasswordUseCase`)
5. **Evaluate**: Does it make code better? Easier to test?
6. **Decide**: Roll out to other modules or stop here

---

**Document Owner:** Development Team  
**Last Updated:** January 16, 2026  
**Related Docs:**
- [Clean Architecture Analysis](./CLEAN_ARCHITECTURE_ANALYSIS.md)
- [Migration Examples](./CLEAN_ARCHITECTURE_MIGRATION_EXAMPLES.md)
- [Executive Summary](./CLEAN_ARCHITECTURE_EXECUTIVE_SUMMARY.md)
