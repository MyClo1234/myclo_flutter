import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class WardrobeNotifier extends AsyncNotifier<List<Item>> {
  static const String _cacheKey = 'wardrobe_cache';

  // Pagination State
  int _currentSkip = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<Item>> build() async {
    // 0. Wait for authentication
    final authState = ref.watch(authProvider);

    // If not authenticated or still loading auth state, return empty or wait
    if (!authState.isAuthenticated) {
      return [];
    }

    _currentSkip = 0;
    _hasMore = true;
    _isLoadingMore = false;

    // 1. Try to load from cache first for instant display (only first page usually)
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);

    if (cachedData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final items = jsonList.map((json) => Item.fromJson(json)).toList();

        // 2. Trigger background refresh to get latest data (first page)
        _fetchFirstPage(prefs);

        return items;
      } catch (e) {
        // If cache is corrupted, just fetch from API
      }
    }

    // 3. If no cache, fetch from API directly
    return _fetchFirstPage(prefs);
  }

  Future<List<Item>> _fetchFirstPage(SharedPreferences prefs) async {
    try {
      final api = ref.read(apiServiceProvider);
      // Reset pagination
      _currentSkip = 0;
      _hasMore = true;

      final data = await api.fetchWardrobeItems(skip: 0, limit: _limit);

      if (data['items'] != null) {
        final List<dynamic> itemsJson = data['items'];
        final items = itemsJson.map((json) => Item.fromJson(json)).toList();

        // Update pagination meta
        _hasMore = data['has_more'] ?? false;
        if (items.isNotEmpty) {
          _currentSkip = items.length;
        }

        // Cache first page only
        await prefs.setString(_cacheKey, jsonEncode(itemsJson));

        state = AsyncValue.data(items);
        return items;
      }
    } catch (e) {
      if (state.value == null) rethrow;
    }
    return [];
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    // Notify listeners if needed, or rely on UI to show spinner based on getter
    // Since AsyncNotifier doesn't notify on property change readily without state change,
    // we assume UI checks the provider state or we use a separate provider for loading status.
    // simpler: append to state.

    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.fetchWardrobeItems(
        skip: _currentSkip,
        limit: _limit,
      );

      if (data['items'] != null) {
        final List<dynamic> itemsJson = data['items'];
        final newItems = itemsJson.map((json) => Item.fromJson(json)).toList();

        _hasMore = data['has_more'] ?? false;

        if (newItems.isNotEmpty) {
          _currentSkip += newItems.length;

          // Append to current state
          final currentItems = state.value ?? [];
          state = AsyncValue.data([...currentItems, ...newItems]);
        }
      }
    } catch (e) {
      print("Load more failed: $e");
      // Optionally set error state or show snackbar via a side-effect
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    // Reset Everything
    _currentSkip = 0;
    _hasMore = true;
    _isLoadingMore = false;
    state = await AsyncValue.guard(() => _fetchFirstPage(prefs));
  }
}

final wardrobeProvider = AsyncNotifierProvider<WardrobeNotifier, List<Item>>(
  () {
    return WardrobeNotifier();
  },
);
