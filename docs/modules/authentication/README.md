# Authentication Module

## Overview

The Authentication module handles user authentication for the MDMPI Mobile App. It follows a **Clean Architecture variant** with domain entities, use cases, and an interface repository. It supports Firebase email/password login, Google Sign-In, email verification, password reset, and user signup with role and department selection.

## Auth Flow

```
App Launch
  → SplashScreen (FlutterNativeSplash)
    → AuthenticationRepository.screenRedirect()
      ├─ Not authenticated → LoginScreen
      ├─ Authenticated, email not verified → VerifyEmailScreen
      └─ Authenticated & verified → AppRouter (department-based onboarding)
```

## Architecture

This module uniquely follows **Clean Architecture** with a domain layer (entities, params, repositories, use cases) and a presentation layer (controllers, pages, widgets).

### Folder Structure

```
lib/
  features/authentication/
    domain/
      entities/
        auth_user.dart                      # AuthUser entity
      params/
        login_request.dart                  # LoginRequest params object
      repositories/
        i_authentication_repository.dart    # Abstract repository interface
      usecases/
        login_with_email_password_usecase.dart
        login_with_google_usecase.dart
    presentation/
      controllers/
        login_controller.dart               # Login state & orchestration
        signup_controller.dart              # Signup state & form management
        loading_screen_controller.dart      # Loading screen state
        forget_password_controller.dart     # Password reset flow
        verify_email_controller.dart        # Email verification flow
      pages/
        login/                              # Login screen
        signup/                             # Signup + email verification screens
        password_configuration/             # Forget/reset password screens
        onboarding/                         # Onboarding screens
      widgets/
        auth_header.dart                    # Shared auth header widget
        success_screen.dart                 # Success confirmation screen
        verification_screen.dart            # Email verification screen

  data/
    repositories/authentication/
      authentication_repository.dart        # Implements IAuthenticationRepository
    repositories/user/
      user_repository.dart                  # User profile data (Firebase/API)
      user_mdmpi_repository.dart            # MDMPI-specific user data
    repositories/app_data/
      role_repository.dart                  # Role lookup
      department_repository.dart            # Department lookup
      sign_up_repository.dart               # Signup API operations
```

### Data Flow

```
UI (LoginScreen / SignupScreen)
  → LoginController / SignupController
    → LoginWithEmailPasswordUseCase / LoginWithGoogleUseCase
      → IAuthenticationRepository (interface)
        → AuthenticationRepository (implementation, extends GetxController)
          → Firebase Auth + UserRepository
            → AppRouter (post-auth department routing)
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `AuthUser` | `features/authentication/domain/entities/` | Domain entity for authenticated user |
| `LoginRequest` | `features/authentication/domain/params/` | Login params (email, password) |
| `IAuthenticationRepository` | `features/authentication/domain/repositories/` | Abstract auth repository |
| `LoginWithEmailPasswordUseCase` | `features/authentication/domain/usecases/` | Email/password login use case |
| `LoginWithGoogleUseCase` | `features/authentication/domain/usecases/` | Google Sign-In use case |
| `LoginController` | `features/authentication/presentation/controllers/` | Login screen state |
| `SignupController` | `features/authentication/presentation/controllers/` | Signup screen state |
| `AuthenticationRepository` | `data/repositories/authentication/` | Concrete implementation (Firebase Auth) |
| `UserRepository` | `data/repositories/user/` | User profile operations |

### DI Registration

Registered in `GeneralBindings`:

```dart
// Repository interface
Get.lazyPut<IAuthenticationRepository>(() => AuthenticationRepository(), fenix: true);

// Use cases
Get.lazyPut(() => LoginWithEmailPasswordUseCase(...), fenix: true);
Get.lazyPut(() => LoginWithGoogleUseCase(...), fenix: true);

// Controllers
Get.lazyPut(() => LoginController(), fenix: true);
Get.put(SignupController(), permanent: false);  // Singleton to retain form data
Get.lazyPut(() => LoadingScreenController(), fenix: true);
Get.lazyPut(() => VerifyEmailController(), fenix: true);
Get.lazyPut(() => ForgetPasswordController(), fenix: true);
```

### Routes

| Route | Page |
|---|---|
| `BRoutes.signIn` | `LoginScreen` |
| `BRoutes.signup` | `SignupScreen` |
| `BRoutes.verifyEmail` | `VerifyEmailScreen` |
| `BRoutes.forgetPassword` | `ForgetPassword` |

### Dependencies

- `firebase_auth` — Firebase Authentication
- `google_sign_in` — Google Sign-In
- `get_storage` — Local device storage for onboarding flags
- Exception classes: `BFirebaseAuthException`, `BFirebaseException`, `BFormatException`, `BPlatformException`
- `Result<T>` sealed class for typed error handling

### Notes

- `SignupController` is registered with `Get.put(permanent: false)` (not `lazyPut`) to retain form data during navigation.
- `AuthenticationRepository` is registered early in `main.dart` via `Get.put` for pre-app-start initialization, and also via `GeneralBindings` using the interface.
- Post-auth routing is handled by `AppRouter` which checks `GetStorage` for department and onboarding status.
