/// Re-exports [AuthSession] and [RegistrationPhase] as the auth domain entity.
///
/// The [AuthSession] class in core/auth already serves as a pure domain model
/// (immutable, no infrastructure dependencies), so a wrapper would add
/// indirection without value.
library;

export 'package:tander_flutter_v3/core/auth/session_manager.dart'
    show AuthSession, RegistrationPhase;
