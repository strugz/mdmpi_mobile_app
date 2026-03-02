import 'package:firebase_auth/firebase_auth.dart';

/// Pure domain entity representing an authenticated user.
///
/// This entity contains NO framework dependencies (except Firebase User for mapping).
/// Contains only business logic and domain concepts.
///
/// Use this entity in:
/// - Use cases
/// - Controllers
/// - Business logic
///
/// Do NOT use for:
/// - Firestore persistence (use UserModel instead)
/// - JSON serialization (use UserModel/DTO instead)
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

  /// Checks if this is an empty/guest user.
  bool isEmpty() {
    return id.isEmpty;
  }

  // ========================================================================
  // FACTORY CONSTRUCTORS
  // ========================================================================

  /// Creates an empty user (for initialization or logout).
  static AuthUser empty() => AuthUser(
    id: '',
    email: '',
    isEmailVerified: false,
    createdAt: DateTime.now(),
  );

  /// Converts Firebase User to domain entity.
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

  // ========================================================================
  // COPY & EQUALITY
  // ========================================================================

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AuthUser(id: $id, email: $email, displayName: $displayName, isEmailVerified: $isEmailVerified)';
  }
}
