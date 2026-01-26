import 'outfit.dart';

class TodaysPick {
  final bool success;
  final String weatherSummary;
  final double tempMin;
  final double tempMax;
  final Outfit? outfit;
  final String? message;

  TodaysPick({
    required this.success,
    required this.weatherSummary,
    required this.tempMin,
    required this.tempMax,
    this.outfit,
    this.message,
  });

  factory TodaysPick.fromJson(Map<String, dynamic> json) {
    return TodaysPick(
      success: json['success'] ?? false,
      weatherSummary: json['weather_summary'] ?? '',
      tempMin: (json['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (json['temp_max'] as num?)?.toDouble() ?? 0.0,
      outfit: json['outfit'] != null ? Outfit.fromJson(json['outfit']) : null,
      message: json['message'],
    );
  }
}
