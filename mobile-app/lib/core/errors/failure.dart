/// Sealed hierarchy of domain-level failures.
///
/// Repositories catch infrastructure exceptions and return typed [Failure]
/// instances via [Result]. Presentation-layer code pattern-matches on subtypes
/// to display appropriate error messages.
sealed class Failure {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.stackTrace]);

  @override
  String toString() => '$runtimeType: $message';
}

/// A remote server (Supabase / HTTP) returned an error.
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, [super.stackTrace, this.statusCode]);
}

/// Local cache read/write failed.
class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.stackTrace]);
}

/// Authentication or session error.
class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.stackTrace]);
}

/// Device is offline or the request timed out.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.stackTrace]);
}
