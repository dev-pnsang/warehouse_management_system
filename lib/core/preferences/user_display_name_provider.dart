import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

const _keyDisplayName = 'user_display_name';

final userDisplayNameProvider = StateNotifierProvider<UserDisplayNameNotifier, AsyncValue<String>>((ref) {
  return UserDisplayNameNotifier();
});

class UserDisplayNameNotifier extends StateNotifier<AsyncValue<String>> {
  UserDisplayNameNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = AsyncValue.data(
        prefs.getString(_keyDisplayName) ?? AppConstants.defaultUserName,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    final value = trimmed.isEmpty ? AppConstants.defaultUserName : trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, value);
    state = AsyncValue.data(value);
  }

  Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName) ?? AppConstants.defaultUserName;
  }
}

/// Synchronous display name for UI: use when [userDisplayNameProvider] is already loaded.
String displayNameOrDefault(AsyncValue<String> state) {
  return state.when(
    data: (v) => v,
    loading: () => AppConstants.defaultUserName,
    error: (_, __) => AppConstants.defaultUserName,
  );
}
