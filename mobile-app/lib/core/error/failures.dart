import 'package:supabase_flutter/supabase_flutter.dart';

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class SupabaseFailureHandler {
  static Failure handle(Object error) {
    if (error is AuthException) {
      return AuthFailure(error.message);
    } else if (error is PostgrestException) {
      return ServerFailure(error.message);
    } else if (error is StorageException) {
      return ServerFailure(error.message);
    } else {
      return ServerFailure(error.toString());
    }
  }
}
