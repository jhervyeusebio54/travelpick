import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'debug_log_io.dart' if (dart.library.html) 'debug_log_stub.dart'
    as debug_log_io;

import '../mock_data.dart';
import '../models/destination.dart';
import '../models/group.dart';
import '../models/user.dart';
import '../models/vote.dart';
import 'auth_service.dart';

class ApiEndpoints {
  const ApiEndpoints._();

  static const groups = '/groups';
  static const destinations = '/destinations';
  static const voteBatch = '/votes/batch';
  static const results = '/results';
  static const userSignup = '/users/signup';
  static const userMembership = '/users/membership';
  static const userLogin = '/users/login';
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();
  static const baseUrl = 'http://127.0.0.1:8000';
  static const useMockData = true;
  static const useRemoteDestinationApi = true;

  final _random = Random();
  final List<CreatedGroup> _savedGroups = [];
  final Map<String, int> _backendGroupIdsByLocalId = {};
  final Map<int, int> _backendVoterUserIdByGroupId = {};
  int _groupIdCounter = 0;

  TravelPickUser _activeUser = mockActiveUser;
  CreatedGroup? _activeGroup;
  final Map<int, int> _userWeights = {};
  List<Destination> _lastVotedDestinations =
      []; // Track destinations that were voted on
  bool _hasSubmittedVotes = false;
  bool _backendVotesSynced = false;

  TravelPickUser get activeUser => _activeUser;
  CreatedGroup? get activeGroup => _activeGroup;
  List<CreatedGroup> get myGroups =>
      List<CreatedGroup>.unmodifiable(_savedGroups);
  int get expectedVoters => 1;
  int get submittedVoters => _hasSubmittedVotes ? 1 : 0;

  String? get _currentOwnerId => AuthService.instance.currentUser?.id;

  Future<List<CreatedGroup>> fetchMyGroups() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final ownerId = _currentOwnerId;
    if (ownerId == null) {
      return const [];
    }

    // Hydrate groups from the backend user profile if present
    final profileGroups = AuthService.instance.currentUser?.groups ?? [];
    for (final membership in profileGroups) {
      final backendGroupId = membership.groupId;
      final groupRole = membership.role;
      final isCreator = groupRole == 'owner';

      // Check if we already have this group in _savedGroups
      final String groupStrId = backendGroupId.toString();
      final exists = _savedGroups.any((g) => g.id == groupStrId || _backendGroupIdsByLocalId[g.id] == backendGroupId);

      if (!exists) {
        try {
          final groupData = await fetchGroupById(backendGroupId);
          if (groupData != null) {
            final name = groupData['name'] as String? ?? 'Trip';
            final code = groupData['code'] as String? ?? '';
            final isPublic = (groupData['privacy'] as String?) == 'public';
            
            final loadedGroup = CreatedGroup(
              id: groupStrId,
              name: name,
              code: code,
              privacyMode: isPublic ? PrivacyMode.public : PrivacyMode.private,
              destinations: List<Destination>.unmodifiable(mockDestinations),
              createdAt: DateTime.now(),
              ownerUserId: groupData['owner_user_id']?.toString() ?? 'guest',
              isCreator: isCreator,
            );

            _savedGroups.add(loadedGroup);
            _backendGroupIdsByLocalId[groupStrId] = backendGroupId;
            _backendGroupIdsByLocalId[code] = backendGroupId;
          }
        } catch (e) {
          debugPrint('Error loading group $backendGroupId from backend: $e');
        }
      }
    }

    // Filter to only groups that belong to the user
    final profileGroupIds = profileGroups.map((m) => m.groupId.toString()).toSet();
    final groups = _savedGroups.where((group) {
      final isOwner = group.ownerUserId == ownerId;
      final bgId = _backendGroupIdsByLocalId[group.id]?.toString() ?? group.id;
      final isMember = profileGroupIds.contains(bgId) || profileGroupIds.contains(group.id);
      return isOwner || isMember;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return groups;
  }

  Future<List<CreatedGroup>> fetchPublicGroups() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final groups =
        _savedGroups
            .where((group) => group.privacyMode == PrivacyMode.public)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return groups;
  }

  CreatedGroup? findGroupByCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final group in _savedGroups) {
      if (group.code.toUpperCase() == normalized) {
        return group;
      }
    }
    return null;
  }

  Future<bool> deleteGroup(String groupId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));

    final ownerId = _currentOwnerId;
    final index = _savedGroups.indexWhere((group) => group.id == groupId);
    if (index < 0) {
      return false;
    }

    final group = _savedGroups[index];
    if (ownerId != null && group.ownerUserId != ownerId) {
      return false;
    }

    _savedGroups.removeAt(index);

    if (_activeGroup?.id == groupId) {
      _activeGroup = null;
      _hasSubmittedVotes = false;
      _userWeights.clear();
    }

    return true;
  }

  void setActiveGroup(CreatedGroup group) {
    _activeGroup = group;
    _activeUser = _activeUser.copyWith(
      groupName: group.name,
      groupCode: group.code,
    );
    _hasSubmittedVotes = group.hasUserVoted;
    _userWeights.clear();
  }

  Future<void> _persistActiveGroupOnProfile(CreatedGroup group) async {
    final backendGroupId = await _ensureBackendGroupId(group);
    final groupRole = group.isCreator ? 'owner' : 'member';
    if (backendGroupId != null) {
      await _syncUserGroupMembership(
        backendGroupId: backendGroupId,
        groupCode: group.code,
        groupRole: groupRole,
      );
    }
    await AuthService.instance.updateProfileGroup(
      groupId: backendGroupId,
      groupCode: group.code,
      groupName: group.name,
      groupRole: groupRole,
    );
    await AuthService.instance.refreshFromBackend();
  }

  void setVotingDestinations(List<Destination> destinations) {
    _lastVotedDestinations = destinations;
  }

  Future<TravelPickUser> createPoll(String groupName) async {
    if (!useMockData) {
      return _createPollRequest(groupName);
    }

    await Future<void>.delayed(const Duration(milliseconds: 260));
    _activeUser = _activeUser.copyWith(
      groupName: groupName,
      groupCode: _buildLegacyGroupCode(groupName),
    );
    _hasSubmittedVotes = false;
    _userWeights.clear();
    return _activeUser;
  }

  Future<TravelPickUser> createGroup(String groupName) => createPoll(groupName);

  Future<CreatedGroup> createTravelGroup({
    required String groupName,
    required PrivacyMode privacyMode,
    required List<Destination> destinations,
    String? ownerUserId,
  }) async {
    if (!useMockData) {
      return _createGroupRequest(
        groupName: groupName,
        privacyMode: privacyMode,
        destinations: destinations,
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 520));
    final code = await generateGroupCode();
    final selectedDestinations = List<Destination>.unmodifiable(destinations);

    for (final destination in selectedDestinations) {
      await addDestinationToGroup(groupCode: code, destination: destination);
    }

    final ownerId = ownerUserId ?? _currentOwnerId ?? 'guest';
    final localGroupId = _nextGroupId();
    final group = CreatedGroup(
      id: localGroupId,
      name: groupName,
      code: code,
      privacyMode: privacyMode,
      destinations: selectedDestinations,
      createdAt: DateTime.now(),
      ownerUserId: ownerId,
    );

    await _syncGroupToBackend(group);
    _savedGroups.add(group);
    setActiveGroup(group);
    await _persistActiveGroupOnProfile(group);
    _hasSubmittedVotes = false;
    _backendVotesSynced = false;
    _userWeights.clear();

    return group;
  }

  Future<String> generateGroupCode([String? groupName]) async {
    if (!useMockData) {
      return _generateCodeRequest(groupName ?? '');
    }

    await Future<void>.delayed(const Duration(milliseconds: 140));
    return _generateUniqueShareCode();
  }

  Future<void> addDestinationToGroup({
    required String groupCode,
    required Destination destination,
  }) async {
    if (!useMockData) {
      return _addDestinationRequest(
        groupCode: groupCode,
        destination: destination,
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 70));
  }

  Future<Map<String, dynamic>> fetchUserProfile(int userId) async {
    return _getJson('/users/$userId');
  }

  Future<Map<String, dynamic>?> fetchGroupById(int groupId) async {
    try {
      return await _getJson('${ApiEndpoints.groups}?id=$groupId');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchGroupByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    try {
      final data = await _getJson('${ApiEndpoints.groups}?code=$normalized');
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _postJson(ApiEndpoints.userLogin, {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }

  Future<void> _syncUserGroupMembership({
    required int backendGroupId,
    required String groupCode,
    required String groupRole,
  }) async {
    final userId = _registeredAuthUserId();
    if (userId == null) {
      return;
    }
    try {
      await _postJson(ApiEndpoints.userMembership, {
        'user_id': userId,
        'group_id': backendGroupId,
        'group_code': groupCode.trim().toUpperCase(),
        'group_role': groupRole,
      });
    } on StateError catch (error) {
      if (error.message.contains('already assigned')) {
        rethrow;
      }
    } catch (_) {
      // Group membership sync is best-effort when offline.
    }
  }

  Future<Map<String, dynamic>> registerAccount({
    required String name,
    required String email,
    required String password,
    String? groupCode,
    int? groupId,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    if (groupId != null) {
      payload['group_id'] = groupId;
    } else if (groupCode != null && groupCode.trim().isNotEmpty) {
      payload['group_code'] = groupCode.trim().toUpperCase();
    }

    try {
      return await _postJson(ApiEndpoints.userSignup, payload);
    } catch (error) {
      final message = error.toString();
      if (_isSignupBusinessErrorMessage(message)) {
        throw StateError(_signupBusinessErrorMessage(message));
      }
      if (message.contains('Not found')) {
        return _registerAccountFallback(payload);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _registerAccountFallback(
    Map<String, dynamic> payload,
  ) async {
    final fallbackPayload = <String, dynamic>{
      'name': payload['name'],
      'email': payload['email'],
    };
    if (payload.containsKey('group_id')) {
      fallbackPayload['group_id'] = payload['group_id'];
    }
    try {
      return await _postJson('/users', fallbackPayload);
    } catch (error) {
      final message = error.toString();
      if (_isSignupBusinessErrorMessage(message)) {
        throw StateError(_signupBusinessErrorMessage(message));
      }
      rethrow;
    }
  }

  static bool _isSignupBusinessErrorMessage(String message) {
    return message.contains('User already exists') ||
        message.contains('Group not found') ||
        message.contains('Invalid input');
  }

  static String _signupBusinessErrorMessage(String message) {
    if (message.contains('User already exists')) {
      return 'User already exists';
    }
    if (message.contains('Group not found')) {
      return 'Group not found';
    }
    if (message.contains('Invalid input')) {
      return 'Invalid input';
    }
    return message;
  }

  Future<TravelPickUser> joinGroup(String groupCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final normalizedCode = groupCode.trim().toUpperCase();
    final existing = findGroupByCode(normalizedCode);

    if (existing != null) {
      setActiveGroup(existing);
      await _persistActiveGroupOnProfile(existing);
      await _registerBackendVoterForActiveGroup();
      return _activeUser;
    }

    // Fetch real group info from backend so we use the actual name,
    // not a placeholder. Prevents in-memory state diverging from users.json.
    final backendGroup = await fetchGroupByCode(normalizedCode);
    final groupName = (backendGroup != null &&
            (backendGroup['name'] as String? ?? '').trim().isNotEmpty)
        ? backendGroup['name'] as String
        : (normalizedCode.contains('-') ? 'Explorer Crew' : normalizedCode);

    final joinedGroup = CreatedGroup(
      id: _nextGroupId(),
      name: groupName,
      code: normalizedCode,
      privacyMode: PrivacyMode.private,
      destinations: List<Destination>.unmodifiable(mockDestinations),
      createdAt: DateTime.now(),
      ownerUserId: _currentOwnerId ?? 'guest',
      isCreator: false,
    );

    _savedGroups.add(joinedGroup);
    setActiveGroup(joinedGroup);
    // _persistActiveGroupOnProfile calls _syncUserGroupMembership then
    // AuthService.refreshFromBackend() keeping users.json as source of truth.
    await _persistActiveGroupOnProfile(joinedGroup);
    _hasSubmittedVotes = false;
    _userWeights.clear();
    await _registerBackendVoterForActiveGroup();
    return _activeUser;
  }

  Future<void> _registerBackendVoterForActiveGroup() async {
    final activeGroup = _activeGroup;
    if (activeGroup == null || activeGroup.isCreator) {
      return;
    }

    final backendGroupId = await _ensureBackendGroupId(activeGroup);
    if (backendGroupId == null) {
      return;
    }

    try {
      await _resolveBackendVoterUserId(backendGroupId);
    } catch (_) {
      // Group may exist only on the backend after the host creates it.
    }
  }

  Future<int?> _ensureBackendGroupId(CreatedGroup group) async {
    var backendGroupId =
        _backendGroupIdsByLocalId[group.id] ?? _backendGroupIdsByLocalId[group.code];
    if (backendGroupId == null && !group.isCreator) {
      backendGroupId = await _findBackendGroupIdByCode(group.code);
    }
    if (backendGroupId != null) {
      _backendGroupIdsByLocalId[group.id] = backendGroupId;
      _backendGroupIdsByLocalId[group.code] = backendGroupId;
    }
    return backendGroupId;
  }

  Future<int?> _findBackendGroupIdByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl${ApiEndpoints.groups}?code=$normalized'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['id'] != null) {
          return (decoded['id'] as num).round();
        }
      }
    } catch (_) {
      // Fall back to listing groups below.
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl${ApiEndpoints.groups}'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return null;
      }
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final groupCode = (entry['code'] as String? ?? '').trim().toUpperCase();
        if (groupCode == normalized && entry['id'] != null) {
          return (entry['id'] as num).round();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  int? _registeredAuthUserId() {
    final authUser = AuthService.instance.currentUser;
    if (authUser == null || authUser.isGuest) {
      return null;
    }
    return int.tryParse(authUser.id);
  }

  Future<String> _deviceParticipantId() async {
    final prefs = await SharedPreferences.getInstance();
    var participantId = prefs.getString('tp_device_participant_id');
    if (participantId == null || participantId.isEmpty) {
      participantId =
          'p_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(99999)}';
      await prefs.setString('tp_device_participant_id', participantId);
    }
    return participantId;
  }

  String _voterPrefsKey(int backendGroupId, bool isCreator) {
    if (isCreator) {
      return 'tp_voter_${backendGroupId}_owner';
    }
    return 'tp_voter_${backendGroupId}_member';
  }

  Future<List<Destination>> fetchDestinations({
    CreatedGroup? group,
    bool forceAll = false,
  }) async {
    if (forceAll && useRemoteDestinationApi) {
      try {
        return await searchDestinations();
      } catch (_) {
        return List<Destination>.unmodifiable(mockDestinations);
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (forceAll) {
      return List<Destination>.unmodifiable(mockDestinations);
    }
    final scopedGroup = group ?? _activeGroup;
    if (scopedGroup != null && scopedGroup.destinations.isNotEmpty) {
      return List<Destination>.unmodifiable(scopedGroup.destinations);
    }
    return List<Destination>.unmodifiable(mockDestinations);
  }

  Future<List<Destination>> searchDestinations([String query = '']) async {
    if (!useRemoteDestinationApi) {
      return _filterMockDestinations(query);
    }

    try {
      final remoteDestinations = await _fetchWikipediaDestinations(query);
      if (remoteDestinations.isNotEmpty) {
        return remoteDestinations;
      }
    } catch (_) {
      // Keep destination discovery usable when the public API is unavailable.
    }

    return _filterMockDestinations(query);
  }

  Future<void> submitVote(List<Vote> votes) async {
    if (!useMockData) {
      return _submitVoteRequest(votes);
    }

    await Future<void>.delayed(const Duration(milliseconds: 360));
    _userWeights
      ..clear()
      ..addEntries(
        votes.map((vote) => MapEntry(vote.destinationId, vote.weight)),
      );
    _hasSubmittedVotes = true;

    if (_activeGroup != null) {
      final index = _savedGroups.indexWhere((g) => g.id == _activeGroup!.id);
      if (index >= 0) {
        final updated = _activeGroup!.copyWith(hasUserVoted: true);
        _savedGroups[index] = updated;
        _activeGroup = updated;
      }
    }

    try {
      await _syncVotesToBackend(votes);
    } catch (error) {
      // #region agent log
      _debugIngest('api_service.dart:submitVote', 'vote sync error', {
        'hypothesisId': 'A,D',
        'error': error.toString(),
      });
      // #endregion
      rethrow;
    }
  }

  Future<void> submitVotes(List<Vote> votes) => submitVote(votes);

  Future<ResultsSnapshot> getResults() async {
    final backendResults = await _fetchBackendResults();
    // #region agent log
    _debugIngest('api_service.dart:getResults', 'backend results branch', {
      'hypothesisId': 'C',
      'runId': 'post-fix',
      'backendResultsNull': backendResults == null,
      'backendTotalVotes': backendResults?.totalVotes,
      'useMockData': useMockData,
      'hasSubmittedVotes': _hasSubmittedVotes,
      'backendVotesSynced': _backendVotesSynced,
      'useBackendResults': backendResults != null &&
          _shouldReturnBackendResults(backendResults),
      'hasBackendGroupId': _activeGroup != null &&
          _backendGroupIdsByLocalId.containsKey(_activeGroup!.id),
    });
    // #endregion
    if (backendResults != null && _shouldReturnBackendResults(backendResults)) {
      return backendResults;
    }

    if (!useMockData) {
      return _getResultsRequest();
    }

    if (_hasSubmittedVotes && _userWeights.isEmpty) {
      await _hydrateVotesFromBackend();
    }

    // #region agent log
    _debugIngest('api_service.dart:getResults', 'using local mock results', {
      'hypothesisId': 'C',
      'runId': 'post-fix',
      'hasSubmittedVotes': _hasSubmittedVotes,
      'localVoteCount': _userWeights.length,
    });
    // #endregion

    await Future<void>.delayed(const Duration(milliseconds: 320));

    // Use the last voted destinations if available, then active group destinations, then mock data
    final destinationPool = _lastVotedDestinations.isNotEmpty
        ? _lastVotedDestinations
        : (_activeGroup?.destinations.isNotEmpty == true
              ? _activeGroup!.destinations
              : mockDestinations);

    final votes = [
      if (_hasSubmittedVotes)
        ..._userWeights.entries.map(
          (entry) => Vote(
            userId: _activeUser.id,
            destinationId: entry.key,
            weight: entry.value,
          ),
        ),
    ];

    // Build destination map from the pool
    final destinationMap = <int, Destination>{};
    for (final dest in destinationPool) {
      destinationMap[dest.id] = dest;
    }

    final results = votes.isNotEmpty
        ? destinationMap.values.map((destination) {
            final destinationVotes = votes
                .where((vote) => vote.destinationId == destination.id)
                .toList(growable: false);
            final distribution = <int, int>{1: 0, 2: 0, 3: 0};
            var totalScore = 0;

            for (final vote in destinationVotes) {
              totalScore += vote.weight;
              distribution[vote.weight] = (distribution[vote.weight] ?? 0) + 1;
            }

            return DestinationResult(
              destination: destination,
              totalScore: totalScore,
              voteCount: destinationVotes.length,
              weightDistribution: distribution,
            );
          }).toList()
        : destinationPool
              .map(
                (destination) => DestinationResult(
                  destination: destination,
                  totalScore: 0,
                  voteCount: 0,
                  weightDistribution: {},
                ),
              )
              .toList();

    results.sort((a, b) {
      final scoreCompare = b.totalScore.compareTo(a.totalScore);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.destination.name.compareTo(b.destination.name);
    });

    return ResultsSnapshot(
      ranking: List<DestinationResult>.unmodifiable(results),
      totalVotes: votes.length,
      voterCount: submittedVoters,
      expectedVoters: expectedVoters,
    );
  }

  Future<ResultsSnapshot> fetchResults() => getResults();

  /// Prefer backend totals when this group is linked to a backend id.
  bool _shouldReturnBackendResults(ResultsSnapshot backendResults) {
    final activeGroup = _activeGroup;
    if (activeGroup != null) {
      final linked = _backendGroupIdsByLocalId.containsKey(activeGroup.id) ||
          _backendGroupIdsByLocalId.containsKey(activeGroup.code);
      if (linked) {
        return true;
      }
    }
    if (!useMockData) {
      return true;
    }
    return backendResults.totalVotes > 0;
  }

  /// Restore local weights after [setActiveGroup] cleared them (e.g. reopening results).
  Future<void> _hydrateVotesFromBackend() async {
    final activeGroup = _activeGroup;
    if (activeGroup == null || _userWeights.isNotEmpty) {
      return;
    }

    final backendGroupId = _backendGroupIdsByLocalId[activeGroup.id];
    if (backendGroupId == null) {
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/votes/$backendGroupId'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return;
      }

      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final destinationId = entry['destination_id'];
        final weight = entry['weight'];
        if (destinationId is int && weight is int) {
          _userWeights[destinationId] = weight;
        } else if (destinationId is num && weight is num) {
          _userWeights[destinationId.round()] = weight.round();
        }
      }
      // #region agent log
      _debugIngest('api_service.dart:_hydrateVotesFromBackend', 'hydrated', {
        'hypothesisId': 'G',
        'runId': 'post-fix-2',
        'weightCount': _userWeights.length,
      });
      // #endregion
    } catch (error) {
      // #region agent log
      _debugIngest('api_service.dart:_hydrateVotesFromBackend', 'failed', {
        'hypothesisId': 'G',
        'runId': 'post-fix-2',
        'error': error.toString(),
      });
      // #endregion
    }
  }

  String _nextGroupId() {
    _groupIdCounter += 1;
    return 'group-$_groupIdCounter';
  }

  String _generateUniqueShareCode() {
    const prefix = 'TRVL';
    for (var attempt = 0; attempt < 50; attempt++) {
      final suffix = 1000 + _random.nextInt(9000);
      final code = '$prefix-$suffix';
      if (findGroupByCode(code) == null) {
        return code;
      }
    }
    return '$prefix-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  Future<TravelPickUser> _createPollRequest(String groupName) async {
    final response = await _postJson(ApiEndpoints.groups, {'name': groupName});
    return _activeUser.copyWith(
      groupName: response['name'] as String? ?? groupName,
      groupCode:
          response['code'] as String? ?? _buildLegacyGroupCode(groupName),
    );
  }

  Future<void> _submitVoteRequest(List<Vote> votes) async {
    await _syncVotesToBackend(votes);
  }

  Future<ResultsSnapshot> _getResultsRequest() async {
    final results = await _fetchBackendResults();
    if (results != null) {
      return results;
    }
    throw StateError('No active backend group to fetch results for.');
  }

  Future<CreatedGroup> _createGroupRequest({
    required String groupName,
    required PrivacyMode privacyMode,
    required List<Destination> destinations,
  }) async {
    final code = await generateGroupCode();
    final group = CreatedGroup(
      id: _nextGroupId(),
      name: groupName,
      code: code,
      privacyMode: privacyMode,
      destinations: List<Destination>.unmodifiable(destinations),
      createdAt: DateTime.now(),
      ownerUserId: _currentOwnerId ?? 'guest',
    );
    await _syncGroupToBackend(group);
    _savedGroups.add(group);
    setActiveGroup(group);
    return group;
  }

  Future<String> _generateCodeRequest(String groupName) async {
    return _generateUniqueShareCode();
  }

  Future<void> _addDestinationRequest({
    required String groupCode,
    required Destination destination,
  }) async {
    final backendGroupId = _backendGroupIdsByLocalId[groupCode];
    if (backendGroupId == null) {
      return;
    }
    await _syncDestinationToBackend(backendGroupId, destination);
  }

  String _buildLegacyGroupCode(String groupName) {
    final letters = groupName
        .trim()
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]'), '')
        .padRight(2, 'X')
        .substring(0, 2);
    final suffix = 300 + groupName.trim().length * 7;
    return '$letters-$suffix';
  }

  Future<List<Destination>> _fetchWikipediaDestinations(String query) async {
    final normalizedQuery = query.trim();
    final searchText = normalizedQuery.isEmpty
        ? 'popular tourist attractions travel destinations'
        : '$normalizedQuery tourist attraction travel destination';
    final uri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'generator': 'search',
      'gsrsearch': searchText,
      'gsrlimit': '30',
      'prop': 'pageimages|extracts',
      'exintro': '1',
      'explaintext': '1',
      'piprop': 'thumbnail',
      'pithumbsize': '900',
      'format': 'json',
      'origin': '*',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Wikipedia returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final queryData = decoded['query'] as Map<String, dynamic>?;
    final pages = queryData?['pages'] as Map<String, dynamic>?;
    if (pages == null) {
      return const [];
    }

    final pageValues =
        pages.values
            .whereType<Map<String, dynamic>>()
            .where(
              (page) => (page['extract'] as String? ?? '').trim().isNotEmpty,
            )
            .toList()
          ..sort((a, b) {
            final aIndex = a['index'] as int? ?? 0;
            final bIndex = b['index'] as int? ?? 0;
            return aIndex.compareTo(bIndex);
          });

    return pageValues
        .asMap()
        .entries
        .map((entry) => _destinationFromWikipediaPage(entry.value, entry.key))
        .toList(growable: false);
  }

  Destination _destinationFromWikipediaPage(
    Map<String, dynamic> page,
    int index,
  ) {
    final title = _cleanTitle(page['title'] as String? ?? 'Destination');
    final extract = (page['extract'] as String? ?? '').trim();
    final thumbnail = page['thumbnail'] as Map<String, dynamic>?;
    final popularity = max(68, 96 - index);

    return Destination(
      id: page['pageid'] as int? ?? title.hashCode,
      name: title,
      country: _deriveLocation(extract),
      imageUrl: thumbnail?['source'] as String? ?? '',
      rating: max(3.8, 4.9 - (index * 0.03)),
      popularity: popularity,
      description: _shortDescription(extract),
      estimatedCost: 'Varies by itinerary',
      bestSeason: 'Check local seasonality',
    );
  }

  List<Destination> _filterMockDestinations(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return List<Destination>.unmodifiable(mockDestinations);
    }

    return mockDestinations
        .where((destination) {
          return destination.name.toLowerCase().contains(normalizedQuery) ||
              destination.country.toLowerCase().contains(normalizedQuery) ||
              destination.description.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  String _cleanTitle(String title) {
    return title.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  String _deriveLocation(String extract) {
    final match = RegExp(
      r"\b(?:in|near|from|of)\s+([A-Z][A-Za-z .'-]+?)(?:,|\.|\sis|\sare|\swas|\swith|\sand)",
    ).firstMatch(extract);
    return match?.group(1)?.trim() ?? 'Tourist place';
  }

  String _shortDescription(String extract) {
    final compact = extract.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 180) {
      return compact;
    }
    return '${compact.substring(0, 177).trimRight()}...';
  }

  Future<bool> _syncGroupToBackend(CreatedGroup group) async {
    try {
      int? backendGroupId;
      if (!group.isCreator) {
        backendGroupId = await _findBackendGroupIdByCode(group.code);
      }
      if (backendGroupId == null) {
        final ownerId = _registeredAuthUserId() ?? activeUser.id;
        final response = await _postJson(ApiEndpoints.groups, {
          'name': group.name,
          'code': group.code,
          'privacy': group.privacyMode.apiValue,
          'owner_user_id': ownerId,
          'member_user_ids': [ownerId],
        });
        backendGroupId = (response['id'] as num?)?.round();
      }
      if (backendGroupId == null) {
        return false;
      }

      for (final destination in group.destinations) {
        await _syncDestinationToBackend(backendGroupId, destination);
      }

      _backendGroupIdsByLocalId[group.id] = backendGroupId;
      _backendGroupIdsByLocalId[group.code] = backendGroupId;
      await _syncUserGroupMembership(
        backendGroupId: backendGroupId,
        groupCode: group.code,
        groupRole: 'owner',
      );
      // #region agent log
      _debugIngest('api_service.dart:_syncGroupToBackend', 'group sync ok', {
        'hypothesisId': 'D',
        'runId': 'post-fix',
        'backendGroupId': backendGroupId,
        'destinationCount': group.destinations.length,
      });
      // #endregion
      return true;
    } catch (error) {
      // #region agent log
      _debugIngest('api_service.dart:_syncGroupToBackend', 'group sync failed', {
        'hypothesisId': 'D',
        'error': error.toString(),
      });
      // #endregion
      // The in-memory flow remains usable if the local backend is not running.
      return false;
    }
  }

  Future<void> _syncDestinationToBackend(
    int backendGroupId,
    Destination destination,
  ) async {
    await _postJson(ApiEndpoints.destinations, {
      ...destination.toJson(),
      'group_id': backendGroupId,
    });
  }

  Future<int> _resolveBackendVoterUserId(int backendGroupId) async {
    final activeGroup = _activeGroup;
    final isCreator = activeGroup?.isCreator ?? true;
    final prefs = await SharedPreferences.getInstance();
    final registeredUserId = _registeredAuthUserId();
    final prefsKey = isCreator
        ? _voterPrefsKey(backendGroupId, true)
        : 'tp_voter_${backendGroupId}_${_registeredAuthUserId() ?? await _deviceParticipantId()}';

    if (registeredUserId != null) {
      await prefs.setInt(prefsKey, registeredUserId);
      _backendVoterUserIdByGroupId[backendGroupId] = registeredUserId;
      _activeUser = _activeUser.copyWith(id: registeredUserId);
      return registeredUserId;
    }

    final storedId = prefs.getInt(prefsKey);
    if (storedId != null) {
      _backendVoterUserIdByGroupId[backendGroupId] = storedId;
      _activeUser = _activeUser.copyWith(id: storedId);
      return storedId;
    }

    final participantId = await _deviceParticipantId();
    final guestPrefsKey = 'tp_voter_${backendGroupId}_$participantId';
    final guestStoredId = prefs.getInt(guestPrefsKey);
    if (guestStoredId != null) {
      _backendVoterUserIdByGroupId[backendGroupId] = guestStoredId;
      _activeUser = _activeUser.copyWith(id: guestStoredId);
      return guestStoredId;
    }

    final authUser = AuthService.instance.currentUser;
    final payload = <String, dynamic>{
      'name': authUser?.name ?? _activeUser.name,
      'group_id': backendGroupId,
    };
    final email = authUser?.email;
    if (email != null && email.isNotEmpty) {
      payload['email'] = email;
    }
    final response = await _postJson('/users', payload);
    final voterId = (response['id'] as num?)?.round();
    if (voterId == null) {
      throw StateError('Backend did not return a voter user id.');
    }

    await prefs.setInt(guestPrefsKey, voterId);
    _backendVoterUserIdByGroupId[backendGroupId] = voterId;
    _activeUser = _activeUser.copyWith(id: voterId);
    return voterId;
  }

  Future<void> _syncVotesToBackend(List<Vote> votes) async {
    final activeGroup = _activeGroup;
    if (activeGroup == null || votes.isEmpty) {
      return;
    }

    var backendGroupId = await _ensureBackendGroupId(activeGroup);
    if (backendGroupId == null) {
      await _syncGroupToBackend(activeGroup);
      backendGroupId = await _ensureBackendGroupId(activeGroup);
    }
    // #region agent log
    _debugIngest('api_service.dart:_syncVotesToBackend', 'vote sync attempt', {
      'hypothesisId': 'B,D',
      'backendGroupId': backendGroupId,
      'votePayload': votes.map((v) => v.toJson()).toList(),
      'localDestinationIds': activeGroup.destinations.map((d) => d.id).toList(),
    });
    // #endregion
    if (backendGroupId == null) {
      throw StateError('Active group is not synced to the backend.');
    }

    final voterUserId = await _resolveBackendVoterUserId(backendGroupId);

    final response = await _postJson(ApiEndpoints.voteBatch, {
      'votes': votes
          .map(
            (vote) => {
              ...vote.toJson(),
              'user_id': voterUserId,
              'group_id': backendGroupId,
            },
          )
          .toList(),
    });
    // Debug: verify saved vote payload from JSON backend.
    // ignore: avoid_print
    print('TravelPick saved votes: $response');
    _backendVotesSynced = true;
    // #region agent log
    _debugIngest('api_service.dart:_syncVotesToBackend', 'vote sync ok', {
      'hypothesisId': 'A,B',
      'runId': 'post-fix',
      'response': response,
    });
    // #endregion
  }

  Future<ResultsSnapshot?> _fetchBackendResults() async {
    final activeGroup = _activeGroup;
    if (activeGroup == null) {
      return null;
    }

    var backendGroupId = await _ensureBackendGroupId(activeGroup);
    if (backendGroupId == null) {
      return null;
    }

    try {
      final data = await _getJson('${ApiEndpoints.results}/$backendGroupId');
      // Debug: verify summary payload includes recently saved votes.
      // ignore: avoid_print
      print('TravelPick fetched summary: $data');
      final breakdown = data['breakdown'] as List<dynamic>? ?? const [];
      final destinationsById = {
        for (final destination in activeGroup.destinations)
          destination.id: destination,
      };

      final ranking =
          breakdown.map((entry) {
            final row = entry as Map<String, dynamic>;
            final destinationId = (row['destination_id'] as num).round();
            final destination =
                destinationsById[destinationId] ?? Destination.fromJson(row);
            final rawDistribution =
                row['weight_distribution'] as Map<String, dynamic>? ??
                <String, dynamic>{};
            final distribution = rawDistribution.map(
              (key, value) => MapEntry(int.parse(key), (value as num).round()),
            );

            return DestinationResult(
              destination: destination,
              totalScore: (row['total_score'] as num? ?? 0).round(),
              voteCount: (row['vote_count'] as num? ?? 0).round(),
              weightDistribution: distribution,
            );
          }).toList()..sort((a, b) {
            final scoreCompare = b.totalScore.compareTo(a.totalScore);
            if (scoreCompare != 0) {
              return scoreCompare;
            }
            return a.destination.name.compareTo(b.destination.name);
          });

      final totalVotes = (data['total_votes'] as num? ?? 0).round();
      final snapshot = ResultsSnapshot(
        ranking: List<DestinationResult>.unmodifiable(ranking),
        totalVotes: totalVotes,
        voterCount: totalVotes > 0 ? totalVotes : _countBackendVoters(breakdown),
        expectedVoters: expectedVoters,
      );
      // #region agent log
      _debugIngest('api_service.dart:_fetchBackendResults', 'backend snapshot', {
        'hypothesisId': 'C',
        'totalVotes': snapshot.totalVotes,
        'rankingCount': snapshot.ranking.length,
      });
      // #endregion
      return snapshot;
    } catch (error) {
      // #region agent log
      _debugIngest('api_service.dart:_fetchBackendResults', 'fetch failed', {
        'hypothesisId': 'D',
        'error': error.toString(),
      });
      // #endregion
      return null;
    }
  }

  int _countBackendVoters(List<dynamic> breakdown) {
    var highestVoteCount = 0;
    for (final entry in breakdown.whereType<Map<String, dynamic>>()) {
      final voteCount = (entry['vote_count'] as num? ?? 0).round();
      highestVoteCount = max(highestVoteCount, voteCount);
    }
    return highestVoteCount;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 6));
    return _decodeJsonResponse(response);
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await http
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 6));
    return _decodeJsonResponse(response);
  }

  void _debugIngest(String location, String message, Map<String, dynamic> data) {
    // #region agent log
    final payload = {
      'sessionId': 'cbf8a0',
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'runId': data['runId'] ?? 'post-fix-2',
    };
    if (!kIsWeb) {
      try {
        debug_log_io.appendDebugLog(payload);
      } catch (_) {}
    }
    http
        .post(
          Uri.parse(
            'http://127.0.0.1:7404/ingest/393fcb21-0b7e-44b8-a6f5-8ab9ed209338',
          ),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': 'cbf8a0',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 2))
        .catchError((_) => http.Response('', 500));
    // #endregion
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] as String? ?? response.reasonPhrase
          : response.reasonPhrase;
      throw StateError(message ?? 'Request failed');
    }
    return decoded as Map<String, dynamic>;
  }
}
