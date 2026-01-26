import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/api_service.dart';

class LocalWeatherState {
  final DailyWeather? weather;
  final String? cityName;
  final double? lat;
  final double? lon;

  LocalWeatherState({this.weather, this.cityName, this.lat, this.lon});
}

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, AsyncValue<LocalWeatherState>>((
      ref,
    ) {
      return WeatherNotifier();
    });

class WeatherNotifier extends StateNotifier<AsyncValue<LocalWeatherState>> {
  WeatherNotifier() : super(const AsyncValue.loading()) {
    fetchWeather();
  }

  final ApiService _apiService = ApiService();

  Future<void> fetchWeather() async {
    try {
      state = const AsyncValue.loading();

      // 1. Get current position
      Position position = await _determinePosition();

      // 2. Call API with Lat/Lon directly
      // Backend will map to nearest region and return weather data
      final weather = await _apiService.getDailyWeather(
        position.latitude,
        position.longitude,
      );

      // We can use the 'message' field or add a 'region' field to DailyWeather to show city name
      // For now, let's assume the backend might return the region name in the message query or separate field.
      // If we looked at the backend logic, get_nearest_region returns a name.
      // But DailyWeather model in Flutter doesn't have 'region' field yet possibly.
      // Let's check DailyWeather model. If it doesn't have region, we might need to add it or infer it.
      // For now, we'll leave cityName null or set it to a placeholder until we update the model.
      // Actually, let's update proper state.

      state = AsyncValue.data(
        LocalWeatherState(
          weather: weather,
          cityName: weather.region ?? weather.message,
          lat: position.latitude,
          lon: position.longitude,
        ),
      );
    } catch (e, st) {
      // Fallback to Seoul if location/API fails (common in Web/Simulator)
      try {
        final weather = await _apiService.getDailyWeather(37.5665, 126.9780);
        state = AsyncValue.data(
          LocalWeatherState(weather: weather, cityName: 'Seoul (Default)'),
        );
      } catch (fallbackError) {
        String errorMsg = e.toString();
        if (errorMsg.contains('kCLErrorLocationUnknown')) {
          if (kIsWeb) {
            errorMsg =
                'Mac 크롬 위치 오류:\n1. Wi-Fi가 켜져 있는지 확인해주세요.\n2. 시스템 설정 > 개인정보 보호 > 위치 서비스 > Chrome 권한 허용\n3. 브라우저 주소창 왼쪽 설정 > 위치 허용';
          } else {
            const suggestion =
                'iOS Simulator Error Detected:\nGo to Simulator Menu -> Features -> Location -> Select "Apple" or "Custom Location".\nEnsure the simulator has a valid location set.';
            debugPrint(suggestion); // Helpful log for developer
            errorMsg =
                'iOS 시뮬레이터의 위치 설정을 확인해주세요.\n(Features > Location > Custom Location)';
          }
        }
        state = AsyncValue.error(errorMsg, st);
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Use lower accuracy for faster city-level resolution
    // This often helps with simulator/web compatibility
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 1000,
      ),
    );
  }
}

// Icon Helper
IconData getWeatherIcon(int rainType) {
  // rainType: 0=Sunny, 1=Rain, 2=Rain/Snow, 3=Snow, 4=Shower
  switch (rainType) {
    case 0:
      return LucideIcons.sun;
    case 1:
    case 4:
      return LucideIcons.cloudRain;
    case 2:
    case 3:
      return LucideIcons.snowflake;
    default: // 맑음 or unknown
      return LucideIcons.cloudSun;
  }
}

String getWeatherDescription(int rainType) {
  switch (rainType) {
    case 0:
      return 'Sunny day';
    case 1:
    case 4:
      return 'Rainy day';
    case 2:
    case 3:
      return 'Snowy day';
    default:
      return 'Cloudy day';
  }
}
