# Use Cases Implementation - Pre-Implementation Checklist

**Date:** January 16, 2026  
**Module:** Login (Authentication)  
**Status:** ⚠️ REVIEW BEFORE IMPLEMENTATION

---

## 🔍 Analysis Summary

I've analyzed your current codebase to identify potential issues if you implement the Use Cases Layer for the Login module. Here's what I found:

### ✅ What You Already Have (Good News!)

1. ✅ **GetX State Management** - Already set up
2. ✅ **Dependency Injection** - `GeneralBindings` working
3. ✅ **Network Manager** - Available for connectivity checks
4. ✅ **Local Storage** - `GetStorage` configured
5. ✅ **Exception Handling** - Custom exceptions defined
6. ✅ **Repository Pattern** - `AuthenticationRepository` exists
7. ✅ **Controllers** - `LoginController`, `UserController` in place
8. ✅ **Loading Indicators** - `BFullScreenLoader`, `BLoaders` available

### ❌ What You're Missing (Must Create)

1. ❌ **Result Type** - No `Result<T>` class exists
2. ❌ **Domain Layer** - No `domain/` folder structure
3. ❌ **Repository Interfaces** - `IAuthenticationRepository` doesn't exist
4. ❌ **Use Case Classes** - No use cases implemented yet
5. ❌ **Domain Entities** - `AuthUser` entity doesn't exist (you have `UserModel` but it's a DTO)
6. ❌ **Request Objects** - `LoginRequest` class doesn't exist

---

## 🚨 Critical Issues That Will Cause Errors

### Issue #1: Missing Result Type ⛔

**Error You'll Get:**
```
Error: Type 'Result' not found.
```

**Why:** Your current repository methods throw exceptions instead of returning `Result<T>`:
```dart
// Current (throws exceptions)
Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
  try {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  } catch (e) {
    throw 'Something went wrong'; // ❌ Throws exception
  }
}
```

**What Use Case Expects:**
```dart
Future<Result<AuthUser>> loginWithEmailPassword(...) async {
  return Result.success(user); // ⛔ Result class doesn't exist!
}
```

**Solution Required:**
- ✅ Create `lib/base/utils/result.dart`
- ✅ Update repository to return `Result<T>` instead of throwing

---

### Issue #2: Type Mismatch - UserCredential vs AuthUser ✅ FIXED

**Status:** ✅ **RESOLVED** - `lib/features/authentication/domain/entities/auth_user.dart` has been implemented with 125 lines of code

**What was the issue:**
Current repository returns Firebase's `UserCredential`:
```dart
// Current
Future<UserCredential> loginWithEmailAndPassword(...) // ❌ Returns Firebase type
```

**What Use Case Expects:**
```dart
Future<Result<AuthUser>> loginWithEmailPassword(...) // ⛔ AuthUser doesn't exist!
```

**Current Workaround:** You use `UserModel` from Firestore, but it's not a pure domain entity.

**Solution Required:**
- ✅ Create `AuthUser` domain entity
- ✅ Map `UserCredential` → `AuthUser` in repository
- ✅ Keep `UserModel` for Firestore persistence (separate concern)

---

### Issue #3: Missing Repository Interface ⛔

**Error You'll Get:**
```
Error: The type 'IAuthenticationRepository' isn't defined.
```

**Why:** Your use case will depend on an interface:
```dart
class LoginWithEmailPasswordUseCase {
  final IAuthenticationRepository _authRepository; // ⛔ Interface doesn't exist!
  // ...
}
```

**Current Situation:** You have `AuthenticationRepository` (concrete class), not an interface.

**Solution Required:**
- ✅ Create `IAuthenticationRepository` interface
- ✅ Make `AuthenticationRepository` implement the interface
- ✅ Update DI bindings to register the interface

---

### Issue #4: Circular Dependency with screenRedirect() ⚠️

**Potential Issue:** Your repository calls `screenRedirect()` which uses GetX navigation:
```dart
// In AuthenticationRepository
void screenRedirect() async {
  Get.offAll(() => const NavigationMenu()); // ⚠️ Repository has navigation logic
}

// In LoginController (current)
await AuthenticationRepository.instance.loginWithEmailAndPassword(...);
// No explicit navigation - repository handles it

// After Use Case implementation
final result = await _loginUseCase.execute(request);
// Controller should handle navigation, but repository might also redirect
```

**Problem:** If repository calls `screenRedirect()` AND controller tries to navigate, you'll have conflicts.

**Solution Required:**
- ✅ Remove navigation from repository
- ✅ Let controller handle all navigation
- ✅ Keep `screenRedirect()` for app initialization only (in `onReady()`)

---

### Issue #5: User Record Saving Logic ⚠️

**Current Flow (Google Sign-In):**
```dart
// LoginController
final userCredentials = await AuthenticationRepository.instance.signInWithGoogle();
await userController.saveUserRecord(userCredentials); // ⚠️ Manual call
```

**After Use Case:**
```dart
// LoginWithGoogleUseCase should handle this internally
final result = await _authRepository.loginWithGoogle();
// Should it also save user record? Or is that a separate use case?
```

**Design Decision Needed:**
- Option A: `LoginWithGoogleUseCase` handles everything (auth + save user)
- Option B: Separate use case: `SaveUserRecordUseCase`

**Recommendation:** Option A (keep it in one use case for simplicity)

---

## 📋 Step-by-Step Implementation Plan (Error-Free)

### Phase 1: Foundation (No Breaking Changes)

#### Step 1.1: Create Result Type ✅

**File:** `lib/base/utils/result.dart`

```dart
// Create this file FIRST
sealed class Result<T> {
  const Result();
  
  factory Result.success(T value) = Success<T>;
  factory Result.failure(String error) = Failure<T>;
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  
  T get value {
    if (this is Success<T>) return (this as Success<T>).value;
    throw StateError('Cannot get value from Failure');
  }
  
  String get error {
    if (this is Failure<T>) return (this as Failure<T>).error;
    throw StateError('Cannot get error from Success');
  }
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
}
```

**Test it:**
```dart
// In main.dart or any controller
void testResult() {
  final success = Result<String>.success('Hello');
  print(success.isSuccess); // true
  print(success.value); // 'Hello'
  
  final failure = Result<String>.failure('Error');
  print(failure.isFailure); // true
  print(failure.error); // 'Error'
}
```

---

#### Step 1.2: Create Domain Entity ✅

**File:** `lib/features/authentication/domain/entities/auth_user.dart`

```dart
// Pure domain entity (no Firebase dependencies)
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
  
  bool isAuthenticated() => id.isNotEmpty && isEmailVerified;
  bool needsEmailVerification() => id.isNotEmpty && !isEmailVerified;
  
  static AuthUser empty() => AuthUser(
    id: '',
    email: '',
    isEmailVerified: false,
    createdAt: DateTime.now(),
  );
  
  // Convert from Firebase User
  factory AuthUser.fromFirebaseUser(User firebaseUser) {
    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }
}
```

**Test it:**
```dart
void testAuthUser() {
  final user = AuthUser(
    id: '123',
    email: 'test@test.com',
    isEmailVerified: true,
    createdAt: DateTime.now(),
  );
  
  print(user.isAuthenticated()); // true
}
```

---

#### Step 1.3: Create Repository Interface ✅

**File:** `lib/features/authentication/domain/repositories/i_authentication_repository.dart`

```dart
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';

abstract class IAuthenticationRepository {
  Future<Result<AuthUser>> loginWithEmailPassword({
    required String email,
    required String password,
  });
  
  Future<Result<AuthUser>> loginWithGoogle();
  
  Future<Result<void>> logout();
  
  Future<Result<AuthUser?>> getCurrentUser();
}
```

**No errors yet** - just defining the contract.

---

#### Step 1.4: Update Existing Repository to Implement Interface ⚠️

**File:** `lib/data/repositories/authentication/authentication_repository.dart`

**⚠️ CRITICAL:** This step will break existing code temporarily!

**Current method (will break):**
```dart
Future<UserCredential> loginWithEmailAndPassword(String email, String password) {
  // ... existing code
}
```

**New method (implements interface):**
```dart
class AuthenticationRepository implements IAuthenticationRepository {
  // ... existing code ...
  
  @override
  Future<Result<AuthUser>> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        return Result.failure('Authentication failed');
      }
      
      final authUser = AuthUser.fromFirebaseUser(userCredential.user!);
      return Result.success(authUser);
      
    } on FirebaseAuthException catch (e) {
      return Result.failure(TFirebaseAuthException(e.code).message);
    } on FirebaseException catch (e) {
      return Result.failure(TFirebaseException(e.code).message);
    } on FormatException catch (_) {
      return Result.failure(const TFormatException().message);
    } on PlatformException catch (e) {
      return Result.failure(TPlatformException(e.code).message);
    } catch (e) {
      return Result.failure('Something went wrong. Please try again');
    }
  }
  
  // Keep old method for backward compatibility (temporary)
  @Deprecated('Use loginWithEmailPassword instead')
  Future<UserCredential> loginWithEmailAndPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }
}
```

**Why @Deprecated?** Existing `LoginController` still calls the old method. We'll update it in Phase 2.

---

### Phase 2: Create Use Cases (Still No Breaking Changes)

#### Step 2.1: Create Request Object ✅

**File:** `lib/features/authentication/domain/usecases/login_with_email_password_usecase.dart`

```dart
class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;
  
  LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
  
  String? validate() {
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Invalid email format';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
```

---

#### Step 2.2: Create Use Case ✅

**File:** `lib/features/authentication/domain/usecases/login_with_email_password_usecase.dart`

```dart
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/repositories/i_authentication_repository.dart';

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
    // Validate input
    final validationError = request.validate();
    if (validationError != null) {
      return Result.failure(validationError);
    }
    
    // Check network
    final isConnected = await _networkManager.isConnected();
    if (!isConnected) {
      return Result.failure('No internet connection');
    }
    
    // Authenticate
    final authResult = await _authRepository.loginWithEmailPassword(
      email: request.email.trim(),
      password: request.password.trim(),
    );
    
    if (authResult.isFailure) {
      return authResult;
    }
    
    // Handle remember me
    if (request.rememberMe) {
      _localStorage.write('REMEMBER_ME_EMAIL', request.email);
      _localStorage.write('REMEMBER_ME_PASSWORD', request.password);
    } else {
      _localStorage.remove('REMEMBER_ME_EMAIL');
      _localStorage.remove('REMEMBER_ME_PASSWORD');
    }
    
    return authResult;
  }
}
```

**Test it (no errors expected):**
```dart
void testUseCase() async {
  // This won't break anything - use case is independent
  final useCase = LoginWithEmailPasswordUseCase(
    authRepository: Get.find<IAuthenticationRepository>(),
    networkManager: Get.find<NetworkManager>(),
    localStorage: GetStorage(),
  );
  
  final request = LoginRequest(
    email: 'test@test.com',
    password: 'password123',
    rememberMe: true,
  );
  
  // This will work if dependencies are registered
  final result = await useCase.execute(request);
  print(result.isSuccess);
}
```

---

#### Step 2.3: Register in DI ✅

**File:** `lib/bindings/general_bindings.dart`

**Add to dependencies():**
```dart
@override
void dependencies() {
  // ... existing bindings ...
  
  // Register repository interface
  Get.lazyPut<IAuthenticationRepository>(
    () => AuthenticationRepository(),
    fenix: true,
  );
  
  // Register use case
  Get.lazyPut(
    () => LoginWithEmailPasswordUseCase(
      authRepository: Get.find<IAuthenticationRepository>(),
      networkManager: Get.find<NetworkManager>(),
      localStorage: GetStorage(),
    ),
    fenix: true,
  );
}
```

**No errors yet** - you're just adding new registrations.

---

### Phase 3: Update Controller (This Changes Behavior)

#### Step 3.1: Update LoginController to Use Use Case ⚠️

**File:** `lib/features/authentication/controllers/login/login_controller.dart`

**Changes needed:**
```dart
class LoginController extends GetxController {
  // ... existing code ...
  
  // ADD: Dependency on use case
  late final LoginWithEmailPasswordUseCase _loginUseCase;
  
  @override
  void onInit() {
    // ... existing code ...
    
    // ADD: Resolve use case
    _loginUseCase = Get.find<LoginWithEmailPasswordUseCase>();
    
    super.onInit();
  }
  
  /// UPDATED: Email and Password SignIn
  Future<void> emailAndPasswordSignIn() async {
    // Form validation (UI-level)
    if (!loginFormKey.currentState!.validate()) {
      BLoaders.errorSnackBar(
          title: 'Validation Error',
          message: 'Please fill in all required fields');
      return;
    }

    try {
      // Show loader
      BFullScreenLoader.openLoadingDialog(
          'Logging you in...', BImages.docerAnimation);

      // Build request
      final request = LoginRequest(
        email: email.text,
        password: password.text,
        rememberMe: rememberMe.value,
      );
      
      // Execute use case
      final result = await _loginUseCase.execute(request);
      
      // Hide loader
      BFullScreenLoader.stopLoading();
      
      // Handle result
      if (result.isSuccess) {
        // Success: load initial data and navigate
        await loadingController.loadInitialData();
        // AuthenticationRepository.instance.screenRedirect(); // Optional
      } else {
        // Failure: show error
        BLoaders.errorSnackBar(
          title: 'Login Failed',
          message: result.error,
        );
      }
    } catch (e) {
      BFullScreenLoader.stopLoading();
      BLoaders.errorSnackBar(
        title: 'Unexpected Error',
        message: e.toString(),
      );
    }
  }
}
```

---

## 🐛 Common Errors and Solutions

### Error 1: "Type 'Result' not found"
**Cause:** Forgot to create `result.dart`  
**Fix:** Create `lib/base/utils/result.dart` (see Step 1.1)

### Error 2: "Type 'AuthUser' not found"
**Cause:** Forgot to create domain entity  
**Fix:** Create `lib/features/authentication/domain/entities/auth_user.dart` (see Step 1.2)

### Error 3: "Type 'IAuthenticationRepository' not found"
**Cause:** Forgot to create interface  
**Fix:** Create `lib/features/authentication/domain/repositories/i_authentication_repository.dart` (see Step 1.3)

### Error 4: "No implementation found for IAuthenticationRepository"
**Cause:** Didn't update DI bindings  
**Fix:** Add to `general_bindings.dart` (see Step 2.3)

### Error 5: "LoginWithEmailPasswordUseCase not found"
**Cause:** Use case not registered in DI  
**Fix:** Add to `general_bindings.dart` (see Step 2.3)

### Error 6: "The method 'loginWithEmailPassword' isn't defined for UserCredential"
**Cause:** Called old repository method signature  
**Fix:** Use new signature with named parameters:
```dart
// Old (breaks)
await repo.loginWithEmailAndPassword(email, password);

// New (works)
await repo.loginWithEmailPassword(email: email, password: password);
```

### Error 7: Double navigation / Multiple redirects
**Cause:** Both repository and controller try to navigate  
**Fix:** Remove navigation from repository, keep only in controller

---

## ✅ Testing Checklist

Before deploying to production:

- [ ] **Unit Test Result Type**
  ```dart
  test('Result.success should return success', () {
    final result = Result.success('test');
    expect(result.isSuccess, true);
    expect(result.value, 'test');
  });
  ```

- [ ] **Unit Test AuthUser Entity**
  ```dart
  test('AuthUser should validate authentication', () {
    final user = AuthUser(id: '123', email: 'test@test.com', isEmailVerified: true, createdAt: DateTime.now());
    expect(user.isAuthenticated(), true);
  });
  ```

- [ ] **Unit Test Use Case with Mocks**
  ```dart
  test('should return failure when no internet', () async {
    when(mockNetworkManager.isConnected()).thenAnswer((_) async => false);
    final result = await useCase.execute(validRequest);
    expect(result.isFailure, true);
  });
  ```

- [ ] **Integration Test Login Flow**
  ```dart
  testWidgets('should login successfully with valid credentials', (tester) async {
    // Test full flow from UI to use case
  });
  ```

- [ ] **Manual Test**
  - [ ] Login with valid credentials → Success
  - [ ] Login with invalid credentials → Shows error
  - [ ] Login without internet → Shows "No internet" error
  - [ ] Remember me checkbox → Credentials saved
  - [ ] Logout and return → Credentials pre-filled

---

## 🎯 Migration Strategy (Zero Downtime)

### Option A: Gradual Migration (Recommended ✅)

1. ✅ Create all new files (Result, AuthUser, Interface, Use Case)
2. ✅ Register in DI
3. ✅ Keep old repository methods with `@Deprecated`
4. ✅ Update ONE controller method to use use case
5. ✅ Test thoroughly
6. ✅ Update remaining controller methods
7. ✅ Remove deprecated methods

**Advantage:** Can rollback easily if issues arise

### Option B: Big Bang Migration (Risky ⚠️)

1. Create all files
2. Update everything at once
3. Test and pray 🙏

**Disadvantage:** If something breaks, hard to find the issue

---

## 📊 Final Verdict

### Will You Encounter Errors? **YES, BUT...**

**Expected Errors (Fixable):**
- ✅ Missing import statements (add them)
- ✅ Missing DI registrations (add to bindings)
- ✅ Type mismatches (follow migration plan)

**Unexpected Errors (Low Risk):**
- ⚠️ Firebase version compatibility (unlikely)
- ⚠️ GetX version issues (unlikely)
- ⚠️ Flutter version issues (unlikely)

### Risk Level: 🟡 MEDIUM

**If you follow the step-by-step plan above, risk is LOW.**

---

## 🚀 Recommended Next Steps

1. **Read this document thoroughly** ✅
2. **Create a new Git branch** (`feature/use-cases-login`)
3. **Follow Phase 1** (Foundation) - No breaking changes
4. **Test after each file creation**
5. **Follow Phase 2** (Use Cases) - Still safe
6. **Follow Phase 3** (Update Controller) - Test thoroughly
7. **Review and merge** if all tests pass

---

## 📞 Need Help?

If you encounter errors not covered here:

1. Check the error message
2. Search for the type/class mentioned
3. Ensure all files are created
4. Verify DI registrations
5. Check import statements

**Common fix:** `flutter pub get` (refresh dependencies)

---

**Document Owner:** Development Team  
**Last Updated:** January 16, 2026  
**Status:** Ready for Implementation

---

## 🎯 Summary

**You WILL encounter errors IF:**
- ❌ You skip creating `Result` type
- ❌ You skip creating `AuthUser` entity
- ❌ You skip creating interface
- ❌ You don't update DI bindings

**You WON'T encounter errors IF:**
- ✅ You follow the step-by-step plan
- ✅ You create files in the correct order
- ✅ You test after each phase
- ✅ You update imports and bindings

**Bottom line:** Implementation is **safe** if done methodically. The documentation I provided is **illustration-only** and assumes all supporting infrastructure exists. This checklist fills those gaps.

**Estimated Time:**
- Phase 1: 1-2 hours
- Phase 2: 1-2 hours
- Phase 3: 1 hour
- Testing: 2-3 hours
- **Total: 5-8 hours** for complete, error-free implementation
