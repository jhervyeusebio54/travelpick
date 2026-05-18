class UserGroupMembership {
  final int groupId;
  final String role;

  const UserGroupMembership({required this.groupId, required this.role});

  factory UserGroupMembership.fromJson(Map<String, dynamic> json) {
    return UserGroupMembership(
      groupId: (json['group_id'] as num).round(),
      role: json['role'] as String? ?? 'member',
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.isGuest = false,
    this.groupId,
    this.groupCode,
    this.groupName,
    this.groupRole,
    this.lastLogin,
    this.groups = const [],
  });

  final String id;
  final String name;
  final String email;
  final bool isGuest;
  final int? groupId;
  final String? groupCode;
  final String? groupName;
  final String? groupRole;
  final String? lastLogin;
  final List<UserGroupMembership> groups;

  bool get hasGroup =>
      (groupName != null && groupName!.trim().isNotEmpty) ||
      (groupCode != null && groupCode!.trim().isNotEmpty);

  String get username => name;

  String get displayLabel {
    if (isGuest) {
      return 'Guest Explorer';
    }
    return name.trim().isNotEmpty ? name : email;
  }

  String get groupDisplay {
    if (groupName != null && groupName!.trim().isNotEmpty) {
      if (groupCode != null && groupCode!.trim().isNotEmpty) {
        return '${groupName!.trim()} · ${groupCode!.trim()}';
      }
      return groupName!.trim();
    }
    if (groupCode != null && groupCode!.trim().isNotEmpty) {
      return groupCode!.trim();
    }
    return '';
  }

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    bool? isGuest,
    int? groupId,
    String? groupCode,
    String? groupName,
    String? groupRole,
    String? lastLogin,
    List<UserGroupMembership>? groups,
    bool clearGroup = false,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isGuest: isGuest ?? this.isGuest,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      groupCode: clearGroup ? null : (groupCode ?? this.groupCode),
      groupName: clearGroup ? null : (groupName ?? this.groupName),
      groupRole: clearGroup ? null : (groupRole ?? this.groupRole),
      lastLogin: clearGroup ? null : (lastLogin ?? this.lastLogin),
      groups: groups ?? this.groups,
    );
  }

  static AuthUser fromProfile(Map<String, dynamic> profile) {
    final id = profile['id'];
    return AuthUser(
      id: id is num ? id.round().toString() : id?.toString() ?? '',
      name: (profile['username'] as String? ?? profile['name'] as String? ?? '').trim(),
      email: (profile['email'] as String? ?? '').trim().toLowerCase(),
      groupId: (profile['group_id'] as num?)?.round(),
      groupCode: profile['group_code'] as String?,
      groupRole: profile['group_role'] as String?,
      lastLogin: profile['last_login'] as String?,
      groups: (profile['groups'] as List<dynamic>?)
              ?.map((item) => UserGroupMembership.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
