# tander-flutter-v3 — Whole-App Launch-Readiness Review (2026-05-29)

**Method:** Verification-first. Every finding below was produced by a reviewer **and**
re-checked by a separate skeptical agent that re-opened the actual file (and, where the
claim was a contract, the on-disk `tander-backend`). Claims that could not be backed by
quoted code were dropped. iOS native code is a **static read only** — this is a Windows
machine; it cannot be compiled or run, so no iOS claim is asserted as "works".

Coverage: 10 dimensions across all 325 Dart files + Android/iOS native layers + build/security.
45 candidate findings → **37 confirmed, 2 iOS-uncertain (need a Mac), 6 refuted as false positives.**

---

## Bottom line

The earlier "68% ready / iPhone 45% / iPad 58%" review you pasted is **not reliable in
its specifics** (≈40% false-positive rate, fabricated per-device percentages, and wrong
build numbers — see §1). But its one decisive structural conclusion is **correct**:

> **iOS is not launch-ready and cannot be promised; Android is much closer.**

My corrected, verified conclusion lands in the same place via mostly different, properly
evidenced reasoning, with **one important addition the pasted review missed entirely**:

- The **single most important defect to fix before launch affects BOTH platforms** — the
  token-refresh interceptor parses the wrong response shape (§3). It self-heals on the first
  occurrence (after a misleading "Network problem" error) but silently drops the rotated
  refresh token, which — given the backend's single-use rotation + reuse detection — can
  revoke the session on a later idle period. High-priority should-fix, not an immediate-crash blocker.
- **iOS** additionally has the uncompiled native call/video layer **and** App-Store
  submission risks (unused Location/background-location permissions). Not shippable to
  iPhone/iPad until a Mac + real-device pass.
- **Android** builds, `flutter analyze` is clean, 155 tests pass, and the native calling
  config is genuinely solid. **No hard launch-blocker was found.** It is ready for serious
  device QA now; a cluster of "should-fix" senior-UX and robustness issues (led by §3) should
  be cleared before a quality public launch (§5).

No percentages are invented below — findings are grouped by **what they block**.

---

## 1. Objective ground truth (re-measured, not taken from the pasted review)

| Check | Pasted review said | Actual (this machine, 2026-05-29) |
|---|---|---|
| `flutter analyze` | "failed, 16 warnings" | **No issues found** (clean, 129s) |
| `flutter test` | "146 tests" | **155 tests, all passed** |
| Android debug/release build | passed | (unchanged — Android builds) |
| iOS build | not run | **cannot run on Windows** — native call/video layer is source-complete but **uncompiled** (see `ios/IOS_BRIDGE_HANDOFF.md`) |

The red/orange boxes in the test log are **intentional negative-path logging**, not failures.

## 2. Adjudication of the pasted review's specific claims

| Pasted claim | Verdict | Evidence |
|---|---|---|
| iOS Twilio bridge uncompiled | ✅ **TRUE** — the decisive iOS blocker | `IOS_BRIDGE_HANDOFF.md:3`; bridge written on Windows |
| `main.dart:27` suppresses painting/`dart:ui` errors → empty widget | ✅ **TRUE** — masks rendering bugs in QA | `main.dart:27-44` returns `SizedBox.shrink()` for `painting.dart`/`dart:ui` |
| STOMP double-subscribe | ✅ **TRUE — and it's the common path** | `build()` calls `setRoomId()` (sub #1) then `_initialize` microtask subs again (#2). `message_thread_screen.dart:182`, `message_thread_notifier.dart:485,129` |
| Android minSdk 26 / iOS 13 floors | ✅ true but **by-design** | Documented Phase-5 calling decisions (`build.gradle.kts:48-53`, `Podfile:2`) — not bugs |
| Bottom-nav overflow on small phones | ⚠️ **partially true** | Active pill (~66px) can exceed an `Expanded` slot on ≤360dp; uses `Expanded`, so degrades not "breaks". `bottom_nav_bar.dart:147,183`, `tabMinSize=58` |
| Tablet liveness `face_overlay_widget.dart:83` breaks landscape | ❌ **FALSE** | File does not exist; liveness was removed |
| Video call ignores camera denial (`:102`) | ❌ **FALSE** | `message_thread_screen.dart:112-122` checks `cam.isGranted` and bails with a SnackBar |
| `rateLimit`/`duplicateId` have no GoRoute | ❌ **FALSE** | They are `VerificationResultState` enum values, never routes (`verification_result_screen.dart:11,15`) |
| `pendingIdVerification` → profileSetup (`:139`) | ❌ **FALSE** | Maps to `home` (`app_router.dart:144`) with a deliberate comment |

**Net:** ~3 real, 2 true-but-by-design, 1 partial, **4 outright false/stale.**

---

## 3. Top defect to fix before launch (both platforms): broken token-refresh parse → session instability

**`lib/core/network/interceptors/token_refresh_interceptor.dart:176-188`** — high-priority should-fix, **confirmed against the on-disk backend.**

The 401-recovery interceptor reads the rotated access token from a **flat** body field:

```dart
final newAccessToken = responseBody['accessToken'];   // ← always null
...
if (newAccessToken is! String || newAccessToken.isEmpty) {
  throw StateError('Invalid access token in refresh response');  // ← fires every time
}
```

But the live backend (`tander-backend/.../AuthController.java:100-103`) returns:
- access token **only** in the `Jwt-Token` response header, and
- body `new RefreshResponse(rotated.refreshToken())`, which `ApiResponseAdvice` wraps
  (refresh-token is **not** in its exempt list) into `{"success":true,"data":{"refreshToken":"…"}}`.

So **there is no `accessToken` field in the body at all**, and `_performTokenRefresh` throws
`StateError` on **every** real refresh (line 179). The impact is subtler than "session dead
until restart" — there are two distinct effects:

1. **Self-heals on the first occurrence, but with a misleading error.** `AuthInterceptor.onResponse`
   runs *earlier* in the same chain (order `[Logging, DeviceId, Auth, TokenRefresh]`) and
   **does** save the new access token from the `Jwt-Token` header on the refresh response —
   *before* the `StateError`. So the in-flight request (and any queued during the refresh) fail
   once with a misleading `"Network problem. Please try again."`, but the **next** request picks
   up the saved token and works.
2. **The rotated *refresh* token is silently dropped → can revoke the session on a later idle
   period.** The `StateError` skips `saveRefreshToken` (lines 186-187), and there is **no cookie
   manager** in the Dio chain to catch the `tander_rt` refresh cookie, so storage keeps the
   *old* refresh token. The backend uses **single-use refresh tokens with reuse detection**
   (`RefreshTokenService.rotate:40-71`): replaying an already-used token **revokes every session
   for the account** and returns `400 refresh-token-reused`. So the **second** time the app
   actually hits `/auth/refresh-token` (a second idle gap beyond the access-token TTL), it
   replays the stale token → all sessions revoked. That 400 is not a 401/403, so
   `_isDefinitiveAuthRejection` is again `false` → the client shows "Network problem"
   indefinitely; with `onSessionExpired` a no-op (§5), only a cold restart → login recovers.

How often this bites depends on the access-token TTL vs. real senior usage — intermittent app
opens with idle gaps make the two-refresh scenario realistic. It self-heals the first time and
is not an immediate-crash blocker, so it is **high-priority should-fix** rather than a hard
blocker — but it is the single most important correctness fix before a quality launch.

> Note: My earlier manual read praised the interceptor's *logic* and an initial draft of this
> section over-stated the impact as "dead until restart." Reading `AuthInterceptor` (which saves
> the header token) and the backend's single-use rotation corrected it to the two-stage mechanism
> above. The underlying defect — parsing a body field that is always null, throwing instead of
> retrying, and dropping the rotated refresh token — is real regardless.

**Fix:** in `_performTokenRefresh`, read the access token from the `Jwt-Token` response header
and the refresh token from `response.data['data']['refreshToken']` (exactly as
`session_manager.dart:296-304` already does), so the rotated refresh token is persisted and the
misleading failure path never fires.

---

## 4. iOS — not launch-ready (requires a Mac + real device)

The Dart call layer is platform-agnostic and shipped; the **iOS native media layer has
never been compiled.** On a Mac, expect 1–3 iteration rounds. These cannot be resolved here:

- **Whole iOS call/video stack uncompiled.** `IOS_BRIDGE_HANDOFF.md` is the task state.
  Independent static read confirms: the bridge's MethodChannel **event names match the
  contract verbatim**, no obvious force-unwrap crashers (defensive `?? ""`), and `hangUpRequested`
  is **correctly absent** from Swift — iOS routes CallKit "End" through the plugin's own Dart
  event stream (`AppDelegate.onEnd → action.fulfill()`), a deliberate platform difference, not a bug.
- **Compile risks (must verify on Mac), exactly the handoff-flagged lines:**
  - `TwilioVideoViewFactory.swift:31` — `VideoView(frame:delegate:)` two-arg init (uncertain vs Twilio 5.x). *If wrong, iOS won't build at all.*
  - `TwilioVideoBridge.swift:184` `DefaultAVAudioSessionConfigurationBlock()` — **reviewed and refuted as a bug**: it's a static closure property that is invoked (Twilio's documented idiom), not a discarded factory result.
- **Runtime risk:** `TwilioVideoBridge.swift:138` derives the Twilio room UUID from `roomName`
  assuming `roomName == backend roomId` used for the CallKit UUID (`AppDelegate.swift:113,123`).
  If they differ → **dead mic on a lock-screen answer.** Verify on device.
- **Cold-start VoIP fallback lifetime** (`AppDelegate.swift:133-141`, P1, uncertain): the
  fallback `CXProvider` is a local `let` whose async `reportNewIncomingCall` completion does
  **not** capture it — if ARC releases it before the report lands on a cold-start push, iOS may
  kill the app (violating the PushKit contract). Hold a strong reference / `withExtendedLifetime`.
  *(This is the cold-start path the safety net exists for — not a rare edge.)*
- **`flutter_callkit_incoming` is pinned 2.0.4+1** but the protocol was researched against 2.5.8 —
  verify the `onEvent`/`CallkitIncomingAppDelegate` signature on the first Mac build.

**iOS App Store submission risks (editable now on Windows, but they block iOS review):**
- **`Info.plist:81-84` + `Podfile:59-60` declare Location, including background "Always",
  with zero location code** (no geolocator/location dep, no `Geolocator`/`Permission.location`
  usage anywhere). Apple routinely **rejects** builds declaring Always/background location with
  no API use (Guideline 5.1.1/2.5.4). **Delete the two Info.plist keys + two Podfile flags.** (P1)
- **`Info.plist:82,84` use dating vocabulary** ("show you nearby matches") in a senior
  social/wellness app — off-brand and may invite stricter dating-app classification. (P2)

---

## 5. Android — close, but clear these before a quality launch

### Highest priority — fix before a quality launch
- **§3 token-refresh parse.** Self-heals on the first refresh (misleading "Network problem"),
  but drops the rotated refresh token → the backend's reuse detection can revoke the session on
  a later idle period. No hard crash, but the top session-stability fix.

### Should-fix (real, evidenced; senior-UX & robustness — not blockers)
**Auth / session**
- **`core_providers.dart:49-53` `onSessionExpired` is a no-op.** A server-revoked refresh
  token clears storage but leaves `AuthState=Authenticated`; user is trapped in the shell
  seeing "Network problem" on every request until they force-restart. (P1) Wire it to sign-out + route to login.
- **`app_router.dart:124-147` forces `pendingNotificationPermission`→home**, contradicting the
  login screen's phase→route map and making the **notification-permission screen unreachable** via
  the normal flow → seniors silently miss call/message push prompts. (P2)
- **`auth_notifier.dart:44-56` double `/user/me` on cold start;** a transient (non-401)
  failure on the redundant 2nd call strands a validly-restored user on login. (P2) Have the repo
  return the session `SessionManager` already built.

**Calls (v2)**
- **`v2_active_call_state.dart:109-111,176-224` caller's call never tears down on
  decline/cancel/no-answer; no ring timeout, no WPS terminal handling** (web has both). A senior
  calling someone who declines sees a frozen "Connecting…" until a Twilio-side timeout. (P1)
- **`v2_active_call_state.dart:196-197` Twilio connect failure silently wipes the call UI**
  with no error and no backend `end()` → leaked CONNECTING state can cause a wrong "busy". (P2)
- **`v2_in_call_screen.dart` no wakelock** → screen can dim/lock mid video call (v1 had this). (P3)

**Push / lifecycle leaks** (compound across logout→login, a normal session-expiry path)
- **`app_shell.dart:38-63` re-initializes push on every shell mount** and
  **`notification_handler.dart:48-62` / `push_notification_service.dart:133-136` never cancel
  their `onMessage`/`onMessageOpenedApp`/`onTokenRefresh` listeners** → after re-login, one push
  fires the handler (and native call UI / token re-register) N times. (P1/P2) Store + cancel subs.

**Messaging / realtime**
- **`stomp_client_manager.dart:57-58,117-123` fixed 1s reconnect, no backoff** → thundering-herd
  at 50k CCU (sibling `WpsClient` already uses 1s→30s). (P2)
- **`conversations_notifier.dart` polls every 3s for the whole session, never auto-disposed**
  (kept warm by the nav badge) → battery/data drain + ~20 req/min/user at scale. (P2)
- **`message_thread_notifier.dart:175-182` marks-as-read with no focus guard** → false "read"
  receipts + extra writes when the thread is mounted-but-backgrounded. (P2)
- **`message_thread_notifier.dart:414,422-424` optimistic rollback restores a stale snapshot**,
  dropping realtime messages that arrived during a failed unsend/hide. (P2)
- **`message_thread_notifier.dart` in-thread list is unbounded** (no pagination/cap) → memory/jank
  on low-end Android. (P2)
- **STOMP double-subscribe** (from the pasted review, confirmed §2) — typing/receipts double-fire;
  message dedup only partly mitigates. (P2)

**Senior accessibility (a11y is P-priority for a 60+ audience)**
- **`tander_text_field.dart:139-140` placeholder contrast ~1.4:1** — the format hints
  ("09XXXXXXXXX", "name@email.com", "8+ chars…") seniors rely on during onboarding are nearly
  invisible. (P2)
- **`tandy_screen.dart:331-338` breathing-suggestion tap targets <20px**; **`tandy_composer.dart:164-168`
  composer placeholder ~2.2:1 contrast.** (P2) App's own `AppSpacing.touchMinimum=44` is the target.

**Feature screens (skipped entirely by the pasted review)**
- **`profile_edit_screen.dart:138-149` Save silently discards gender, birthdate, civil status,
  religion, children count, languages** — the form edits them, the DTO supports them, but
  `_handleSave` never sends them. Data-loss in a primary flow. (P1) **First verify the
  `/user/profile` update endpoint actually accepts these six fields** (a `match web: only send
  fields the web sends` comment hints it may be deliberate): if the backend ignores them, the
  correct fix is to *remove them from the form*, not wire them — otherwise the "fix" is a second
  silent no-op.
- **`create_post_sheet.dart:388-404` uses `Image.asset` on a picked file path** → every attached
  community-post photo shows a broken-image icon. One-line fix (use `Image.file`). (P1)
- **`discover_notifier.dart:136-162` failed like/pass silently vanishes**, no error, no retry,
  no rollback → the intended connection is silently lost. (P2)
- `community_feed_notifier.dart:133-143` optimistic revert can wipe concurrently-loaded posts (P3);
  edit-post `Image.network` lacks `errorBuilder` (P3).

**Android native (config is otherwise strong — see §6)**
- **Camera is `required=true` in the merged manifest** (from `cunning_document_scanner`) → Play
  hides the app from camera-less devices. Add `<uses-feature android:name="android.hardware.camera"
  android:required="false" tools:replace="android:required"/>`. (P2)
- `tander_general` FCM channel not pre-created natively (defense-in-depth; benign while payloads
  stay data-only) (P3); `RECEIVE_BOOT_COMPLETED` + `BLUETOOTH_CONNECT` are declared-but-unused
  permissions (remove for least-privilege / Play hygiene) (P3).

### Cosmetic / cleanup (P3)
- `main.dart:27-44` global painting-error suppression — replace the band-aid with a real fix to
  whatever assertion it was hiding (it makes QA harder).
- `bottom_nav_bar.dart:147,183` the active-tab pill (~66px) can exceed an `Expanded` slot on
  ≤360dp screens, producing a few px of overflow on the active tab. Uses `Expanded`, so it
  degrades rather than "breaks"; clamp the pill padding / icon box on narrow widths.
- Dead/divergent messaging endpoint constants + unwired mute/unmute (`api_endpoints.dart:88-103`).
- Two contradictory STOMP message shapes — the **typed `StompMessagePayload` contract is the dead
  one**; the live flat parser is correct (delete the dead artifact).
- iOS stale copy: camera usage string still references removed liveness (`Info.plist:71-72`);
  `NSLocalNetworkUsageDescription` claims P2P though calls use the Twilio SFU (`:79-80`);
  `AppDelegate.swift:12-14` `isPortraitLocked` still references "liveness/ID verification".
- `networkQualityChanged` string format differs iOS vs Android (no live consumer today).

---

## 6. What is actually solid (verified — give credit)

- **Networking architecture.** `DioClient` + interceptor ordering is clean; the token-refresh
  interceptor's *control logic* (single-flight, pending-queue replay, `_hasRetried` loop-breaker,
  `/auth/*` exclusion, transient-vs-definitive distinction) is genuinely well-designed — it just
  parses the wrong body shape (§3). `NetworkExceptionHandler` maps every Dio error type correctly
  (covered by tests).
- **Android calling config.** Manifest declares the correct `phoneCall|microphone|camera`
  foreground-service types (Android 14+), `FOREGROUND_SERVICE_*`, `POST_NOTIFICATIONS`,
  `USE_FULL_SCREEN_INTENT`, `usesCleartextTraffic="false"` + network-security-config,
  `showWhenLocked`/`turnScreenOn` — with a deliberate, well-reasoned no-orientation-lock comment.
- **Test + analyzer health.** Clean `flutter analyze`; 155 passing tests pinning the mappers,
  network exception handling, validators, and registration-phase parsing.
- **Registration flow** is unified and ~91% polished (per project history), liveness removed.
- **Verification caught 6 false positives** from the review pass itself (e.g. the live STOMP parser
  is correct; iOS speakerphone routing is the sanctioned Twilio+CallKit pattern; connection lists
  don't need client pagination — backend returns a bare capped list), so the confirmed list above
  is high-trust.

---

## 7. Suggested order of work

1. **Fix §3 token refresh** (read `Jwt-Token` header + `data.refreshToken`). Top correctness fix:
   removes the misleading "Network problem" errors and the latent session-revocation. No hard
   blocker (Android has none), but the highest-value pre-launch fix on both platforms.
2. **iOS:** open on a Mac, `pod install`, build; fix the two compile-risk lines + the cold-start
   CXProvider lifetime; verify lock-screen audio (UUID assumption); **delete the unused
   Location permissions/strings**; then real-device call test both directions.
3. **Should-fix cluster** for a quality senior launch: `onSessionExpired`, call decline/no-answer
   teardown + ring timeout, push-listener leaks, the profile-edit data-loss, the create-post
   thumbnail, placeholder contrast, and the notification-permission routing gap.
4. Scale hygiene before 50k: STOMP backoff, conversations-poll gating.
5. Cosmetic/cleanup last.

*Generated 2026-05-29. iOS items are static reads — confirm on a Mac + real device before trusting.*
