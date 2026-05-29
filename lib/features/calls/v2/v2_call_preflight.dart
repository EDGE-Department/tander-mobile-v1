import 'package:tander_flutter_v3/core/contracts/calls_v2_contracts.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/calls_v2_remote_datasource.dart';

/// Pre-flight before starting a v2 call. Mirrors web's
/// `resolveActiveCallConflict` in `use-call-manager.ts`.
///
/// Per product directive ("don't ask, just auto-end"), a new call is never
/// blocked behind a modal: if the user already has an active call — a stuck
/// CONNECTING zombie, a leftover on another device, whatever — we auto-end
/// it, then return. The backend's terminal transition releases the caller's
/// `user_call_state`, so the follow-up startCall isn't rejected as
/// caller-busy.
///
/// Best-effort: a `/active` read failure or an end failure is swallowed —
/// the caller proceeds to startCall, which surfaces the real error
/// (e.g. callee-busy) normally.
Future<void> resolveV2CallConflict({
  required CallsV2RemoteDatasource datasource,
}) async {
  ActiveCallEnvelopeDto? active;
  try {
    final response = await datasource.getActive();
    active = response.active;
  } on Object catch (e) {
    AppLogger.warning(
      'preflight /active failed: $e — proceeding optimistically',
      operation: 'resolveV2CallConflict',
    );
    return;
  }
  if (active == null) return;

  // Auto-end the existing call. RINGING-as-caller cancels; everything else
  // (CONNECTING/ACTIVE/RECONNECTING/…) ends. Awaited so the user_call_state
  // release commits before the subsequent startCall runs.
  final isCaller = active.role.toLowerCase() == 'caller';
  try {
    if (isCaller && active.state == 'RINGING') {
      await datasource.cancel(active.callId, reason: 'replaced-by-new-call');
    } else {
      await datasource.end(active.callId, reason: 'replaced-by-new-call');
    }
  } on Object catch (e) {
    AppLogger.warning(
      'auto-end of existing call failed; proceeding anyway: $e',
      operation: 'resolveV2CallConflict',
    );
  }
}
