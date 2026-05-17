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
      id: json['id'] as int,
      name: json['name'] as String,
      country: json['country'] as String? ?? 'Unknown',
      imageUrl: json['imageUrl'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      popularity: json['popularity'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      estimatedCost: json['estimatedCost'] as String? ?? '',
      bestSeason: json['bestSeason'] as String? ?? '',
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
}
