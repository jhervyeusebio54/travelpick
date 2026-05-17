import 'destination.dart';

enum PrivacyMode {
  private,
  public;

  String get label {
    return switch (this) {
      PrivacyMode.private => 'Private',
      PrivacyMode.public => 'Public',
    };
  }

  String get description {
    return switch (this) {
      PrivacyMode.private => 'Only invited members can join.',
      PrivacyMode.public => 'Anyone can vote and share opinions.',
    };
  }

  String get apiValue {
    return switch (this) {
      PrivacyMode.private => 'private',
      PrivacyMode.public => 'public',
    };
  }
}

class CreatedGroup {
  const CreatedGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.privacyMode,
    required this.destinations,
    required this.createdAt,
    required this.ownerUserId,
    this.hasUserVoted = false,
    this.isCreator = true,
  });

  final String id;
  final String name;
  final String code;
  final PrivacyMode privacyMode;
  final List<Destination> destinations;
  final DateTime createdAt;
  final String ownerUserId;
  final bool hasUserVoted;
  final bool isCreator;

  int get destinationCount => destinations.length;

  String get formattedCreatedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  CreatedGroup copyWith({
    String? id,
    String? name,
    String? code,
    PrivacyMode? privacyMode,
    List<Destination>? destinations,
    DateTime? createdAt,
    String? ownerUserId,
    bool? hasUserVoted,
    bool? isCreator,
  }) {
    return CreatedGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      privacyMode: privacyMode ?? this.privacyMode,
      destinations: destinations ?? this.destinations,
      createdAt: createdAt ?? this.createdAt,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      hasUserVoted: hasUserVoted ?? this.hasUserVoted,
      isCreator: isCreator ?? this.isCreator,
    );
  }
}
