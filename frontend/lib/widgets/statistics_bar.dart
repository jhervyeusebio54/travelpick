import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../theme.dart';

/// A ranked destination entry for the statistics bar.
class StatEntry {
  const StatEntry({
    required this.destination,
    required this.localScore,
    required this.groupScore,
  });

  final Destination destination;

  /// The current user's contribution to this destination's score.
  final int localScore;

  /// The combined score from all group members.
  final int groupScore;

  int get totalScore => groupScore + localScore;
}

class StatisticsBar extends StatelessWidget {
  const StatisticsBar({required this.entries, super.key});

  final List<StatEntry> entries;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final maxScore =
        sorted.isEmpty ? 1 : sorted.first.totalScore.clamp(1, double.infinity).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.coral.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.leaderboard_rounded,
                  color: AppTheme.coral,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Rankings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Updates as you vote',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final (index, entry) in sorted.indexed) ...[
            _StatRow(
              rank: index + 1,
              entry: entry,
              maxScore: maxScore,
            ),
            if (index != sorted.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.rank,
    required this.entry,
    required this.maxScore,
  });

  final int rank;
  final StatEntry entry;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final fraction = maxScore == 0 ? 0.0 : entry.totalScore / maxScore;
    final isTop = rank == 1;
    final barColor = isTop ? AppTheme.coral : AppTheme.teal;

    final rankEmoji = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                rankEmoji,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Expanded(
              child: Text(
                entry.destination.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isTop ? AppTheme.coral : AppTheme.ink,
                    ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                key: ValueKey(entry.totalScore),
                '${entry.totalScore} pts',
                style: TextStyle(
                  color: barColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * fraction,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: isTop
                          ? [AppTheme.coral, Color(0xFFFF9E8C)]
                          : [AppTheme.deepTeal, AppTheme.teal],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
