import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Provides a stable device ID that persists across app restarts.
/// Used for rate limiting and device identification.
class DeviceIdService {
  DeviceIdService(this._prefs);

  final SharedPreferences _prefs;
  static const String _deviceIdKey = 'tander_device_id';

  /// Returns the device ID, creating one if it doesn't exist.
  String getDeviceId() {
    final existingId = _prefs.getString(_deviceIdKey);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final newDeviceId = const Uuid().v4();
    _prefs.setString(_deviceIdKey, newDeviceId);
    return newDeviceId;
  }
}
