// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'liveness_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LivenessState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() initializing,
    required TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )
    ready,
    required TResult Function(String imagePath) success,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? initializing,
    TResult? Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult? Function(String imagePath)? success,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? initializing,
    TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult Function(String imagePath)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Initializing value) initializing,
    required TResult Function(_Ready value) ready,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Initializing value)? initializing,
    TResult? Function(_Ready value)? ready,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Initializing value)? initializing,
    TResult Function(_Ready value)? ready,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LivenessStateCopyWith<$Res> {
  factory $LivenessStateCopyWith(
    LivenessState value,
    $Res Function(LivenessState) then,
  ) = _$LivenessStateCopyWithImpl<$Res, LivenessState>;
}

/// @nodoc
class _$LivenessStateCopyWithImpl<$Res, $Val extends LivenessState>
    implements $LivenessStateCopyWith<$Res> {
  _$LivenessStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
    _$InitialImpl value,
    $Res Function(_$InitialImpl) then,
  ) = __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$LivenessStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'LivenessState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() initializing,
    required TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )
    ready,
    required TResult Function(String imagePath) success,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? initializing,
    TResult? Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult? Function(String imagePath)? success,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? initializing,
    TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult Function(String imagePath)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Initializing value) initializing,
    required TResult Function(_Ready value) ready,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Initializing value)? initializing,
    TResult? Function(_Ready value)? ready,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Initializing value)? initializing,
    TResult Function(_Ready value)? ready,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements LivenessState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$InitializingImplCopyWith<$Res> {
  factory _$$InitializingImplCopyWith(
    _$InitializingImpl value,
    $Res Function(_$InitializingImpl) then,
  ) = __$$InitializingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitializingImplCopyWithImpl<$Res>
    extends _$LivenessStateCopyWithImpl<$Res, _$InitializingImpl>
    implements _$$InitializingImplCopyWith<$Res> {
  __$$InitializingImplCopyWithImpl(
    _$InitializingImpl _value,
    $Res Function(_$InitializingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitializingImpl implements _Initializing {
  const _$InitializingImpl();

  @override
  String toString() {
    return 'LivenessState.initializing()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitializingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() initializing,
    required TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )
    ready,
    required TResult Function(String imagePath) success,
    required TResult Function(String message) error,
  }) {
    return initializing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? initializing,
    TResult? Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult? Function(String imagePath)? success,
    TResult? Function(String message)? error,
  }) {
    return initializing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? initializing,
    TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult Function(String imagePath)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initializing != null) {
      return initializing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Initializing value) initializing,
    required TResult Function(_Ready value) ready,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) {
    return initializing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Initializing value)? initializing,
    TResult? Function(_Ready value)? ready,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return initializing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Initializing value)? initializing,
    TResult Function(_Ready value)? ready,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initializing != null) {
      return initializing(this);
    }
    return orElse();
  }
}

abstract class _Initializing implements LivenessState {
  const factory _Initializing() = _$InitializingImpl;
}

/// @nodoc
abstract class _$$ReadyImplCopyWith<$Res> {
  factory _$$ReadyImplCopyWith(
    _$ReadyImpl value,
    $Res Function(_$ReadyImpl) then,
  ) = __$$ReadyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    CameraController cameraController,
    bool isFaceDetected,
    bool isFaceCentered,
    double stabilityScore,
    bool isCapturing,
    String? instruction,
  });
}

/// @nodoc
class __$$ReadyImplCopyWithImpl<$Res>
    extends _$LivenessStateCopyWithImpl<$Res, _$ReadyImpl>
    implements _$$ReadyImplCopyWith<$Res> {
  __$$ReadyImplCopyWithImpl(
    _$ReadyImpl _value,
    $Res Function(_$ReadyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cameraController = null,
    Object? isFaceDetected = null,
    Object? isFaceCentered = null,
    Object? stabilityScore = null,
    Object? isCapturing = null,
    Object? instruction = freezed,
  }) {
    return _then(
      _$ReadyImpl(
        cameraController: null == cameraController
            ? _value.cameraController
            : cameraController // ignore: cast_nullable_to_non_nullable
                  as CameraController,
        isFaceDetected: null == isFaceDetected
            ? _value.isFaceDetected
            : isFaceDetected // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFaceCentered: null == isFaceCentered
            ? _value.isFaceCentered
            : isFaceCentered // ignore: cast_nullable_to_non_nullable
                  as bool,
        stabilityScore: null == stabilityScore
            ? _value.stabilityScore
            : stabilityScore // ignore: cast_nullable_to_non_nullable
                  as double,
        isCapturing: null == isCapturing
            ? _value.isCapturing
            : isCapturing // ignore: cast_nullable_to_non_nullable
                  as bool,
        instruction: freezed == instruction
            ? _value.instruction
            : instruction // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ReadyImpl implements _Ready {
  const _$ReadyImpl({
    required this.cameraController,
    this.isFaceDetected = false,
    this.isFaceCentered = false,
    this.stabilityScore = 0.0,
    this.isCapturing = false,
    this.instruction,
  });

  @override
  final CameraController cameraController;
  @override
  @JsonKey()
  final bool isFaceDetected;
  @override
  @JsonKey()
  final bool isFaceCentered;
  @override
  @JsonKey()
  final double stabilityScore;
  @override
  @JsonKey()
  final bool isCapturing;
  @override
  final String? instruction;

  @override
  String toString() {
    return 'LivenessState.ready(cameraController: $cameraController, isFaceDetected: $isFaceDetected, isFaceCentered: $isFaceCentered, stabilityScore: $stabilityScore, isCapturing: $isCapturing, instruction: $instruction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadyImpl &&
            (identical(other.cameraController, cameraController) ||
                other.cameraController == cameraController) &&
            (identical(other.isFaceDetected, isFaceDetected) ||
                other.isFaceDetected == isFaceDetected) &&
            (identical(other.isFaceCentered, isFaceCentered) ||
                other.isFaceCentered == isFaceCentered) &&
            (identical(other.stabilityScore, stabilityScore) ||
                other.stabilityScore == stabilityScore) &&
            (identical(other.isCapturing, isCapturing) ||
                other.isCapturing == isCapturing) &&
            (identical(other.instruction, instruction) ||
                other.instruction == instruction));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    cameraController,
    isFaceDetected,
    isFaceCentered,
    stabilityScore,
    isCapturing,
    instruction,
  );

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadyImplCopyWith<_$ReadyImpl> get copyWith =>
      __$$ReadyImplCopyWithImpl<_$ReadyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() initializing,
    required TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )
    ready,
    required TResult Function(String imagePath) success,
    required TResult Function(String message) error,
  }) {
    return ready(
      cameraController,
      isFaceDetected,
      isFaceCentered,
      stabilityScore,
      isCapturing,
      instruction,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? initializing,
    TResult? Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult? Function(String imagePath)? success,
    TResult? Function(String message)? error,
  }) {
    return ready?.call(
      cameraController,
      isFaceDetected,
      isFaceCentered,
      stabilityScore,
      isCapturing,
      instruction,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? initializing,
    TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult Function(String imagePath)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (ready != null) {
      return ready(
        cameraController,
        isFaceDetected,
        isFaceCentered,
        stabilityScore,
        isCapturing,
        instruction,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Initializing value) initializing,
    required TResult Function(_Ready value) ready,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) {
    return ready(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Initializing value)? initializing,
    TResult? Function(_Ready value)? ready,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return ready?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Initializing value)? initializing,
    TResult Function(_Ready value)? ready,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (ready != null) {
      return ready(this);
    }
    return orElse();
  }
}

abstract class _Ready implements LivenessState {
  const factory _Ready({
    required final CameraController cameraController,
    final bool isFaceDetected,
    final bool isFaceCentered,
    final double stabilityScore,
    final bool isCapturing,
    final String? instruction,
  }) = _$ReadyImpl;

  CameraController get cameraController;
  bool get isFaceDetected;
  bool get isFaceCentered;
  double get stabilityScore;
  bool get isCapturing;
  String? get instruction;

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReadyImplCopyWith<_$ReadyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SuccessImplCopyWith<$Res> {
  factory _$$SuccessImplCopyWith(
    _$SuccessImpl value,
    $Res Function(_$SuccessImpl) then,
  ) = __$$SuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String imagePath});
}

/// @nodoc
class __$$SuccessImplCopyWithImpl<$Res>
    extends _$LivenessStateCopyWithImpl<$Res, _$SuccessImpl>
    implements _$$SuccessImplCopyWith<$Res> {
  __$$SuccessImplCopyWithImpl(
    _$SuccessImpl _value,
    $Res Function(_$SuccessImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? imagePath = null}) {
    return _then(
      _$SuccessImpl(
        imagePath: null == imagePath
            ? _value.imagePath
            : imagePath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SuccessImpl implements _Success {
  const _$SuccessImpl({required this.imagePath});

  @override
  final String imagePath;

  @override
  String toString() {
    return 'LivenessState.success(imagePath: $imagePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuccessImpl &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, imagePath);

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuccessImplCopyWith<_$SuccessImpl> get copyWith =>
      __$$SuccessImplCopyWithImpl<_$SuccessImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() initializing,
    required TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )
    ready,
    required TResult Function(String imagePath) success,
    required TResult Function(String message) error,
  }) {
    return success(imagePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? initializing,
    TResult? Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult? Function(String imagePath)? success,
    TResult? Function(String message)? error,
  }) {
    return success?.call(imagePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? initializing,
    TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult Function(String imagePath)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(imagePath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Initializing value) initializing,
    required TResult Function(_Ready value) ready,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Initializing value)? initializing,
    TResult? Function(_Ready value)? ready,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Initializing value)? initializing,
    TResult Function(_Ready value)? ready,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class _Success implements LivenessState {
  const factory _Success({required final String imagePath}) = _$SuccessImpl;

  String get imagePath;

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuccessImplCopyWith<_$SuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
    _$ErrorImpl value,
    $Res Function(_$ErrorImpl) then,
  ) = __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$LivenessStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'LivenessState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() initializing,
    required TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )
    ready,
    required TResult Function(String imagePath) success,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? initializing,
    TResult? Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult? Function(String imagePath)? success,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? initializing,
    TResult Function(
      CameraController cameraController,
      bool isFaceDetected,
      bool isFaceCentered,
      double stabilityScore,
      bool isCapturing,
      String? instruction,
    )?
    ready,
    TResult Function(String imagePath)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Initializing value) initializing,
    required TResult Function(_Ready value) ready,
    required TResult Function(_Success value) success,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Initializing value)? initializing,
    TResult? Function(_Ready value)? ready,
    TResult? Function(_Success value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Initializing value)? initializing,
    TResult Function(_Ready value)? ready,
    TResult Function(_Success value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements LivenessState {
  const factory _Error({required final String message}) = _$ErrorImpl;

  String get message;

  /// Create a copy of LivenessState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
