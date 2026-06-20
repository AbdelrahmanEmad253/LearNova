import 'package:learnova/core/errors/failure.dart';

/// Lightweight Result type that avoids external dependencies (dartz / fpdart).
///
/// Usage:
/// ```dart
/// final result = await repository.fetchData();
/// result.when(
///   success: (data) => state = AsyncData(data),
///   failure: (f) => state = AsyncError(f, StackTrace.current),
/// );
/// ```
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = Err<T>;

  /// Exhaustive pattern-match on success / failure.
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  });

  /// Returns the data if [Success], otherwise `null`.
  T? get dataOrNull;

  /// Returns the [Failure] if [Err], otherwise `null`.
  Failure? get failureOrNull;

  /// Returns `true` when this is a [Success].
  bool get isSuccess;
}

/// Successful result containing [data].
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) =>
      success(data);

  @override
  T get dataOrNull => data;

  @override
  Failure? get failureOrNull => null;

  @override
  bool get isSuccess => true;
}

/// Failed result containing a typed [Failure].
class Err<T> extends Result<T> {
  final Failure error;
  const Err(this.error);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) =>
      failure(error);

  @override
  T? get dataOrNull => null;

  @override
  Failure? get failureOrNull => error;

  @override
  bool get isSuccess => false;
}
