class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.imageUrl,
    required this.rating,
    required this.popularity,
    required this.description,
    required this.estimatedCost,
    required this.bestSeason,
  });

  final int id;
  final String name;
  final String country;
  final String imageUrl;
  final double rating;
  final int popularity;
  final String description;
  final String estimatedCost;
  final String bestSeason;

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: _readId(json['id'] ?? json['destination_id']),
      name:
          (json['name'] as String?) ??
          (json['title'] as String?) ??
          (json['destination'] as String?) ??
          '',
      country:
          (json['country'] as String?) ??
          (json['location'] as String?) ??
          'Unknown',
      imageUrl:
          (json['imageUrl'] as String?) ?? (json['image_url'] as String?) ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).round(),
      description: json['description'] as String? ?? '',
      estimatedCost:
          (json['estimatedCost'] as String?) ??
          (json['estimated_cost'] as String?) ??
          '',
      bestSeason:
          (json['bestSeason'] as String?) ??
          (json['best_season'] as String?) ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'imageUrl': imageUrl,
      'rating': rating,
      'popularity': popularity,
      'description': description,
      'estimatedCost': estimatedCost,
      'bestSeason': bestSeason,
    };
  }

  static int _readId(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? _stableHash(value);
    }
    return 0;
  }

  static int _stableHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
