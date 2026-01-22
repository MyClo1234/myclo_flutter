import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import 'api_provider.dart';

class WardrobeNotifier extends AsyncNotifier<List<Item>> {
  static const String _cacheKey = 'wardrobe_cache';

  @override
  Future<List<Item>> build() async {
    // 1. Try to load from cache first for instant display
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);

    if (cachedData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final items = jsonList.map((json) => Item.fromJson(json)).toList();

        // 2. Trigger background refresh to get latest data
        _fetchAndSave(prefs);

        return items;
      } catch (e) {
        // If cache is corrupted, just fetch from API
      }
    }

    // 3. If no cache, fetch from API directly
    final prefsInstance = await SharedPreferences.getInstance();
    return _fetchAndSave(prefsInstance);
  }

  Future<List<Item>> _fetchAndSave(SharedPreferences prefs) async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.fetchWardrobeItems();

      if (data['items'] != null) {
        final List<dynamic> itemsJson = data['items'];

        // Save to cache
        await prefs.setString(_cacheKey, jsonEncode(itemsJson));

        final items = itemsJson.map((json) => Item.fromJson(json)).toList();

        // If we are already displaying cached data, we need to explicitly update state
        // to show the fresh data
        state = AsyncValue.data(items);

        return items;
      }
    } catch (e) {
      // If API fails and we have no cache (handled in build), error will propagate
      // If we have cache, we might want to silently fail or show snackbar
      // For now, let's just let the error happen if this was the primary fetch
      if (state.value == null) rethrow; // Rethrow if we have nothing to show
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    state = await AsyncValue.guard(() => _fetchAndSave(prefs));
  }
}

final wardrobeProvider = AsyncNotifierProvider<WardrobeNotifier, List<Item>>(
  () {
    return WardrobeNotifier();
  },
);
