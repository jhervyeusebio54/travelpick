import 'dart:math';

import '../mock_data.dart';
import '../models/destination.dart';
import '../models/group.dart';
import '../models/user.dart';
import '../models/vote.dart';
import 'auth_service.dart';

class ApiEndpoints {
  const ApiEndpoints._();

  static const createPoll = '/create_poll';
  static const createGroup = '/create_group';
  static const generateCode = '/generate_code';
  static const addDestination = '/add_destination';
  static const submitVote = '/submit_vote';
  static const getResults = '/get_results';
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();
  static const baseUrl = 'http://127.0.0.1:8000';
  static const useMockData = true;

  final _random = Random();
  final List<CreatedGroup> _savedGroups = [];
  int _groupIdCounter = 0;

  TravelPickUser _activeUser = mockActiveUser;
  CreatedGroup? _activeGroup;
  final Map<int, int> _userWeights = {};
  bool _hasSubmittedVotes = false;

  TravelPickUser get activeUser => _activeUser;
  CreatedGroup? get activeGroup => _activeGroup;
  List<CreatedGroup> get myGroups => List<CreatedGroup>.unmodifiable(_savedGroups);
  int get expectedVoters => 1;
  int get submittedVoters => _hasSubmittedVotes ? 1 : 0;

  String? get _currentOwnerId => AuthService.instance.currentUser?.id;

  Future<List<CreatedGroup>> fetchMyGroups() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final ownerId = _currentOwnerId;
    if (ownerId == null) {
      return const [];
    }

    final groups = _savedGroups
        .where((group) => group.ownerUserId == ownerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return groups;
  }

  Future<List<CreatedGroup>> fetchPublicGroups() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final groups = _savedGroups
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
    final group = CreatedGroup(
      id: _nextGroupId(),
      name: groupName,
      code: code,
      privacyMode: privacyMode,
      destinations: selectedDestinations,
      createdAt: DateTime.now(),
      ownerUserId: ownerId,
    );

    _savedGroups.add(group);
    setActiveGroup(group);
    _hasSubmittedVotes = false;
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

  Future<TravelPickUser> joinGroup(String groupCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final normalizedCode = groupCode.trim().toUpperCase();
    final existing = findGroupByCode(normalizedCode);

    if (existing != null) {
      setActiveGroup(existing);
      return _activeUser;
    }

    final joinedGroup = CreatedGroup(
      id: _nextGroupId(),
      name: normalizedCode.contains('-') ? 'Explorer Crew' : normalizedCode,
      code: normalizedCode,
      privacyMode: PrivacyMode.private,
      destinations: List<Destination>.unmodifiable(mockDestinations),
      createdAt: DateTime.now(),
      ownerUserId: _currentOwnerId ?? 'guest',
      isCreator: false,
    );

    _savedGroups.add(joinedGroup);
    setActiveGroup(joinedGroup);
    _hasSubmittedVotes = false;
    _userWeights.clear();
    return _activeUser;
  }

  Future<List<Destination>> fetchDestinations({
    CreatedGroup? group,
    bool forceAll = false,
  }) async {
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
  }

  Future<void> submitVotes(List<Vote> votes) => submitVote(votes);

  Future<ResultsSnapshot> getResults() async {
    if (!useMockData) {
      return _getResultsRequest();
    }

    await Future<void>.delayed(const Duration(milliseconds: 320));

    final destinationPool = _activeGroup?.destinations.isNotEmpty == true
        ? _activeGroup!.destinations
        : mockDestinations;

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

    final results =
        destinationPool.map((destination) {
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
        }).toList()..sort((a, b) {
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

  Future<TravelPickUser> _createPollRequest(String groupName) {
    final payload = {'name': groupName};
    throw UnimplementedError(
      'POST $baseUrl${ApiEndpoints.createPoll} with $payload',
    );
  }

  Future<void> _submitVoteRequest(List<Vote> votes) {
    final payload = {'votes': votes.map((vote) => vote.toJson()).toList()};
    throw UnimplementedError(
      'POST $baseUrl${ApiEndpoints.submitVote} with $payload',
    );
  }

  Future<ResultsSnapshot> _getResultsRequest() {
    throw UnimplementedError('GET $baseUrl${ApiEndpoints.getResults}');
  }

  Future<CreatedGroup> _createGroupRequest({
    required String groupName,
    required PrivacyMode privacyMode,
    required List<Destination> destinations,
  }) {
    final payload = {
      'name': groupName,
      'privacy': privacyMode.apiValue,
      'destination_ids': destinations.map((destination) => destination.id),
    };
    throw UnimplementedError(
      'POST $baseUrl${ApiEndpoints.createGroup} with $payload',
    );
  }

  Future<String> _generateCodeRequest(String groupName) {
    final payload = {'name': groupName};
    throw UnimplementedError(
      'POST $baseUrl${ApiEndpoints.generateCode} with $payload',
    );
  }

  Future<void> _addDestinationRequest({
    required String groupCode,
    required Destination destination,
  }) {
    final payload = {'group_code': groupCode, 'destination_id': destination.id};
    throw UnimplementedError(
      'POST $baseUrl${ApiEndpoints.addDestination} with $payload',
    );
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
}
