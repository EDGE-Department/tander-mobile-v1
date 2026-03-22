import 'package:shared_preferences/shared_preferences.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

/// Wraps [SharedPreferences] for non-sensitive cached data.
///
/// All write operations return [Result<void>] so callers can react to
/// storage failures without unhandled exceptions. Read operations that
/// hit [SharedPreferences] synchronous getters also return [Result] to
/// keep the error-handling strategy uniform.
final class LocalStorage {
  const LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  // ---------------------------------------------------------------------------
  // User cache
  // ---------------------------------------------------------------------------

  static const String _cachedUserJsonKey = 'cached_user_json';

  Future<Result<void>> cacheUserJson(String userJson) async {
    try {
      await _prefs.setString(_cachedUserJsonKey, userJson);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to cache user JSON: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Result<String?> getCachedUserJson() {
    try {
      return Success(_prefs.getString(_cachedUserJsonKey));
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to read cached user JSON: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> clearCachedUser() async {
    try {
      await _prefs.remove(_cachedUserJsonKey);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to clear cached user: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Generic string helpers
  // ---------------------------------------------------------------------------

  Future<Result<void>> saveString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to write string "$key": $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Result<String?> getString(String key) {
    try {
      return Success(_prefs.getString(key));
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to read string "$key": $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Generic bool helpers
  // ---------------------------------------------------------------------------

  Future<Result<void>> saveBool(String key, {required bool value}) async {
    try {
      await _prefs.setBool(key, value);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to write bool "$key": $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Result<bool?> getBool(String key) {
    try {
      return Success(_prefs.getBool(key));
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to read bool "$key": $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Generic int helpers
  // ---------------------------------------------------------------------------

  Future<Result<void>> saveInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to write int "$key": $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Result<int?> getInt(String key) {
    try {
      return Success(_prefs.getInt(key));
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to read int "$key": $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Removal & clearing
  // ---------------------------------------------------------------------------

  Future<Result<void>> remove(String key) async {
    try {
      await _prefs.remove(key);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to remove key "$key": $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> clearAll() async {
    try {
      await _prefs.clear();
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to clear local storage: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
