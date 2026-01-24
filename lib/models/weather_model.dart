class DailyWeather {
  final String dateId;
  final double? minTemp;
  final double? maxTemp;
  final int rainType;
  final String message;
  final String? region;

  DailyWeather({
    required this.dateId,
    this.minTemp,
    this.maxTemp,
    required this.rainType,
    required this.message,
    this.region,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      dateId: json['date_id'] as String,
      minTemp: (json['min_temp'] as num?)?.toDouble(),
      maxTemp: (json['max_temp'] as num?)?.toDouble(),
      rainType: json['rain_type'] as int,
      message: json['message'] as String,
      region: json['region'] as String?,
    );
  }
}
