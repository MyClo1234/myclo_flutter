import 'item.dart';

class Outfit {
  final String? id;
  final Item top;
  final Item bottom;
  final double score;
  final String? reasoning;
  final String? styleDescription;
  final List<String> reasons;

  Outfit({
    this.id,
    required this.top,
    required this.bottom,
    required this.score,
    this.reasoning,
    this.styleDescription,
    this.reasons = const [],
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id']?.toString(), // Sometimes implicit
      top: Item.fromJson(json['top']),
      bottom: Item.fromJson(json['bottom']),
      score:
          (json['score'] is int
              ? (json['score'] as int).toDouble()
              : json['score']) ??
          0.0,
      reasoning: json['reasoning'],
      styleDescription: json['style_description'],
      reasons:
          (json['reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
