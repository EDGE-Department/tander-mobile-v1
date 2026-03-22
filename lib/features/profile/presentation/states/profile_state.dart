import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';

/// Sealed state hierarchy for the profile UI.
///
/// Using a sealed class guarantees exhaustive `switch` -- the compiler
/// will error if a new subclass is added without updating every consumer.
sealed class ProfileState {
  const ProfileState();
}

/// Profile data is being fetched for the first time.
final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile data was successfully loaded.
final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({required this.profile});

  final UserProfile profile;
}

/// Profile fetch or mutation failed with a typed exception.
final class ProfileError extends ProfileState {
  const ProfileError({required this.exception});

  final AppException exception;
}
