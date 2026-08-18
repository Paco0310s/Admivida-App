class EitherUtil<Failure, Success> {
  final Failure? _failure;
  final Success? _success;
  final bool isFailure;

  EitherUtil._(this._failure, this._success, this.isFailure);

  factory EitherUtil.failure(Failure failure) {
    return EitherUtil._(failure, null, true);
  }

  factory EitherUtil.success(Success value) {
    return EitherUtil._(null, value, false);
  }

  T when<T>(T Function(Failure) failure, T Function(Success) success) {
    if (isFailure) {
      return failure(_failure as Failure);
    } else {
      return success(_success as Success);
    }
  }
}
