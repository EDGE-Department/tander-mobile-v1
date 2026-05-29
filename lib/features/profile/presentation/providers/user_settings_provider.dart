import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/profile/presentation/providers/profile_providers.dart';

/// Manages the user's settings state.
final userSettingsProvider =
    AsyncNotifierProvider<UserSettingsNotifier, UserSettings>(
      UserSettingsNotifier.new,
    );

class UserSettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    final result = await repository.fetchUserSettings();

    return switch (result) {
      Success(value: final settings) => settings,
      Failure(exception: final exception) => throw exception,
    };
  }

  /// Updates settings and optimistically updates the local state.
  Future<void> updateSettings(UpdateSettingsRequestDto request) async {
    // Keep a reference to the old state in case we need to roll back.
    final previousState = state;

    // Optimistically update the state.
    state = AsyncData(_applyUpdates(state.requireValue, request));

    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.updateUserSettings(request: request);

    if (result is Failure) {
      // Rollback on failure.
      state = previousState;
      throw result.exception;
    }
  }

  /// Helper to apply a patch request to the current settings object.
  UserSettings _applyUpdates(
    UserSettings current,
    UpdateSettingsRequestDto request,
  ) {
    return UserSettings(
      showOnline: request.showOnline ?? current.showOnline,
      showLastSeen: request.showLastSeen ?? current.showLastSeen,
      showProfileViews: request.showProfileViews ?? current.showProfileViews,
      showAge: request.showAge ?? current.showAge,
      readReceipts: request.readReceipts ?? current.readReceipts,
      profileVisibility: request.profileVisibility ?? current.profileVisibility,
      discoveryVisible: request.discoveryVisible ?? current.discoveryVisible,
      discoveryMinAge: request.discoveryMinAge ?? current.discoveryMinAge,
      discoveryMaxAge: request.discoveryMaxAge ?? current.discoveryMaxAge,
      discoveryMaxDistanceKm:
          request.discoveryMaxDistanceKm ?? current.discoveryMaxDistanceKm,
      notifyMessages: request.notifyMessages ?? current.notifyMessages,
      notifyMatches: request.notifyMatches ?? current.notifyMatches,
      notifyProfileViews:
          request.notifyProfileViews ?? current.notifyProfileViews,
      notifyCommunity: request.notifyCommunity ?? current.notifyCommunity,
      notifyTandy: request.notifyTandy ?? current.notifyTandy,
      notifyCalls: request.notifyCalls ?? current.notifyCalls,
      quietHoursStart: (request.quietHoursStartSet ?? false)
          ? request.quietHoursStart
          : current.quietHoursStart,
      quietHoursEnd: (request.quietHoursEndSet ?? false)
          ? request.quietHoursEnd
          : current.quietHoursEnd,
      twoFactorEnabled: request.twoFactorEnabled ?? current.twoFactorEnabled,
      consentMarketing: request.consentMarketing ?? current.consentMarketing,
      consentAdPersonalization:
          request.consentAdPersonalization ?? current.consentAdPersonalization,
      consentTandyMemory:
          request.consentTandyMemory ?? current.consentTandyMemory,
      familyAlertContactPhone: current.familyAlertContactPhone,
      familyAlertContactLabel: current.familyAlertContactLabel,
    );
  }
}
