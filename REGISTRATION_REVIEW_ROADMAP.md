# Registration Flow — Review & Fix Roadmap

**Created:** 2026-05-29
**Method:** Read-only clean-sweep review of all 9 registration screens + cross-cutting auth data layer (27 agent passes, 3 per flow, advisor reconciliation per flow). Then fix-mode began.
**Status legend:** ✅ Fixed & verified (analyze 0 / 155 tests / build) · 🟡 Code-complete, on-device-unverified · ⬜ Open (client-fixable) · 🔒 Backend-only (needs `tander-backend` repo) · ⏸️ Deferred (needs product decision)

> **Epistemic caveat:** Every finding is from **reading code, not running it.** Backend-checklist items are *hypotheses to confirm*, not observed failures. Recent fixes are code-complete + analyze/test/build-pass but **on-device-unverified** (device disconnected during this work).

---

## HOW TO USE THIS ROADMAP (for the next `/goal` session)

1. The **cross-cutting iteration is DONE** (badges, data-layer hardening, dead-DTOs). Don't redo it.
2. Resume at **Iteration 2** below (Theme-A accessibility pass) — highest-value remaining client work.
3. Then the per-flow ⬜ items in the order listed.
4. The 🔒 items cannot be done here — they're spec'd for the backend team at the bottom.
5. Line numbers are **approximate** (the badge fix shifted some); re-grep before editing.
6. Pattern that worked: ultrathink → audit agent(s) → advisor → fix agent, gated at `flutter analyze lib/` = 0, `flutter test` = 155, `flutter build apk --debug`. Fix agents must use **non-overlapping file scopes** (never 3 writers on one file).

---

## 🧭 THE HEADLINE (architectural reveal)

**The flow is ID-verification-FIRST; the step badges were a pre-refactor fossil.**

Actual execution order: `Login → "Register" → Ready-to-Verify → ID Scanner → Verification Result → Sign Up → OTP → (account created) → Profile → Photo → Notification → Welcome → Discover`.

Proof (load-bearing): Sign Up's `register()` cannot complete without `auditId`, written by exactly one place — the ID scanner's `verifyIdPreRegister`. Router comment confirms: *"pendingIdVerification is never emitted mid-onboarding (ID is verified pre-registration)."* Before the fix, a new user's first screen read **"Step 5 of 6"** (sequence 5→1→2→3→4→6).

**Status: ✅ FIXED** — renumbered to **5-step, ID-unnumbered** (user-approved scheme).

---

## DECISIONS LOCKED

- **Badge scheme:** 5-step, ID-verification unnumbered. Sign Up=1/5, OTP=2/5, Profile=3/5, Photo=4/5, Notification=5/5. Ready-to-Verify / ID Scanner / Verification Result carry **no badge**.
- **Phase-mapping default:** keep `_ => .complete` but **log** unknown strings (changing the default risks trapping complete users on a backend rename — deliberate).
- **Availability-parse:** keep current return values but **log** unexpected shapes (visibility, not behavior change).
- **Checkbox-gating fix:** the naive "disable button when unchecked" is *worse* for 60+ (greys button with no explanation). Needs careful version (keep enabled + make checkboxes visible/scrolled-into-view) or deliberate defer. ⏸️

---

## ✅ ITERATION 1 — CROSS-CUTTING (DONE, verified)

| Fix | Detail | Files |
|---|---|---|
| ✅ Badge renumber | 5-step ID-unnumbered; `AuthStepHeader.currentStep` made nullable to hide badge. Sign Up live header was actually "of 4" → fixed to 1/5. | `auth_scene_decorations.dart`, `ready_to_verify_screen.dart`, `notification_permission_screen.dart`, `otp_verification_screen.dart`, `profile_setup_screen.dart`, `photo_setup_screen.dart`, `sign_up_screen.dart` (+ dead `sign_up_header.dart`) |
| ✅ Phase-mapping drift logging | Unknown backend phase logs `AppLogger.warning` then defaults to `.complete` (unchanged). Helper `_unrecognisedPhase`. | `core/auth/session_manager.dart` |
| ✅ Availability-parse drift logging | Unexpected response shape logs warning; return values byte-for-byte unchanged. Legit "taken" stays quiet. | `auth/data/datasources/auth_remote_datasource.dart` |
| ✅ Dead-DTO removal | 5 unused DTOs removed (~151 LOC), `.g.dart` regenerated: `CheckAvailabilityResponseDto`, `SendOtpRequestDto`, `VerifyRegistrationOtpRequestDto`, `LoginResponseDto`, `IdVerificationRequestDto` | `core/contracts/auth_contracts.dart` (+`.g.dart`) |

---

## ⬜ ITERATION 2 — THEME A: SYSTEMATIC ACCESSIBILITY PASS (highest-value remaining)

One coordinated pass, not N tickets. All client-fixable. Target: 60+ audience, WCAG 44pt minimum.

**Sub-44 touch targets:**
- ⬜ Sign Up: "Sign In" link (plain GestureDetector, no min size) — `sign_up_form_card.dart` (~SignInRow)
- ⬜ Sign Up: T&C / Privacy `TapGestureRecognizer` TextSpans (hit area = text width only) — `agreement_checkboxes.dart` (~line 121)
- ⬜ OTP: digit boxes 36px min-clamp → raise to 44 — `otp_digit_boxes.dart` (~line 107)
- ⬜ OTP: resend link 4px vertical padding — `resend_timer.dart` (~line 86)
- ⬜ OTP: "Contact support" escape-hatch link unpadded — `otp_verification_screen.dart` (~line 759)
- ⬜ Profile: DOB help-icon ~36px (Cycle 6b border made it *look* tappable without enlarging hit area) — `profile_form_fields.dart` (~line 96)
- ⬜ Photo: remove-button 32×32 — `photo_grid_slots.dart` (~line 151)
- ⬜ Error-dismiss X 32px — `auth_error_display.dart` (~line 258)

**Missing Semantics / liveRegion:**
- ⬜ OTP digit input — no Semantics wrapper (screen reader can't announce) — `otp_digit_boxes.dart`
- ⬜ ID Scanner submitting/error states — no liveRegion announcement — `id_scanner_screen.dart`
- ⬜ Photo grid + empty slots + uploading state — no Semantics — `photo_grid_slots.dart`
- ⬜ Back buttons missing `button: true` (have label only) — various headers

**Real reduce-motion gaps** (NOTE: progress spinners are correctly NOT gated — they signal work):
- ⬜ Method-selector shimmer — `method_selector.dart` (~line 96)
- ⬜ Availability pulsing-dots loader — `availability_suffix_icon.dart` (~line 42)
- ⬜ VerificationResult success-icon `elasticOut` scale — `verification_result_screen.dart` (~line 59)

---

## ⬜ PER-FLOW FIX ITERATIONS (3–9)

### Flow 1 — Sign Up
- ⏸️ **Checkbox button-gating** (1.2): careful version only (keep enabled + checkbox visibility), NOT naive disable. — `sign_up_form_card.dart`
- ⬜ Availability vs submit error copy inconsistency (1.6): "...Sign in to complete your profile" (mid-form) vs bare (submit). Pick one. — `sign_up_form_card.dart`
- (Theme A items → Iteration 2)

### Flow 2 — OTP
- ⬜ Auto-submit-on-6-digits not documented (surprise for 60+) — add microcopy. — `otp_verification_screen.dart` (~line 639)
- ⬜ Progress bar "X of 6 digits" cognitive noise — consider removing. — `otp_verification_screen.dart` (~line 803)
- (Theme A items → Iteration 2)

### Flow 3 — Profile
- ⬜ **18-vs-60 copy** (3.1a): DOB-help says "60+", age-error says "18 or older". The `≥18` check is **vestigial** (60+ enforced at ID gate). Align Profile copy/check to 60. Verification Result already correctly says "at least 60". — `profile_setup_screen.dart` (~line 191), `dob_help_sheet.dart`
- ⬜ Error 8s auto-dismiss too fast for 60+ (app-wide, Cycle 1 timer) — consider 12s or manual-only for validation. — `auth_error_display.dart` (~line 89)

### Flow 4 — Photo
- ⬜ **Concurrent-upload race** (4.2, client-fixable, no backend dep): slot tracked by index captured at add-time; list contracts on a failed slot's removal → stale-index callback strands a slot in `isUploading` → Continue permanently disabled (Skip still escapes). Fix: track by identity (file path/UUID), not index. — `photo_setup_screen.dart` (~lines 152–246)
- ⬜ Temp image files never cleaned up (LOW) — `photo_setup_screen.dart` (~line 139)
- ⬜ Photo count "up to 4" only in error copy, not upfront (LOW)
- (Theme A items → Iteration 2)

### Flow 5 — Ready-to-Verify
- ⬜ Camera-prep guidance / "why ID needed" thin / mandatory-vs-skip unclear (MED) — `ready_to_verify_screen.dart`
- ⬜ Trust text 14pt grey, low-vision miss (LOW-MED)

### Flow 6 — ID Scanner
- ⬜ Privacy reassurance not repeated at capture point (MED, **draft carefully**: must match actual retention [PII purged 30d, fingerprints kept] AND avoid biometric-claim footgun) — exists one screen back on Ready-to-Verify. — `id_scanner_screen.dart`
- ⬜ 10s cancel-affordance delay (LOW-MED tuning) — `id_scanner_screen.dart` (~line 169)
- ⬜ `CODE:/HINT:/STATE:`-in-message error protocol fragility (Theme B, loud-but-fragile — has legacy text fallback) — backend coordination ideal
- (Semantics → Iteration 2)

### Flow 7 — Verification Result
- ⬜ **faceMismatch "Contact Support" → `popUntil(isFirst)` + live `// TODO`** (7.1, MED): button promises support, delivers pop-to-root under pushReplacement entry. Pre-existing pattern (NOT a Cluster-2 regression). Fix: route to actual support (mailto via `launchSupportEmail`) or `context.go`. — `verification_result_screen.dart` (~line 320)
- ⬜ ageRequirementNotMet "Back to Start" → `popUntil(isFirst)` fragile under pushReplacement (LOW) — `verification_result_screen.dart` (~line 318)
- ⬜ "Learn More" primary (ageRequirementNotMet) routes to login — misleading label (LOW-MED) — (~line 379)

### Flow 8 — Notification
- ⬜ Feature cards engagement-focused, not benefit/safety-focused for 60+ (MED) — `notification_permission_screen.dart` (~lines 40–56)
- ⬜ Permission-denied dialog: "Skip" first/easier-tap; "Open Settings" wording (LOW-MED) — (~line 106)

### Flow 9 — Welcome
- ✅ Clean — no findings. (Reduce-motion gated, first-name extractor robust, one-time flag coherent, router-guarded.)

---

## THEME B — Fail-silent parsing / drift fragility (status)

- ✅ availability-parse → now logs on drift (Iteration 1)
- ✅ phase-mapping → now logs on unknown (Iteration 1)
- ✅ 5 dead DTOs removed (Iteration 1)
- 🔒 photo field-name divergence → backend (see below)
- ⬜ `CODE:/HINT:/STATE:` regex protocol (Flow 6) — fragile but fail-loud-with-fallback; ideally backend returns structured `{code,message,emailHint,existingAccountState}`
- Note: most manual-parse sites have downstream fail-loud guards (refreshToken emptiness throws, registrationPhase reasonable default). The two genuinely silent-and-dangerous ones are now hardened.

**GOOD (confirmed solid, no action):** interceptor stack (loop-guard + concurrent-401 queue + definitive-vs-transient); NetworkExceptionHandler mapping complete; all 9 AppException userMessages safe for 60+; token storage Bearer-tolerant; no client-side Twilio JWT minting.

---

## 🔒 BACKEND HANDOFF — needs `tander-backend` repo (cannot be done client-side)

Exact contract questions for the backend team:

1. **Photo upload field-name** (HIGH, possible current bug): endpoints `/user/upload-profile-photo` + `/user/upload-additional-photos` receive **`'file'`** from onboarding (`photo_setup_screen.dart`) but **`'profilePhoto'`/`'additionalPhotos'`** from profile-edit (`profile_remote_datasource.dart`). Which field name(s) does each endpoint actually accept? One client path may be silently 400-ing. → then align the client.
2. **Register idempotency** (Flow 2): if `register()` succeeds but `signIn()` fails, the account exists tokenless. What does a duplicate `/auth/register` return? If structured "already exists," client can catch + route to login. If 500, the OTP-screen "data expired" misdirection stands.
3. **Age-enforcement authority** (Theme C / Flow 6): does the backend **recompute** age from the uploaded ID, or **trust** the client-sent `meetsAgeRequirement` flag? If it trusts the flag, the 60+ gate is client-side and tamper-bypassable.

**Also confirm (lower urgency):** availability response shape `{data:{exists,blocked}}`; canonical `registrationPhase` enum list vs client switch; OTP-verify returns `{valid:bool}` (both SMS+email); `verifyIdPreRegister` auditId shape (top-level vs nested).

---

## VERIFICATION CEILING

- Iteration-1 fixes: ✅ analyze 0 / 155 tests / APK build — but 🟡 **on-device-unverified** (badge layout with absent Ready-to-Verify badge; logo positioning). Device disconnected for recent installs.
- Behavior-changing future fixes (upload-race refactor, any checkbox-gating) will be code-complete + gated but on-device-pending until a device is connected: `adb -s e4d225e4 install -r build/app/outputs/flutter-apk/app-debug.apk`.
- 155 test count is the current green baseline. No widget/integration tests cover these screens' UX — gates are analyze + unit tests + build only.

---

## SUGGESTED NEXT-SESSION ORDER

1. **Iteration 2 — Theme A a11y pass** (one coordinated pass; biggest user-value, all client-fixable, low risk)
2. **Flow 4 — upload-race** (confirmed client bug, clean fix, no backend dep)
3. **Flow 7 — faceMismatch routing + TODO** (reachable broken affordance)
4. **Flow 3 — 18-vs-60 copy alignment**
5. Remaining per-flow copy/UX (Flows 1,2,5,6,8 LOW-MEDs)
6. ⏸️ Checkbox-gating (careful version) — decide approach first
7. 🔒 Backend items — separate `tander-backend` session
