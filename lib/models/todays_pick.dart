import 'outfit.dart';

class TodaysPick {
  final bool success;
  final String weatherSummary;
  final double tempMin;
  final double tempMax;
  final Outfit? outfit;
  final String? message;

  // New fields from redesigned API
  final String? pickId;
  final String? topId;
  final String? bottomId;
  final String? imageUrl;
  final String? reasoning;
  final double? score;
  final Map<String, dynamic>? weather;

  TodaysPick({
    required this.success,
    required this.weatherSummary,
    required this.tempMin,
    required this.tempMax,
    this.outfit,
    this.message,
    this.pickId,
    this.topId,
    this.bottomId,
    this.imageUrl,
    this.reasoning,
    this.score,
    this.weather,
  });

  factory TodaysPick.fromJson(Map<String, dynamic> json) {
    return TodaysPick(
      success: json['success'] ?? false,
      weatherSummary: json['weather_summary'] ?? '',
      tempMin: (json['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (json['temp_max'] as num?)?.toDouble() ?? 0.0,
      outfit: json['outfit'] != null ? Outfit.fromJson(json['outfit']) : null,
      message: json['message'],
      pickId: json['pick_id']?.toString(),
      topId: json['top_id']?.toString(),
      bottomId: json['bottom_id']?.toString(),
      imageUrl: json['image_url'],
      reasoning: json['reasoning'],
      score: (json['score'] as num?)?.toDouble(),
      weather: json['weather'] as Map<String, dynamic>?,
    );
  }
}
