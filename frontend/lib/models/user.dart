class TravelPickUser {
  const TravelPickUser({
    required this.id,
    required this.name,
    required this.groupName,
    required this.groupCode,
  });

  final int id;
  final String name;
  final String groupName;
  final String groupCode;

  TravelPickUser copyWith({
    int? id,
    String? name,
    String? groupName,
    String? groupCode,
  }) {
    return TravelPickUser(
      id: id ?? this.id,
      name: name ?? this.name,
      groupName: groupName ?? this.groupName,
      groupCode: groupCode ?? this.groupCode,
    );
  }
}
