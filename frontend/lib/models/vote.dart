import 'dart:math' as math;

import 'destination.dart';

class Vote {
  const Vote({
    required this.userId,
    required this.destinationId,
    required this.weight,
  });

  final int userId;
  final int destinationId;
  final int weight;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'destination_id': destinationId,
      'weight': weight,
    };
  }
}

class DestinationResult {
  const DestinationResult({
    required this.destination,
    required this.totalScore,
    required this.voteCount,
    required this.weightDistribution,
  });

  final Destination destination;
  final int totalScore;
  final int voteCount;
  final Map<int, int> weightDistribution;

  double get averageWeight {
    if (voteCount == 0) {
      return 0;
    }

    return totalScore / voteCount;
  }
}

class ResultsSnapshot {
  const ResultsSnapshot({
    required this.ranking,
    required this.totalVotes,
    required this.voterCount,
    required this.expectedVoters,
  });

  final List<DestinationResult> ranking;
  final int totalVotes;
  final int voterCount;
  final int expectedVoters;

  DestinationResult? get winner => ranking.isEmpty ? null : ranking.first;

  int get totalScore {
    return ranking.fold(0, (score, result) => score + result.totalScore);
  }

  double get consensusPercentage {
    final winningScore = winner?.totalScore ?? 0;
    if (totalScore == 0) {
      return 0;
    }

    return (winningScore / totalScore) * 100;
  }

  double get fairnessScore {
    if (ranking.length < 2 || totalScore == 0) {
      return 100;
    }

    final entropy = ranking.fold<double>(0, (value, result) {
      final share = result.totalScore / totalScore;
      if (share == 0) {
        return value;
      }

      return value - (share * math.log(share));
    });

    return (entropy / math.log(ranking.length) * 100).clamp(0, 100);
  }

  double get votingProgress {
    if (expectedVoters == 0) {
      return 0;
    }

    return (voterCount / expectedVoters).clamp(0, 1);
  }
}
