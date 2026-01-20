import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import 'api_provider.dart';

class WardrobeNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    return _fetchItems();
  }

  Future<List<Item>> _fetchItems() async {
    final api = ref.read(apiServiceProvider);
    final data = await api.fetchWardrobeItems();

    if (data['items'] != null) {
      return (data['items'] as List)
          .map((json) => Item.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchItems());
  }
}

final wardrobeProvider = AsyncNotifierProvider<WardrobeNotifier, List<Item>>(
  () {
    return WardrobeNotifier();
  },
);
