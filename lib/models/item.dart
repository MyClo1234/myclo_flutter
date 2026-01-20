class Item {
  final String id;
  final String name;
  final String category; // Main category
  final String subCategory; // Sub category
  final String color;
  final String? imageUrl;
  final Map<String, dynamic>? attributes;

  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.color,
    this.imageUrl,
    this.attributes,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    var attrs = json['attributes'] as Map<String, dynamic>?;
    return Item(
      id: json['id']?.toString() ?? '',
      name:
          attrs?['category']?['sub'] ??
          attrs?['category']?['main'] ??
          'Unknown',
      category: attrs?['category']?['main'] ?? 'Other',
      subCategory: attrs?['category']?['sub'] ?? '',
      color: attrs?['color']?['primary'] ?? 'Unknown',
      imageUrl: json['image_url'],
      attributes: attrs,
    );
  }
}
