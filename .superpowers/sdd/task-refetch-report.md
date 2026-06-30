# Refetch-on-Navigation — Implementation Report

## Per-Tab Summary

| Tab | Screen file | Refresh method | Widget conversion needed |
|-----|-------------|---------------|--------------------------|
| Connect | `lib/features/connection/presentation/screens/connection_screen.dart` | `loadAll()` | No (already ConsumerStatefulWidget) |
| Discover | `lib/features/discover/presentation/screens/discover_screen.dart` | `loadProfiles()` | No (already ConsumerStatefulWidget) |
| Community | Same as Discover (mounted together) | `refreshFeed()` | No — added to same initState as Discover |
| Chat | `lib/features/messaging/presentation/screens/messages_screen.dart` | `loadConversations()` | No (already ConsumerStatefulWidget) |
| Tandy | `lib/features/tandy/presentation/screens/tandy_screen.dart` | `loadConversation()` | No (already ConsumerStatefulWidget) |
| Profile | `lib/features/profile/presentation/screens/profile_screen.dart` | `fetchProfile()` | No — already wired; added `if (!mounted) return` guard |

## Pattern Applied

Each screen received `initState` with a post-frame, `mounted`-guarded call:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    ref.read(<provider>.notifier).<refreshMethod>();
  });
}
```

Profile screen already had the `initState` — only the `mounted` guard was missing.

## Files Changed

- `lib/features/connection/presentation/screens/connection_screen.dart` — added initState
- `lib/features/discover/presentation/screens/discover_screen.dart` — added initState, added `community_feed_notifier` import
- `lib/features/messaging/presentation/screens/messages_screen.dart` — added initState + import
- `lib/features/tandy/presentation/screens/tandy_screen.dart` — added initState
- `lib/features/profile/presentation/screens/profile_screen.dart` — added `mounted` guard

## Test

- **New**: `test/features/connection/presentation/screens/connection_screen_refetch_test.dart`
  - Overrides `connectionRepositoryProvider` with a fake that records `fetchIncomingRequests` calls (proxy for `loadAll`)
  - Overrides `sessionManagerProvider` with a minimal instance (session=null → STOMP subscription skipped)
  - Asserts `fetchCallCount == 2`: one from notifier `build()` auto-fetch, one from screen `initState`
  - **Note**: `ConnectionNotifier` is `final`; subclassing is not possible, so spy is done via repository layer
  - **Passes**: `+1 All tests passed`
- **Suite**: `test/features/auth/` + `test/features/connection/` → `+44 All tests passed`

## Commands & Output

```
flutter analyze lib/features/connection lib/features/discover lib/features/community lib/features/messaging lib/features/tandy lib/features/profile
→ No issues found! (ran in 7.5s)

flutter test test/features/auth/ test/features/connection/ --reporter compact
→ 00:07 +44: All tests passed!
```

## Concerns

- **Discover**: `loadProfiles()` resets state to `DiscoverLoading` on each navigation, causing a brief skeleton. This is acceptable (the stale error is worse), but if swipe position is precious in future, switch to `ref.invalidate(discoverNotifierProvider)` which calls `build()` + `loadProfiles()` fresh.
- **Chat**: `loadConversations()` was chosen over `refreshSilently()` because pull-to-refresh also uses it, and it correctly transitions out of `ConversationsError` state (unlike `refreshSilently` which swallows errors).
- **Profile**: The pre-existing `initState` was already correct; only the `mounted` guard was missing. No duplicate calls added.
- **Pre-existing flaky test**: `connection_repository_impl_test.dart: maps a 404 to Failure(NotFoundException)` occasionally fails (Dio error log noise); unrelated to this change.
