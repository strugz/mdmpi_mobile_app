# Use Cases Layer - Quick Visual Guide

**Date:** January 16, 2026  
**Target Audience:** Developers new to Use Cases pattern

---

## 🎯 What is a Use Case?

> **A Use Case is ONE specific business operation that encapsulates ALL the logic needed to accomplish that operation.**

Think of it as a **recipe** 📖:
- **Input**: Ingredients (email, password)
- **Process**: Steps (validate, check network, authenticate)
- **Output**: Result (success with user data, or failure with error)

---

## 🔄 The Problem: Controller Does Everything

### Current Login Flow (Without Use Cases)

```
┌─────────────────────────────────────────────────────┐
│           LoginController                           │
│  (Too many responsibilities!)                       │
│                                                     │
│  • Manages UI state (text fields, loading)          │
│  • Validates form fields ← Business Logic           │
│  • Checks network connectivity ← Business Logic     │
│  • Calls repository ← Data Access                   │
│  • Handles "remember me" ← Business Logic           │
│  • Shows loaders/snackbars ← UI Logic               │
│  • Navigates to next screen ← UI Logic              │
│                                                     │
│  Result: 🔴 Hard to test, hard to reuse            │
└─────────────────────────────────────────────────────┘
```

**Problems:**
- 🔴 **Testing nightmare**: Need to mock GetX, UI components, repositories
- 🔴 **Can't reuse**: Logic is tied to this controller
- 🔴 **Hard to maintain**: Change one thing, risk breaking everything
- 🔴 **Unclear contract**: What input does it need? What output does it give?

---

## ✅ The Solution: Use Cases Layer

### Login Flow with Use Cases

```
┌─────────────────────────────────────────────────────┐
│           LoginController                           │
│  (UI concerns only)                                 │
│                                                     │
│  • Manages UI state (text fields, loading) ✅       │
│  • Shows loaders/snackbars ✅                       │
│  • Navigates to next screen ✅                      │
│  • Delegates business logic to Use Case ✅          │
│                                                     │
│  Result: 🟢 Simple, focused, easy to test          │
└───────────────────┬─────────────────────────────────┘
                    │
                    │ execute(request)
                    ▼
┌─────────────────────────────────────────────────────┐
│    LoginWithEmailPasswordUseCase                    │
│  (Business logic only)                              │
│                                                     │
│  • Validates input (email format, password) ✅      │
│  • Checks network connectivity ✅                   │
│  • Calls repository (via interface) ✅              │
│  • Handles "remember me" logic ✅                   │
│  • Returns Result<AuthUser> ✅                      │
│                                                     │
│  Result: 🟢 Easy to test, reusable, clear contract │
└───────────────────┬─────────────────────────────────┘
                    │
                    │ depends on interface
                    ▼
┌─────────────────────────────────────────────────────┐
│    IAuthenticationRepository (Interface)            │
│  • loginWithEmailPassword(email, password)          │
└───────────────────┬─────────────────────────────────┘
                    │
                    │ implements
                    ▼
┌─────────────────────────────────────────────────────┐
│    AuthenticationRepository                         │
│  • Talks to Firebase Auth                           │
│  • Maps Firebase User → AuthUser Entity             │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Code Comparison

### ❌ Before: Controller Does Everything

```dart
class LoginController extends GetxController {
  Future<void> emailAndPasswordSignIn() async {
    // ❌ Validation
    if (!loginFormKey.currentState!.validate()) {
      BLoaders.errorSnackBar(...);
      return;
    }

    // ❌ Network check
    if (!await NetworkManager.instance.isConnected()) {
      BLoaders.errorSnackBar(...);
      return;
    }

    try {
      // ❌ Show loader (UI)
      BFullScreenLoader.openLoadingDialog(...);

      // ❌ Remember me logic (Business)
      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text);
        localStorage.write('REMEMBER_ME_PASSWORD', password.text);
      }

      // ❌ Direct repository call (Data)
      await AuthenticationRepository.instance
          .loginWithEmailAndPassword(email.text, password.text);

      // ❌ Hide loader (UI)
      BFullScreenLoader.stopLoading();

      // ❌ Navigate (UI)
      await loadingController.loadInitialData();
      
    } catch (e) {
      // ❌ Error handling
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }
}
```

**Line count: ~30 lines**  
**Responsibilities: 7 (UI, validation, network, business logic, data, navigation, error handling)**

---

### ✅ After: Use Case Handles Business Logic

#### 1. Use Case (Business Logic)

```dart
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
  
  Future<Result<AuthUser>> execute(LoginRequest request) async {
    // ✅ Input validation (clear contract)
    if (!request.isValid()) {
      return Result.failure('Invalid email or password');
    }
    
    // ✅ Network check
    if (!await _networkManager.isConnected()) {
      return Result.failure('No internet connection');
    }
    
    // ✅ Authenticate
    final authResult = await _authRepository.loginWithEmailPassword(
      email: request.email,
      password: request.password,
    );
    
    if (authResult.isFailure) {
      return authResult; // Propagate error
    }
    
    // ✅ Remember me logic
    if (request.rememberMe) {
      _localStorage.write('REMEMBER_ME_EMAIL', request.email);
      _localStorage.write('REMEMBER_ME_PASSWORD', request.password);
    }
    
    return authResult;
  }
}

// Clear input contract
class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;
  
  LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
  
  bool isValid() => email.contains('@') && password.length >= 6;
}
```

#### 2. Controller (UI Only)

```dart
class LoginController extends GetxController {
  late final LoginWithEmailPasswordUseCase _loginUseCase;
  
  final email = TextEditingController();
  final password = TextEditingController();
  final rememberMe = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loginUseCase = Get.find<LoginWithEmailPasswordUseCase>();
  }
  
  Future<void> emailAndPasswordSignIn() async {
    // ✅ UI-level form validation
    if (!loginFormKey.currentState!.validate()) {
      BLoaders.errorSnackBar(title: 'Error', message: 'Fill all fields');
      return;
    }

    // ✅ Show loader (UI concern)
    BFullScreenLoader.openLoadingDialog('Logging in...', BImages.docerAnimation);

    // ✅ Build request
    final request = LoginRequest(
      email: email.text,
      password: password.text,
      rememberMe: rememberMe.value,
    );
    
    // ✅ Execute use case (business logic)
    final result = await _loginUseCase.execute(request);
    
    // ✅ Hide loader (UI concern)
    BFullScreenLoader.stopLoading();
    
    // ✅ Handle result (UI concern)
    if (result.isSuccess) {
      BLoaders.successSnackBar(title: 'Welcome!', message: 'Logged in');
      await _loadingController.loadInitialData();
    } else {
      BLoaders.errorSnackBar(title: 'Error', message: result.error);
    }
  }
}
```

**Controller line count: ~20 lines** (33% reduction!)  
**Controller responsibilities: 3 (UI state, loaders/snackbars, navigation)**  
**Use case line count: ~30 lines**  
**Use case responsibilities: 1 (login business logic)**

---

## 🧪 Testing: Before vs After

### ❌ Before: Hard to Test

```dart
// ❌ Need to setup GetX, mock UI components, mock repositories
test('should login successfully', () async {
  // Setup nightmare
  Get.put(LoginController());
  Get.put(NetworkManager());
  Get.put(AuthenticationRepository.instance);
  // ... mock UI, forms, etc.
  
  final controller = Get.find<LoginController>();
  controller.email.text = 'test@test.com';
  controller.password.text = 'password123';
  
  await controller.emailAndPasswordSignIn();
  
  // How do you assert success?
  // Controller shows snackbar, navigates - hard to verify
});
```

**Problems:**
- 🔴 Complex setup (GetX, UI, mocks)
- 🔴 Hard to verify (snackbars, navigation)
- 🔴 Slow (needs full framework)

---

### ✅ After: Easy to Test

```dart
// ✅ Just mock repository, test pure logic
test('should login successfully with valid credentials', () async {
  // Arrange (simple!)
  final mockAuthRepo = MockIAuthenticationRepository();
  final mockNetworkManager = MockNetworkManager();
  final mockStorage = MockGetStorage();
  
  final useCase = LoginWithEmailPasswordUseCase(
    authRepository: mockAuthRepo,
    networkManager: mockNetworkManager,
    localStorage: mockStorage,
  );
  
  when(mockNetworkManager.isConnected()).thenAnswer((_) async => true);
  when(mockAuthRepo.loginWithEmailPassword(
    email: 'test@test.com',
    password: 'password123',
  )).thenAnswer((_) async => Result.success(mockAuthUser));
  
  // Act
  final result = await useCase.execute(LoginRequest(
    email: 'test@test.com',
    password: 'password123',
    rememberMe: true,
  ));
  
  // Assert (clear!)
  expect(result.isSuccess, true);
  expect(result.value.email, 'test@test.com');
  verify(mockStorage.write('REMEMBER_ME_EMAIL', 'test@test.com')).called(1);
});

test('should return failure when no internet', () async {
  // Arrange
  when(mockNetworkManager.isConnected()).thenAnswer((_) async => false);
  
  // Act
  final result = await useCase.execute(validRequest);
  
  // Assert
  expect(result.isFailure, true);
  expect(result.error, 'No internet connection');
  verifyNever(mockAuthRepo.loginWithEmailPassword(any, any));
});

test('should return failure with invalid email', () async {
  // Act
  final result = await useCase.execute(LoginRequest(
    email: 'invalid-email',  // No @
    password: 'password123',
  ));
  
  // Assert
  expect(result.isFailure, true);
});
```

**Benefits:**
- ✅ Simple setup (just mock dependencies)
- ✅ Clear assertions (Result<T> is explicit)
- ✅ Fast (no UI, no framework)
- ✅ Comprehensive (easy to test all edge cases)

---

## 🎨 Visual Mental Model

### Think of Use Cases as Lego Blocks 🧱

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Application                         │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ Login UseCase │  │ SignUp        │  │ ForgotPassword│
│               │  │ UseCase       │  │ UseCase       │
│ 🧱            │  │ 🧱            │  │ 🧱            │
└───────────────┘  └───────────────┘  └───────────────┘

Each block is:
✅ Independent (can test in isolation)
✅ Reusable (can use in multiple places)
✅ Composable (can combine blocks)
✅ Clear contract (input → process → output)
```

---

## 📊 Benefits Summary

| Benefit | Controller + Use Case | Controller Only |
|---------|----------------------|-----------------|
| **Testability** | 🟢🟢🟢 Easy (mock interfaces) | 🔴 Hard (mock framework) |
| **Reusability** | 🟢🟢🟢 High (use anywhere) | 🔴 Low (tied to controller) |
| **Clarity** | 🟢🟢🟢 Clear contract | 🟡 Implicit |
| **Maintainability** | 🟢🟢🟢 Single responsibility | 🔴 God object |
| **Error Handling** | 🟢🟢 Explicit (Result<T>) | 🟡 Implicit (exceptions) |

---

## 🚀 Quick Start: 3 Steps to Add Use Cases

### Step 1: Create the Use Case

```dart
// lib/features/authentication/domain/usecases/login_with_email_password_usecase.dart
class LoginWithEmailPasswordUseCase {
  final IAuthenticationRepository _authRepository;
  
  LoginWithEmailPasswordUseCase({
    required IAuthenticationRepository authRepository,
  }) : _authRepository = authRepository;
  
  Future<Result<AuthUser>> execute(LoginRequest request) async {
    // Your business logic here
  }
}
```

### Step 2: Register in DI

```dart
// lib/bindings/general_bindings.dart
class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    // Register use case
    Get.lazyPut(
      () => LoginWithEmailPasswordUseCase(
        authRepository: Get.find<IAuthenticationRepository>(),
      ),
      fenix: true,
    );
  }
}
```

### Step 3: Use in Controller

```dart
// lib/features/authentication/controllers/login/login_controller.dart
class LoginController extends GetxController {
  late final LoginWithEmailPasswordUseCase _loginUseCase;
  
  @override
  void onInit() {
    super.onInit();
    _loginUseCase = Get.find<LoginWithEmailPasswordUseCase>();
  }
  
  Future<void> login() async {
    final result = await _loginUseCase.execute(request);
    
    if (result.isSuccess) {
      // Handle success
    } else {
      // Handle failure
    }
  }
}
```

---

## 🎓 Real-World Analogy

### Without Use Cases: You're the Chef AND the Waiter AND the Cashier

```
Customer: "I'd like a burger"

You (Controller):
1. Take order ✅
2. Check ingredients ✅
3. Cook burger ✅
4. Serve burger ✅
5. Take payment ✅
6. Clean dishes ✅

Problem: You're doing EVERYTHING!
```

### With Use Cases: Division of Labor

```
Customer: "I'd like a burger"

Waiter (Controller):
1. Take order ✅
2. Send to kitchen →

Chef (Use Case):
3. Check ingredients ✅
4. Cook burger ✅
5. Return to waiter →

Waiter (Controller):
6. Serve burger ✅

Result: Each person has ONE job!
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ Don't: Make Use Cases Too Small

```dart
// ❌ TOO SMALL (just a wrapper)
class ValidateEmailUseCase {
  bool execute(String email) => email.contains('@');
}

// ✅ GOOD (meaningful operation)
class LoginWithEmailPasswordUseCase {
  Future<Result<AuthUser>> execute(LoginRequest request) async {
    // Validate, check network, authenticate, handle remember me
  }
}
```

### ❌ Don't: Put UI Logic in Use Cases

```dart
// ❌ BAD (use case shows UI)
class LoginUseCase {
  Future<void> execute() {
    BLoaders.successSnackBar(...); // ❌ NO UI IN USE CASES!
    Get.to(HomeScreen()); // ❌ NO NAVIGATION IN USE CASES!
  }
}

// ✅ GOOD (use case returns result, controller handles UI)
class LoginUseCase {
  Future<Result<AuthUser>> execute(LoginRequest request) {
    // Just return result
    return Result.success(user);
  }
}
```

### ❌ Don't: Use Use Cases for Everything

```dart
// ❌ OVERKILL (simple getter doesn't need use case)
class GetCurrentUserUseCase {
  Future<AuthUser?> execute() => _repo.getCurrentUser();
}

// ✅ GOOD (just call repository directly for simple queries)
class LoginController {
  Future<void> checkAuth() async {
    final user = await _authRepository.getCurrentUser();
    // ...
  }
}
```

---

## 📚 Further Reading

- [Full Login Example](./USE_CASE_LOGIN_EXAMPLE.md) - Complete code with all layers
- [Migration Examples](./CLEAN_ARCHITECTURE_MIGRATION_EXAMPLES.md) - More use case examples
- [Clean Architecture Analysis](./CLEAN_ARCHITECTURE_ANALYSIS.md) - Full analysis

---

## 🎯 Key Takeaways

1. **Use Cases = Business Operations** (one class per operation)
2. **Controller = UI Orchestrator** (delegates to use cases)
3. **Easy to Test** (mock interfaces, not framework)
4. **Clear Contracts** (explicit input/output)
5. **Single Responsibility** (each class does ONE thing)

**Start small. Try one use case. See if it makes your code better. Then decide.**

---

**Last Updated:** January 16, 2026
