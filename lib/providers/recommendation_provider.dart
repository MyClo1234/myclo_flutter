import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_provider.dart';

import '../models/todays_pick.dart'; // Add import
import 'weather_provider.dart'; // Add import

class RecommendationNotifier extends AsyncNotifier<TodaysPick?> {
  @override
  Future<TodaysPick?> build() async {
    // Wait for weather to get location
    final weatherState = ref.watch(weatherProvider);

    // If we have location, fetch today's pick
    if (weatherState.value?.lat != null && weatherState.value?.lon != null) {
      return _fetchTodaysPick(
        weatherState.value!.lat!,
        weatherState.value!.lon!,
      );
    }

    // Or return null/loading until location is ready
    return null;
  }

  Future<TodaysPick?> _fetchTodaysPick(double lat, double lon) async {
    final api = ref.read(apiServiceProvider);
    try {
      final data = await api.fetchTodaysPick(lat: lat, lon: lon);
      return TodaysPick.fromJson(data);
    } catch (e) {
      // Handle error or return null
      print("Error fetching Todays Pick: $e");
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    // We rely on weather provider triggering rebuild or we manually re-fetch if we have location
    final weatherState = ref.read(weatherProvider).value;
    if (weatherState?.lat != null && weatherState?.lon != null) {
      state = await AsyncValue.guard(
        () => _fetchTodaysPick(weatherState!.lat!, weatherState.lon!),
      );
    }
  }
}

final recommendationProvider =
    AsyncNotifierProvider<RecommendationNotifier, TodaysPick?>(() {
      return RecommendationNotifier();
    });
