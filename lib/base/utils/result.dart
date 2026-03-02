/// A type that represents either a success or a failure.
///
/// Use this instead of throwing exceptions for expected error cases.
/// Inspired by Rust's Result<T, E> and Kotlin's Result<T>.
///
/// Example:
/// ```dart
/// Future<Result<User>> loginUser(String email, String password) async {
///   if (email.isEmpty) {
///     return Result.failure('Email is required');
///   }
///
///   try {
///     final user = await authService.login(email, password);
///     return Result.success(user);
///   } catch (e) {
///     return Result.failure('Login failed: ${e.toString()}');
///   }
/// }
///
/// // Usage
/// final result = await loginUser('test@test.com', 'password');
/// if (result.isSuccess) {
///   print('Logged in: ${result.value}');
/// } else {
///   print('Error: ${result.error}');
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful result with the given value.
  factory Result.success(T value) = Success<T>;

  /// Creates a failed result with the given error message.
  factory Result.failure(String error) = Failure<T>;

  /// Returns true if this is a successful result.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failed result.
  bool get isFailure => this is Failure<T>;

  /// Returns the value if successful, otherwise throws.
  T get value {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    throw StateError('Cannot get value from a Failure. Check isSuccess before accessing value.');
  }

  /// Returns the error message if failed, otherwise throws.
  String get error {
    if (this is Failure<T>) {
      return (this as Failure<T>).error;
    }
    throw StateError('Cannot get error from a Success. Check isFailure before accessing error.');
  }

  /// Transforms the value if successful, otherwise returns the failure.
  Result<U> map<U>(U Function(T value) transform) {
    if (this is Success<T>) {
      return Result.success(transform((this as Success<T>).value));
    }
    return Result.failure((this as Failure<T>).error);
  }

  /// Chains another operation if successful, otherwise returns the failure.
  Result<U> flatMap<U>(Result<U> Function(T value) transform) {
    if (this is Success<T>) {
      return transform((this as Success<T>).value);
    }
    return Result.failure((this as Failure<T>).error);
  }

  /// Executes one of two callbacks depending on success or failure.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(String error) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    }
    return onFailure((this as Failure<T>).error);
  }

  /// Returns the value if successful, otherwise returns the provided default value.
  T getOrDefault(T defaultValue) {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    return defaultValue;
  }

  /// Returns the value if successful, otherwise returns null.
  T? getOrNull() {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    return null;
  }
}

/// Successful result containing a value.
class Success<T> extends Result<T> {
  @override
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Failed result containing an error message.
class Failure<T> extends Result<T> {
  @override
  final String error;
  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}
