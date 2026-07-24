sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication error.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Requested resource was not found.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}

class Result<T> {
  final T? data;
  final Failure? failure;

  const Result._({this.data, this.failure});

  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(Failure failure) => Result._(failure: failure);

  bool get isSuccess => failure == null;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) {
    if (isSuccess) {
      return success(data as T);
    }
    return error(failure!);
  }
}
