import 'package:tander_flutter_v3/core/errors/app_exception.dart';

sealed class Result<TValue> {
  const Result();

  bool get isSuccess => this is Success<TValue>;
  bool get isFailure => this is Failure<TValue>;

  TValue? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  AppException? get exceptionOrNull => switch (this) {
        Success() => null,
        Failure(:final exception) => exception,
      };

  TOutput when<TOutput>({
    required TOutput Function(TValue value) success,
    required TOutput Function(AppException exception) failure,
  }) =>
      switch (this) {
        Success(:final value) => success(value),
        Failure(:final exception) => failure(exception),
      };

  Result<TOutput> map<TOutput>(TOutput Function(TValue value) transform) =>
      switch (this) {
        Success(:final value) => Success<TOutput>(transform(value)),
        Failure(:final exception) => Failure<TOutput>(exception),
      };
}

final class Success<TValue> extends Result<TValue> {
  const Success(this.value);

  final TValue value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<TValue> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

final class Failure<TValue> extends Result<TValue> {
  const Failure(this.exception);

  final AppException exception;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<TValue> && other.exception == exception;

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure($exception)';
}
