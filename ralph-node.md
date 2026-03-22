# Tander Flutter V3 — Ralph Node (Permanent Context)

## 1. PROJECT IDENTITY
- App: Tander — Dating + wellness app for Filipino seniors 60+
- Source (web): C:\Users\admin\Desktop\Tander\tander-web
- Backend: C:\Users\admin\Desktop\Tander\Tanders Backend
- Destination: C:\Users\admin\Desktop\Tander\tander-flutter-v3
- V2 Reference: C:\Users\admin\Desktop\Tander\tander-flutter-V2 (architecture patterns only)

## 2. ARCHITECTURE RULES
- Clean Architecture: features/{module}/data|domain|presentation
- State: Riverpod 2.x (providers, notifiers, states)
- Navigation: GoRouter with redirect guards
- HTTP: Dio with auth interceptor
- Realtime: stomp_dart_client (global singleton, NEVER disconnect on unmount)
- WebRTC: flutter_webrtc (P2P, STOMP signaling)
- Push: firebase_messaging (FCM) + flutter_callkit_incoming (iOS CallKit)
- Tokens: access token in-memory, refresh token in FlutterSecureStorage
- Result type: sealed class Result<T> { Success | Failure }
- Every file < 400 lines, every function < 30 lines, every function ≤ 3 params
- No dynamic, no empty catch, no magic numbers, no vague names
- All domain entities immutable (final fields)
- All DTOs use json_serializable with @JsonKey for field mapping
- Snake_case files, PascalCase classes, camelCase variables

## 3. DESIGN SYSTEM (EXACT from web)
### Colors
- primary: 0xFFE67E22 (orange), primaryHover: 0xFFD35400, primaryLight: 0xFFFEF3E2
- secondary: 0xFF0F9D94 (teal), secondaryHover: 0xFF0D8A82, secondaryLight: 0xFFE6F7F6
- canvas: 0xFFFAF8F5, card: 0xFFFFFFFF, subtle: 0xFFF5F1EC
- textStrong: 0xFF1F2937, textBody: 0xFF4B5563, textMuted: 0xFF9CA3AF, textInverse: 0xFFFFFFFF
- success: 0xFF22C55E, danger: 0xFFEF4444, warning: 0xFFF59E0B, info: 0xFF3B82F6
- border: 0xFFE5E1DC, primaryAccessible: 0xFFCF6F1E
- darkWarm: 0xFF1A0800 (call bg, testimonials)

### Typography
- Display: "Bricolage Grotesque" (google_fonts), fallback "Plus Jakarta Sans"
- Body: "Plus Jakarta Sans" (google_fonts)
- Sizes: displayXl(48), displayLg(36), h1(30), h2(24), h3(20), bodyLg(18), body(16), bodySm(14), caption(12)
- Min body: 14px (elder-friendly)

### Spacing & Radius
- spacing: xxs=4, xs=8, sm=12, md=16, lg=24, xl=32, xxl=48
- radius: xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, full=999
- Touch targets: 44px min, 56px comfortable (elder-friendly)

### Shadows (warm orange-tinted)
- sm: BoxShadow(color: Color(0x14E67E22), blurRadius: 8, offset: Offset(0, 2))
- md: BoxShadow(color: Color(0x1AE67E22), blurRadius: 16, offset: Offset(0, 4))
- lg: BoxShadow(color: Color(0x1FE67E22), blurRadius: 32, offset: Offset(0, 12))

### Animation Curve
- premiumEase: Cubic(0.22, 1.00, 0.36, 1.00) ≈ Curves.easeOutExpo
- springCurve: Cubic(0.34, 1.56, 0.64, 1.00)
- durations: fast=150ms, base=250ms, slow=400ms, slower=600ms

## 4. BACKEND CONTRACT RULES (CRITICAL)
- Backend sends "Jwt-Token: Bearer {token}" response header — strip "Bearer " before storing
- registrationPhase is string enum: PENDING_EMAIL_VERIFICATION, PENDING_PROFILE_SETUP, PENDING_PHOTO_SETUP, PENDING_ID_VERIFICATION, PENDING_NOTIFICATION_PERMISSION, COMPLETE
- interests, lookingFor, languages come as JSON-encoded strings from /user/me — parse with jsonDecode
- Backend uses "matches" internally, UI says "Connections"
- targetUserId MUST be sent as int (not string) in ALL STOMP payloads
- Backend call type is lowercase "voice"/"video", normalize to CallType.AUDIO/.VIDEO
- Backend relays ICE candidates as "ice-candidate" type — handle BOTH "ice" and "ice-candidate"
- IceServer.urls is String (singular), not List — wrap in array if string
- Room ID format for DMs: dm_{minUserId}_{maxUserId}
- Spring pagination: content[], totalElements, totalPages, number, size, first, last

## 5. ALL API ENDPOINTS
### Auth
POST /api/auth/login — {email, password} → 200 + Jwt-Token header
POST /api/auth/register — {email, password, username, ...}
POST /api/auth/refresh-token — {refreshToken} → new tokens
POST /api/auth/forgot-password — {email}
POST /api/auth/verify-reset-otp — {email, otp}
POST /api/auth/reset-password — {email, otp, newPassword}
POST /api/auth/resend-verification — {email}
POST /api/auth/send-otp — {email}
POST /api/auth/verify-otp — {email, otp}
GET  /api/auth/check-email?email= — availability
GET  /api/auth/check-username?username= — availability
POST /api/auth/id-verification — multipart (idImage)

### Profile
GET  /user/me — current user profile
GET  /user/{userId} — other user profile
PUT  /user/profile — update profile
POST /user/upload-profile-photo — multipart
POST /user/upload-additional-photos — multipart
DELETE /user/delete-photo?photoUrl=
DELETE /user/delete-profile-photo
PUT  /user/reorder-photos — {photoUrls[]}
PUT  /user/change-password — {oldPassword, newPassword}
DELETE /user/delete-account
GET  /user/export-data

### Settings
GET/PUT /settings/notifications
GET/PUT /settings/privacy
GET/PUT /settings/security
GET/PUT /settings/discovery

### Discovery
GET  /api/discovery/profiles?page=&size=&minAge=&maxAge=&city=&country=
GET  /api/discovery/profile/{userId}

### Connections (backend calls "matches")
GET  /api/matches/received?page=&size= — incoming requests
GET  /api/matches/sent?page=&size= — sent requests
GET  /api/matches/connected?page=&size= — friends
POST /api/matches/{id}/accept
POST /api/matches/{id}/decline
POST /api/matches/{id}/cancel
DELETE /api/matches/{id} — remove connection
POST /api/matches/swipe — {targetUserId, direction: LEFT|RIGHT}

### Messages
GET  /chat/conversations
GET  /chat/conversations/{id}/messages?page=&size=
POST /chat/messages — {conversationId, content, type}
PUT  /chat/conversations/{id}/mark-read
PUT  /chat/conversations/{id}/mute
PUT  /chat/conversations/{id}/unmute
POST /chat/users/{userId}/start-conversation
POST /chat/messages/image — multipart
POST /chat/messages/voice — multipart

### Tandy (AI)
GET  /api/tandy/conversation
GET  /api/tandy/greeting
POST /api/tandy/send — {message}
DELETE /api/tandy/conversation — clear
PUT  /api/tandy/language — {language}
POST /api/tandy/messages/{id}/card-expanded

### Calls
POST /api/twilio/video/room — {receiverId, callType}
GET  /api/twilio/video/ice-servers
POST /api/twilio/video/accept — {roomName}
POST /api/twilio/video/decline — {roomName}
POST /api/twilio/video/end — {roomName}
POST /api/twilio/video/cancel — {roomName}
GET  /api/twilio/video/history?page=&size=
GET  /api/twilio/video/config — timeout values

### Push Notifications (NEW — web doesn't use these)
POST /api/notifications/register-token — {deviceToken, platform, deviceId}
POST /api/notifications/register-voip-token — {voipToken, deviceId}
POST /api/notifications/unregister-token — {deviceToken}
GET  /api/notifications/status — Firebase status + active devices

### Community
GET  /api/community/feed?page=&size=
GET  /api/community/posts/{id}
POST /api/community/posts — create post
POST /api/community/posts/{id}/comments
POST /api/community/posts/{id}/reactions

## 6. ALL STOMP DESTINATIONS
### Client → Server (send)
/app/webrtc.offer — {roomName, sdp, targetUserId: INT, callType}
/app/webrtc.answer — {roomName, sdp, targetUserId: INT}
/app/webrtc.ice — {roomName, candidate, targetUserId: INT}
/app/webrtc.hangup — {roomName, targetUserId: INT, reason}
/app/webrtc.media-state — {roomName, targetUserId: INT, isAudioMuted, isVideoOff}
/app/webrtc.ring-ack — {roomName, callerId: INT}
/app/chat.send/{roomId} — {content, type}
/app/chat.typing/{roomId} — {isTyping}
/app/chat.read — {conversationId}
/app/chat.delivered — {messageId, roomId}
/app/presence.heartbeat — {} (every 20 seconds)

### Server → Client (subscribe)
/topic/calls.{userId} — call lifecycle events
/user/{userId}/queue/calls — call events (redundant for reliability)
/topic/call/{roomId} — room-specific WebRTC signals
/user/{userId}/queue/webrtc — WebRTC signals (offer, answer, ice)
/topic/webrtc.{userId} — WebRTC signals (redundant)
/topic/chat/{roomId} — chat messages
/topic/chat/{roomId}/typing — typing indicators
/topic/chat/{roomId}/delivered — delivery receipts
/topic/chat/{roomId}/read — read receipts
/user/{userId}/queue/messages — new message notification

## 7. PUSH NOTIFICATION PAYLOADS (from backend)
### incoming_call (HIGH PRIORITY)
{type: "incoming_call", callerId, callerName, callerPhoto, callType: "voice"|"video", roomId, callUUID}
### missed_call
{type: "missed_call", callerId, callerName, callType, callLogId, timestamp}
### new_message
{type: "new_message", senderId, conversationId, timestamp}
### call_cancelled (DATA-ONLY — no visible notification)
{type: "call_cancelled", callerId, callerName, roomId, timestamp}

## 8. NAVIGATION ROUTES (mobile, no landing page)
/splash → /login (unauthenticated) or / (authenticated)
/login, /forgot-password, /otp-verification, /email-verification
/profile-setup, /photo-setup, /notification-permission
/ (ShellRoute with bottom nav: Discover, Connections, Messages, Tandy, Profile)
/messages/:conversationId, /messages/call-history
/calls/:roomName (full screen, no bottom nav)
/discover/profile/:userId, /discover/filters
/community/:postId
/tandy/chat
/profile/edit, /profile/photos, /profile/settings, /profile/settings/*
/user/:userId

## 9. ORIENTATION RULES
- Phones (shortest side ≤ 600dp): PORTRAIT ONLY (locked)
- Tablets/iPads (shortest side > 600dp): LANDSCAPE + PORTRAIT (both allowed)

## 10. SUBAGENT RULES
- Use /flutter-mobile-app skill for ALL presentation-layer tasks
- Read the corresponding web source file BEFORE writing Flutter code
- Every file < 400 lines — split if approaching limit
- No `dynamic` type — use typed models with fromJson/toJson
- No empty catch blocks — log with context or rethrow
- All domain entities immutable (final fields, @immutable)
- Test every mapper and repository
- Follow V2 naming: snake_case files, PascalCase classes
- Import order: dart:, package:flutter, package:third_party, package:tander/core, package:tander/features, relative
- Prefer const constructors everywhere
- Use Consumer/ConsumerWidget for Riverpod

## 11. COMPLETE WEB FILE INVENTORY (source of truth)
### Auth Module (exclude landing-page.tsx and landing/ directory)
- screens: login-page, forgot-password-page, otp-verification-page, email-verification-page, profile-setup-page, photo-setup-page, notification-permission-page

### Calls Module
- screens: call-page
- components: incoming-call-overlay
- hooks: use-call-listener, use-call-manager, use-call-setup, use-call-signal-handler, use-call-timers
- state: call-peer-state (Zustand-like singleton)
- signaling: call-signaling
- webrtc: webrtc-peer
- types: call.types

### Messaging Module
- screens: messages-page, message-thread-page, call-history-page
- components: messaging-thread-messages, messaging-thread-panel (includes voice recording via MediaRecorder), messaging-media-chips

### Tandy Module (LARGEST — 35+ components)
- screens: tandy-page, tandy-chat-page
- components/chat: structured-block-renderer, recipe-card, guide-card, sponsor-card, safety-notice-bar, emotion-indicator
- components/cooking-mode: cooking-mode-overlay, cooking-timer
- components: tandy-sidebar, tandy-composer, tandy-message-thread, tandy-empty-state, tandy-constants, tandy-mobile-bar, tandy-panel-overlay
- components (wellness): tandy-breathing-panel, tandy-breathing-panel-enhanced, tandy-meditation-panel, tandy-mood-checkin, tandy-support-panel, tandy-psychiatrist-card, tandy-psychiatrist-panel
- components (hub): tandy-features-grid, tandy-daily-insight, tandy-progress-card, tandy-welcome-card, tandy-quick-actions, tandy-primary-cta
- components (visual): tandy-constellation-bg, tandy-online-badge, tandy-icons, tandy-avatar

### Discover Module
- screens: discover-page, discover-profile-page, swipe-card
- components: discover-filters-sheet, community-tab-content (community feed within discover tab)

### Connection Module
- screens: connection-page, connection-cards

### Community Module
- screens: community-page, community-post-page, community-create-page
- components: post-card, create-post-sheet, post-detail-sheet

### Profile Module
- screens: profile-page, profile-edit-page, profile-photos-page, profile-settings-page, profile-settings-notifications-page, profile-settings-privacy-page, profile-settings-security-page, profile-settings-discovery-page, user-profile-page
- components: edit-profile-sheet, profile-hero, profile-page-components, profile-helpers, settings-sheet, settings-sheet-views, help-sheet, help-content

### Shared UI
- avatar, badge, button, glass-card, gradient-border, breathing-glow, floating-orb, stagger-entrance, slide-up-sheet, toast, confirm-modal, report-modal, message-options-sheet, page-transition, photo-lightbox, profile-view-modal, profile-view-content, warm-checkbox, skeleton-card, empty-state
## 12. TEXT SCALING & ACCESSIBILITY (BULLETPROOF for seniors)

### Problem
Filipino seniors 60+ often set their phone's text size to MAXIMUM in Settings → Accessibility.
Android: up to 2.0x text scale. iOS: up to ~3.0x with "Larger Accessibility Sizes".
The UI MUST NOT break at any text scale setting.

### Rules for EVERY widget
- NEVER use fixed heights on containers that hold text. Use minHeight + padding instead.
- NEVER set `textScaler: TextScaler.noScaling` — ALWAYS respect user's accessibility setting.
- Use `Text(maxLines: N, overflow: TextOverflow.ellipsis)` on ALL bounded text.
- Use `FittedBox(fit: BoxFit.scaleDown)` for text inside fixed-width badges/pills.
- Use `Flexible` and `Expanded` instead of fixed-size `SizedBox` for text containers.
- All font sizes in Flutter are already in logical pixels (sp equivalent) — no conversion needed.
- Use `LayoutBuilder` to adapt layout when text overflows at large scales.
- Use `MediaQuery.textScalerOf(context)` to detect current scale and adjust layouts if needed.
- Buttons: use minHeight 56px (NOT fixed height) so they grow with text.
- Cards: use padding-based sizing, not fixed height.
- Nav bar: use Flexible children, not fixed-width tabs. Icons don't scale, but labels do.
- Bottom sheets: maxHeight 92dvh, scrollable body — handles any text size.
- Toasts: maxWidth only, height grows with text.

### Testing requirements
Every screen MUST be tested at 3 text scales:
1. Default (1.0x) — matches web design
2. Large (1.5x) — common senior setting
3. Maximum (2.0x Android / 3.0x iOS) — worst case

### Specific adaptations at large scale
- If text scale > 1.5x: hide less important decorative elements (bokeh orbs, constellation bg)
- If text scale > 1.5x: stack horizontal layouts vertically (filter pills wrap instead of scroll)
- If text scale > 1.5x: reduce avatar sizes by 20% to give text more room
- Bottom nav: at 2.0x+, hide labels and show icons only (with tooltips/semantics)
- Swipe card: name/age truncate with ellipsis, interests show max 2 instead of 4
- Message bubbles: maxWidth stays at 74%, text wraps naturally
- Call controls: icons don't scale, label below can wrap to 2 lines

### Flutter implementation
```dart
// In every screen's build method, check scale:
final textScale = MediaQuery.textScalerOf(context).scale(1.0);
final isLargeText = textScale > 1.5;

// Adaptive avatar size:
final avatarSize = isLargeText ? 40.0 : 48.0;

// Adaptive max interests:
final maxInterests = isLargeText ? 2 : 4;

// Adaptive nav bar:
final showNavLabels = textScale <= 1.8;
```

### Semantic labels (screen readers)
- EVERY interactive element has `Semantics(label: ...)` or `tooltip`
- EVERY image has `semanticLabel`
- EVERY icon-only button has `Semantics(button: true, label: ...)`
- Navigation announced via `Semantics(header: true)` on page titles
- Call status changes announced via `SemanticsService.announce()`

## 13. FULLSTACK BACKEND INTEGRATION (connecting to real backend)

### Backend Connection
- API base URL configured via EnvConfig: `http://10.0.2.2:8080` (Android emulator) / `http://localhost:8080` (iOS sim)
- Production URL set via environment variable or flavor
- ALL API calls go through DioClient with interceptors — no raw http calls
- STOMP connects to `ws://{host}:8080/ws` (native WebSocket, NOT SockJS on mobile)

### Authentication Flow (end-to-end)
1. POST /api/auth/login → backend returns `Jwt-Token: Bearer {token}` HEADER (not body)
2. Strip "Bearer " prefix → store in-memory as access token
3. POST /api/auth/refresh-token with refresh token → get new access token
4. On every request: AuthInterceptor attaches `Authorization: Bearer {token}` header
5. On 401: TokenRefreshInterceptor queues requests, refreshes, retries all queued
6. On refresh failure: clear session → redirect to login
7. On logout: POST /api/notifications/unregister-token → clear tokens → disconnect STOMP → navigate to login

### Token Storage
- Access token: IN-MEMORY ONLY (never persisted — dies with app kill)
- Refresh token: FlutterSecureStorage (persists across app restarts)
- On app launch: bootstrapSession reads refresh token → calls /api/auth/refresh-token → calls /user/me → rebuilds AuthSession

### STOMP Connection (real-time)
- Connect ONLY after successful auth (access token available)
- Send Bearer token in CONNECT frame headers
- Heartbeat: 4s server/client (matches backend SpringWebSocketConfig)
- Presence heartbeat: /app/presence.heartbeat every 20s
- On disconnect: exponential backoff 1s → 30s, beforeConnect refreshes token
- On token null (logout): stop reconnect loop
- NEVER disconnect on widget unmount — global singleton

### Push Notification Registration (backend integration)
1. After login/bootstrap: request notification permission
2. Get FCM token from firebase_messaging
3. POST /api/notifications/register-token {deviceToken, platform: "android"/"ios", deviceId: unique device ID}
4. On token refresh: re-register with new token
5. On logout: POST /api/notifications/unregister-token {deviceToken}
6. iOS only: get VoIP token → POST /api/notifications/register-voip-token {voipToken, deviceId}

### API Error Handling (bulletproof)
- Network error (no internet): show OfflineBanner, queue retry on reconnect
- 400 Bad Request: show validation error from response body
- 401 Unauthorized: auto-refresh token, retry. If refresh fails → login
- 403 Forbidden: show "Access denied" toast
- 404 Not Found: show appropriate empty state
- 409 Conflict: handle multi-device conflicts (e.g., call already answered)
- 429 Rate Limited: show "Please wait" toast with retry-after
- 500+ Server Error: show "Something went wrong, try again" toast with retry button
- Timeout (15s): show "Connection slow, retrying..." toast

### STOMP Error Handling
- STOMP CONNECT failure: retry with backoff, show connection status indicator
- Subscription failure: log and retry on next connect
- Message send failure: queue message, retry when connected
- Stale subscription: resubscribeAll on reconnect

### WebRTC Error Handling
- Camera/mic denied: show permission dialog, fallback to audio-only for video calls
- ICE connection failed: show "Reconnecting..." overlay, attempt ICE restart
- Peer connection closed: cleanup, show "Call ended" with reason
- No remote stream after 30s: timeout, end call with "failed" reason

### Data Validation
- ALL API responses validated against DTO types (json_serializable)
- Null fields handled with defaults (never crash on missing field)
- JSON string arrays parsed safely (interests, languages from /user/me)
- Date strings parsed with tryParse (never throw on malformed date)
- Pagination: handle empty pages, last page detection

### Offline Behavior
- Profile data cached locally (SharedPreferences) for instant display
- Messages show cached conversations, mark "waiting to sync" on send failure
- Discovery shows "No internet" empty state
- Call button disabled when offline (check connectivity before initiating)
- Settings changes queued, synced when online

### Environment Flavors
```dart
// lib/core/config/env_config.dart
enum AppEnvironment { dev, staging, production }

class EnvConfig {
  static late AppEnvironment current;

  static String get apiBaseUrl => switch (current) {
    AppEnvironment.dev => 'http://10.0.2.2:8080',      // Android emulator
    AppEnvironment.staging => 'https://staging-api.tander.app',
    AppEnvironment.production => 'https://api.tander.app',
  };

  static String get wsUrl => switch (current) {
    AppEnvironment.dev => 'ws://10.0.2.2:8080/ws',
    AppEnvironment.staging => 'wss://staging-api.tander.app/ws',
    AppEnvironment.production => 'wss://api.tander.app/ws',
  };
}
```

## 14. PIXEL-PERFECT UI SPECS (exact values from web source)

### App Shell / Bottom Nav
- Nav resting height: 76px, scrolled: 62px, max-width scrolled: 1200px
- Glass bg: rgba(255,252,248,0.78), blur(64px) saturate(220%) brightness(1.04)
- Glass border: 1px solid rgba(255,255,255,0.84)
- Glass shadow: inset 0 1.5px 0 rgba(255,255,255,1), inset 0 -1px 0 rgba(0,0,0,0.04), 0 18px 60px rgba(230,126,34,0.14), 0 4px 16px rgba(0,0,0,0.07)
- Active pill: gradient(158deg, #F07020, #DF5C08), radius 16px 13px 14px 15px / 15px 16px 13px 14px
- Active pill shadow: 0 4px 22px rgba(224,92,8,0.44), 0 1px 4px rgba(224,92,8,0.20)
- Active pill bloom: radial-gradient(ellipse 78% 68% at 50% 88%, rgba(240,112,32,0.30), transparent 70%) blur(12px)
- Tab: h48px, px18, radius 14px, icon 24×24, gap 9px
- Pill spring: stiffness 420, damping 38. Icon spring: stiffness 480, damping 22
- Tab stagger: 0.055 per child, 0.14 initial delay
- Logo icon: 38×38px, shadow 0 4px 20px rgba(230,126,34,0.34), ring 3px rgba(255,255,255,0.85)
- Wordmark: font-chancery 1.45rem, gradient text #E67E22→#0F9D94→#E67E22 200% sweep 8s
- Tandy pulse: 3.4s ease-out, shadow 0→8px rgba(15,157,148,0.54→0)
- Badge: min-w 17px, h 17px, px 3px, font 9px, gradient(135deg, #E8650A, #C9510A), border 1.5px white
- 3 bokeh orbs: orange 200×110 blur(32px), teal 150×85 blur(26px), gold 130×75 blur(24px)

### Swipe Card (Discover)
- Card radius: 32px, shadow-xl
- Swipe threshold: 100px distance OR 600px/s velocity
- Drag elastic: 0.18, rotation: ±18° mapped from x[-250,250]
- Hint wiggle on mount: x [0,22,-22,0] over 0.85s, delay 900ms
- Entry spring: stiffness 380, damping 28. Reset spring: stiffness 500, damping 32
- Swipe out: ease [0.32,0,0.67,0] 0.38s, exit distance: window.innerWidth + 300
- Photo indicators: top-4 inset-x-4, bar h5px radius-full, active rgba(255,255,255,0.96), inactive rgba(255,255,255,0.36)
- LIKE stamp: top-14 left-5, 3px #2E8B57 border, bg rgba(46,139,87,0.14), rotate(-20deg), text "LIKE" text-lg font-black tracking-[0.18em], opacity from x[25,120]→[0,1]
- NOPE stamp: top-14 right-5, 3px #C0392B border, bg rgba(192,57,43,0.14), rotate(20deg), text "NOPE", opacity from x[-25,-120]→[0,1]
- Bottom gradient: linear-gradient(to top, rgba(8,3,1,0.95) 0%, rgba(8,3,1,0.70) 35%, rgba(8,3,1,0.28) 60%, transparent)
- Name: font-display text-[2.1rem] bold white. Age: text-[1.55rem] light white/78
- Interest chips: px-3 py-1 radius-full text-xs bold, bg rgba(255,255,255,0.16), border rgba(255,255,255,0.26), blur(6px), max 4 shown
- View profile btn: h44px px-5 radius-full text-sm bold white, bg rgba(255,255,255,0.16), border 1.5px rgba(255,255,255,0.32)

### Messages Page
- Container: h calc(100dvh - 84px), bg gradient(180deg, #F5ECE2, #EDE1D2)
- Sidebar: w392px, radius 24px, bg gradient(rgba(255,253,249,0.97)→rgba(255,248,240,0.97)), border rgba(220,206,188,0.85), shadow 0 8px 32px rgba(118,79,33,0.08)
- "Messages" label: #904C18, 10.5px, 700, tracking 0.08em, uppercase
- "Your Chats": font-display 800 22px #1F2937 tracking -0.04em
- Search: h44px, radius 14px, bg rgba(255,255,255,0.70), border rgba(232,226,216,0.80), font 14px
- Filter tabs: radius-full, active bg #E67E22 white shadow 0 6px 16px #E67E2230, inactive bg rgba(255,255,255,0.60) #7C6E60
- Conversation row: min-h 68px, px 14px, py 12px, radius 16px, active border-left 3px #E67E22
- Avatar: 48px with unread ring gradient(135deg, #E67E22, #F7B23C) + pulse 2.6s
- Name: 15.5px, 800 unread / 600 read, #1A1209. Preview: 13.5px, 600/400, #3A2A1A/#7A6E62
- Unread badge: min-w 24px h24px, gradient(135deg, #E67E22, #F59E0B), font 12px 800
- Row entrance: translateY(6px)→0 over 300ms ease(0.22,1,0.36,1), stagger 40ms

### Message Thread & Composer
- Thread bg: #F8F1E6 with radial gradients + crosshatch pattern 24px
- Header: bg rgba(255,252,247,0.97), border-bottom rgba(221,211,194,0.70), blur(28px)
- Avatar in header: 40px, online dot 10px #22C55E border 2px #FFFBF5
- Name: 15px 800 #18110A. Status: 11.5px, typing #0F9D94, online #16803C, offline #8D8072
- Call buttons: 38×38px radius 12px, phone #E67E22, video #0F9D94
- Composer outer: radius 24px, bg rgba(255,253,250,0.98), border 1.5px rgba(221,211,194,0.80)
- Composer focus: border #E67E2260, shadow 0 22px 50px #E67E2212
- Textarea: font 16px, line-height 1.6, min-h 28px, max-h 120px
- Send btn: 44×44px radius 16px, gradient(145deg, #E67E22, #D06A18), shadow 0 6px 20px #E67E2230
- Voice btn: 44×44px radius 16px, bg rgba(15,157,148,0.08), color #0F9D94
- Recording: red dot 8px pulse 1.1s, waveform bars w2.5px radius 2px, time 15px 700
- Voice send: 44×44px radius 16px, gradient(145deg, #22C55E, #16A34A)
- Photo preview: 72×72px radius 14px
- Image attach btn: 40×40px radius 14px, bg rgba(15,157,148,0.08)
- User bubble animation: translateY(6px) translateX(6px)→none 220ms
- Tandy bubble animation: translateY(6px) translateX(-6px)→none 220ms
- Typing dots: 3 dots, gap 6px, bounce translateY(0→-4px) staggered 180ms

### Call Page
- Background: gradient(160deg, #1A0800 0%, #0D0A06 40%, #06100E 100%)
- PiP video: top-16 right-4, 112×144px (w-28 h-36), radius-2xl, border-2 white/20
- Audio avatar: 112×112px, border 3px rgba(255,255,255,0.12), shadow 0 8px 32px rgba(0,0,0,0.40)
- Avatar spring: stiffness 260, damping 22, initial scale 0.85
- Pulse ring: -inset-4, 2px rgba(230,126,34,0.30), scale 1→1.15 opacity 0.25→0.08 over 2.5s
- Connected glow: -inset-3, 2px green-400/30, shadow 0→20px rgba(230,126,34,0.3→0) over 3s
- Controls gradient: linear-gradient(to top, rgba(0,0,0,0.50), transparent)
- Mute/Camera: 56×56px radius-full, muted bg-white text-black, unmuted bg-white/15 text-white
- End call: 64×64px radius-full, bg-red-600, shadow 0 4px 24px rgba(220,38,38,0.35)
- Name: font-display bold clamp(1.25rem,3vw,1.75rem) white
- Status: white/50 sm tabular-nums

### Incoming Call Overlay
- Card: fixed top-6 right-6, z-300, w360px
- Spring: stiffness 340, damping 28, initial y-30 scale 0.92
- Card bg: gradient(145deg, #1A0800, #0D1B2A), radius 20px
- Shadow: 0 24px 80px rgba(0,0,0,0.45), 0 8px 24px rgba(0,0,0,0.25), 0 0 0 1px rgba(255,255,255,0.08)
- Avatar: 52×52px, border 2px white/15, pulse ring 2.2s scale(1→1.6) opacity(1→0)
- Name: 17px bold white. Status: 13px white/45
- Accept: flex-1 h48px radius 14px bg-green-600 white bold 14px, shadow 0 4px 16px rgba(22,163,74,0.35)
- Decline: flex-1 h48px radius 14px bg red-600/20 red-400 bold 14px
- Ringtone: 440Hz sine, gain 0.12, 0.4s tone every 2.5s

### Tandy Chat Bubbles
- User: gradient(135deg, #F7B23C→#EE8B23→#DB6F18), white text, padding 13px 18px
- User radius: start 28/14/28/28, mid 12/14/12/28, end 12/14/28/28
- User shadow: 0 14px 28px rgba(230,126,34,0.26), inset 0 1px 0 rgba(255,255,255,0.20)
- User max-width: 74%
- Tandy: gradient(180deg, rgba(239,251,249,0.98)→rgba(255,255,255,0.97)), border 1.5px rgba(15,157,148,0.16)
- Tandy radius: start 14/28/28/12, mid 14/12/28/12, end 14/28/28/12
- Tandy shadow: 0 14px 32px rgba(15,157,148,0.10), 0 2px 12px rgba(0,0,0,0.04)
- Tandy max-width: 88% with blocks, 74% text-only
- Send btn: 48×48px radius 18px, enabled gradient(135deg, #F6B137, #E67E22) shadow 0 10px 26px rgba(230,126,34,0.38)

### Breathing Panel (4-7-8)
- Phases: inhale 4s #E67E22, hold 7s #7C3AED, exhale 8s #0F9D94, rest 2s #2E8B57
- Total: 21s × 4 cycles = 84s session
- Orb scale: idle 1.0, inhale 1.0→1.24, hold 1.24 gentle bob, exhale 1.24→0.98, rest 0.98→1.0
- Stars: 24 nodes at 3 layers, color transitions per phase
- Ripple: scale 0.4→2.8 opacity 0.65→0

### Profile Hero
- Avatar: 96×96 mobile / 112×112 desktop, border 3.5px/4px
- Online dot: 14×14 mobile / 16×16 desktop, border 2.5px card
- Cover banner: h140 mobile / h180 desktop
- Completion ring: SVG stroke animated
- Tier badge: radius-full, complete bg-success/80, incomplete bg-black/40, text 11px bold
- Photo change btn: 32×32 / 36×36, radius-full, bg white/12 border white/25

### Connection Page
- Tab bar: radius 18px, border border, bg subtle, p-1.5, gap 0.5
- Tab btn: min-h 44px, px-5, py-2, radius 12px, font 14px 600
- Active pill: gradient(135deg, #F07020, #E67E22), shadow 0 3px 12px rgba(230,126,34,0.35)
- Active spring: stiffness 420, damping 32
- Stats pills: radius-full, pending primary/8 border primary/20, friends secondary/8 border secondary/20
- Panel motion: enter y8→0 0.18s, exit y0→-5 0.12s
- Card stagger: delay i×0.045 duration 0.22 ease [0.16,1,0.3,1]

### Shared Components
- SlideUpSheet: max-h 92dvh, w-full sm:max-w-lg, radius-t-2xl sm:radius-2xl, backdrop black/40 blur(2px)
- Sheet header: px-5 py-4, border-b, close btn 36×36 radius-full
- Toast: fixed bottom-6 right-6, max-w-sm, radius-xl, 4 variants (success/error/warning/info)
- Toast durations: success 4s, error 5.5s, warning 4.5s, info 4s, max stack 3
- Toast progress bar: h-0.5 origin-left linear countdown
- PhotoLightbox: fixed inset-0 z-120, bg-black, nav arrows 44×44 radius-full bg-white/10
- Dots: active w-5 h-2 white, inactive w-2 h-2 white/40, swipe threshold 50px

## 15. FLUTTER ↔ WEB MAPPING REFERENCE
- Framer Motion spring → Flutter SpringSimulation or physics_model
- Framer Motion animate/initial/exit → Flutter AnimatedContainer / flutter_animate
- Tailwind class → Flutter equivalent:
  - rounded-full → BorderRadius.circular(999)
  - backdrop-blur-[Npx] → BackdropFilter(filter: ImageFilter.blur(sigmaX: N, sigmaY: N))
  - shadow-xl → BoxShadow(blurRadius: 25, spreadRadius: -5, offset: Offset(0, 20))
  - bg-gradient-to-r → LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight)
  - clamp(min, preferred, max) → Use LayoutBuilder or MediaQuery
  - animate-* → AnimationController + CurvedAnimation or flutter_animate
  - tabular-nums → FontFeature.tabularFigures()
- cubic-bezier(0.22, 1.00, 0.36, 1.00) → Cubic(0.22, 1.00, 0.36, 1.00) in Flutter
- useTransform(input, [inMin,inMax], [outMin,outMax]) → lerpDouble or custom map function
- position: fixed → Use Stack with Positioned or Overlay
- z-index → Stack order (last child on top) or Overlay
- dvh → Use MediaQuery.of(context).size.height
- inset-0 → Positioned.fill()
- gap → MainAxisSpacing/CrossAxisSpacing or SizedBox between children
- grid-cols-N → GridView.count(crossAxisCount: N)
- flex-shrink-0 → Flexible(fit: FlexFit.tight) or SizedBox with fixed size
- overflow-hidden → ClipRRect or ClipRect
- line-clamp-N → Text(maxLines: N, overflow: TextOverflow.ellipsis)
- @media (prefers-reduced-motion) → MediaQuery.of(context).disableAnimations
