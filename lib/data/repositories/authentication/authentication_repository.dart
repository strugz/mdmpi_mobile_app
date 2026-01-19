import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/firebase_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/format_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/platform_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/entities/auth_user.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/repositories/i_authentication_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/login/login.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/signup/verify_email.dart';
import 'package:mdmpi_mobile_app/app_router.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

class AuthenticationRepository extends GetxController implements IAuthenticationRepository {
  static AuthenticationRepository get instance => Get.find();

  ///  Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  /// Get Authenticated User Data
  User? get authUser => _auth.currentUser;

  ///  Called from main.dart on app launch
  @override
  void onReady() {
    // Remove the native splash screen
    FlutterNativeSplash.remove();
    // Redirect to the appropriate screen
    screenRedirect();
    super.onReady();
  }

  /// Function to Show Relevant Screen
  ///
  /// Redirects user based on authentication status:
  /// - Not authenticated → LoginScreen
  /// - Authenticated but email not verified → VerifyEmailScreen
  /// - Authenticated and verified → AppRouter (which handles onboarding)
  void screenRedirect() async {
    final user = _auth.currentUser;

    if (user != null) {
      // If the user is logged in
      if (user.emailVerified) {
        // Redirect to AppRouter - it will handle onboarding check and routing
        Get.offAll(() => const AppRouter());
      } else {
        // If the user's email is not verified, navigate to the VerifyEmailScreen
        Get.offAll(() => VerifyEmailScreen(email: _auth.currentUser?.email));
      }
    } else {
      // Not authenticated - go to login
      Get.offAll(() => const LoginScreen());
    }
  }

  /*-------------------------------- Email & Password sign-in ---------------------------------------*/
  /// [EmailAuthentication] - LOGIN
  Future<UserCredential> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [EmailAuthentication] - LOGIN (implements interface)
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
        return Result.failure('Authentication failed. Please try again.');
      }

      final authUser = AuthUser.fromFirebaseUser(userCredential.user!);
      return Result.success(authUser);

    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthError(e.code));
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

  /// [EmailAuthentication] - REGISTER
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [EmailAuthentication] - REGISTER
  @override
  Future<Result<AuthUser>> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return Result.failure('Registration failed. Please try again.');
      }

      final authUser = AuthUser.fromFirebaseUser(userCredential.user!);
      return Result.success(authUser);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthError(e.code));
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

  /// [EmailVerification] - MAIL VERIFICATION (Updated - implements interface)
  @override
  Future<Result<void>> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return Result.success(null);
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

  /// [EmailAuthentication] - Forget Password (Updated - implements interface)
  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return Result.success(null);
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

  /// [ReAuthentication] - Re Authenticate User
  Future<void> reAuthenticateWithEmailAndPassword(
      String email, String password) async {
    try {
      //  Create a credential
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);

      //ReAuthenticate
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [ReAuthentication] - Re Authenticate User (Updated - implements interface)
  @override
  Future<Result<void>> reAuthenticate({
    required String email,
    required String password,
  }) async {
    try {
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);
      await _auth.currentUser!.reauthenticateWithCredential(credential);
      return Result.success(null);
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

  /// [GoogleAuthentication] - GOOGLE (New - implements interface)
  @override
  Future<Result<AuthUser>> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? userAccount = await GoogleSignIn().signIn();

      if (userAccount == null) {
        return Result.failure('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication? googleAuth =
          await userAccount.authentication;

      final credentials = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credentials);

      if (userCredential.user == null) {
        return Result.failure('Google sign-in failed');
      }

      final authUser = AuthUser.fromFirebaseUser(userCredential.user!);
      return Result.success(authUser);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthError(e.code));
    } on FirebaseException catch (e) {
      return Result.failure(TFirebaseException(e.code).message);
    } on FormatException catch (_) {
      return Result.failure(const TFormatException().message);
    } on PlatformException catch (e) {
      return Result.failure(TPlatformException(e.code).message);
    } catch (e) {
      if (kDebugMode) logDebug('Google sign-in error: $e');
      return Result.failure('Google sign-in failed: ${e.toString()}');
    }
  }

  /// [FacebookAuthentication] - FACEBOOK
/*-------------------------------- ./end Federated identity & social sign-in ---------------------------------------*/

  /// [LogoutUser] - Valid for any authentication (Updated - implements interface)
  @override
  Future<Result<void>> logout() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const LoginScreen());
      return Result.success(null);
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

  /// DELETE USER - Remove user Auth and Firestore account (Updated - implements interface)
  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await UserRepository.instance.removeUserRecord(_auth.currentUser!.uid);
      await _auth.currentUser!.delete();
      return Result.success(null);
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

  /// Get currently logged-in user (New - implements interface)
  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        return Result.success(null);
      }

      final authUser = AuthUser.fromFirebaseUser(firebaseUser);
      return Result.success(authUser);
    } catch (e) {
      return Result.failure('Failed to get current user: ${e.toString()}');
    }
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  /// Maps Firebase Auth error codes to user-friendly messages
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
      case 'email-already-in-use':
        return 'This email address is already in use';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email';
      default:
        return TFirebaseAuthException(code).message;
    }
  }
}

