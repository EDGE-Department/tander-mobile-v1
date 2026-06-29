/// Pure, widget-free age-eligibility helpers shared by the profile-setup submit
/// gate and the birth-date picker floor.
///
/// Extracted so the trap-critical fail-open logic is unit-testable without
/// widget/provider scaffolding, and so a single age computation governs both
/// surfaces (the picker floor and the submit gate) instead of drifting copies.
library;

/// Whole-years age of someone born on [birthDate] as of [asOf].
///
/// Inclusive on the birthday: on your Nth birthday you are exactly N (so an
/// N-minimum is satisfied that day). This mirrors the backend's
/// `Period.between(...).getYears()` and the original screen calculation —
/// using a strict `>` here would re-trap an exactly-eligible senior whose
/// birthday is today.
int ageInYears(DateTime birthDate, DateTime asOf) {
  var age = asOf.year - birthDate.year;
  final hadBirthdayThisYear =
      asOf.month > birthDate.month ||
      (asOf.month == birthDate.month && asOf.day >= birthDate.day);
  if (!hadBirthdayThisYear) age -= 1;
  return age;
}

/// Whether a manually-entered [birthDate] must be BLOCKED at submit.
///
/// FAILS OPEN (returns `false` — do not block) when [minimumAge] is `null`,
/// i.e. the backend minimum is unknown (the `/auth/verification-config` fetch
/// failed or returned an unusable body). Reaching profile setup already
/// required clearing the backend's mandatory, hard-failing ID age-gate, so the
/// client check here is UX-only; a restrictive client fallback would merely
/// re-trap eligible users (the exact dead-end this logic exists to remove).
/// Inclusive: a user who is exactly [minimumAge] passes.
bool isBirthDateBelowMinimum({
  required DateTime birthDate,
  required int? minimumAge,
  required DateTime asOf,
}) {
  if (minimumAge == null) return false;
  return ageInYears(birthDate, asOf) < minimumAge;
}

/// The most permissive legal age floor for the birth-date picker, used when the
/// backend minimum is unknown.
///
/// Assumes the backend minimum is >= 18 (true for prod = 20 and the default
/// 60). If `TANDER_MINIMUM_AGE` were ever set below 18 *and* the config fetch
/// failed, the picker would floor here while the submit gate fails open — an
/// internal inconsistency, but not exploitable (the backend ID gate is the real
/// enforcer).
const int permissivePickerAgeFloor = 18;

/// The birth-date picker's minimum-age floor: the backend minimum when known,
/// else [permissivePickerAgeFloor].
///
/// Never falls back to a restrictive value (e.g. 60): doing so would cap the
/// picker at "60 years ago" on a config-fetch failure and stop an eligible
/// 20-59 user from selecting their real birthday — relocating the trap to the
/// picker.
int pickerAgeFloor(int? minimumAge) => minimumAge ?? permissivePickerAgeFloor;
