import 'exceptions.dart';

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);

  factory ServerFailure.fromException(ServerException exception) {
    return ServerFailure(exception.message);
  }
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);

  factory NetworkFailure.fromException(NetworkException exception) {
    return NetworkFailure(exception.message);
  }
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);

  factory CacheFailure.fromException(CacheException exception) {
    return CacheFailure(exception.message);
  }
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);

  factory ValidationFailure.fromException(ValidationException exception) {
    return ValidationFailure(exception.message);
  }
}
