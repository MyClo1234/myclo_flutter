import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outfit.dart';
import 'api_provider.dart';

class RecommendationNotifier extends AsyncNotifier<Outfit?> {
  @override
  Future<Outfit?> build() async {
    return _fetchOutfit();
  }

  Future<Outfit?> _fetchOutfit() async {
    final api = ref.read(apiServiceProvider);
    final data = await api.fetchRecommendedOutfit();

    if (data['outfits'] != null && (data['outfits'] as List).isNotEmpty) {
      return Outfit.fromJson(data['outfits'][0]);
    }
    return null;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOutfit());
  }
}

final recommendationProvider =
    AsyncNotifierProvider<RecommendationNotifier, Outfit?>(() {
      return RecommendationNotifier();
    });
