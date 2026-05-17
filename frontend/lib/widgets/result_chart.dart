import 'package:flutter/material.dart';

import '../models/vote.dart';
import '../theme.dart';

class ResultChart extends StatelessWidget {
  const ResultChart({required this.results, super.key});

  final List<DestinationResult> results;

  @override
  Widget build(BuildContext context) {
    final maxScore = results.isEmpty
        ? 1
        : results
              .map((result) => result.totalScore)
              .reduce((value, element) => value > element ? value : element);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppTheme.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Weighted Scoreboard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final (index, result) in results.indexed) ...[
            _ScoreBar(
              result: result,
              maxScore: maxScore,
              color: index == 0 ? AppTheme.coral : AppTheme.teal,
            ),
            if (index != results.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.result,
    required this.maxScore,
    required this.color,
  });

  final DestinationResult result;
  final int maxScore;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = maxScore == 0 ? 0.0 : result.totalScore / maxScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                result.destination.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${result.totalScore} pts',
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * percent,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.24),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
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
