import 'package:flutter/material.dart';

import '../models/vote.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/app_page_route.dart';
import '../widgets/result_chart.dart';
import 'trip_summary.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  static const routeName = '/results';

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final Future<ResultsSnapshot> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = ApiService.instance.getResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranked Results')),
      body: DecoratedBox(
        decoration: AppTheme.explorerGradient(),
        child: SafeArea(
          top: false,
          child: FutureBuilder<ResultsSnapshot>(
            future: _resultsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final results = snapshot.data!;
              final winner = results.winner;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                children: [
                  if (winner != null)
                    AnimatedReveal(child: _WinnerCard(result: winner)),
                  const SizedBox(height: 16),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 90),
                    child: _ConsensusRow(results: results),
                  ),
                  const SizedBox(height: 16),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 150),
                    child: ResultChart(results: results.ranking),
                  ),
                  const SizedBox(height: 16),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 210),
                    child: Text(
                      'Full Ranking',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final (index, result) in results.ranking.indexed) ...[
                    AnimatedReveal(
                      delay: Duration(milliseconds: 250 + (index * 55)),
                      child: _RankingTile(rank: index + 1, result: result),
                    ),
                    if (index != results.ranking.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: ElevatedButton.icon(
          onPressed: () {
            pushAppPage(context, const TripSummaryScreen());
          },
          icon: const Icon(Icons.map_rounded),
          label: const Text('View Trip Summary'),
        ),
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.result});

  final DestinationResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: AppTheme.cardDecoration(radius: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              result.destination.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppTheme.teal);
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    AppTheme.deepTeal.withValues(alpha: 0.86),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.coral,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Winning Destination',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.destination.name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.destination.country} - ${result.totalScore} weighted points',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsensusRow extends StatelessWidget {
  const _ConsensusRow({required this.results});

  final ResultsSnapshot results;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.diversity_3_rounded,
            label: 'Consensus',
            value: '${results.consensusPercentage.round()}%',
            tint: AppTheme.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.balance_rounded,
            label: 'Fairness',
            value: '${results.fairnessScore.round()}%',
            tint: AppTheme.coral,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.rank, required this.result});

  final int rank;
  final DestinationResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppTheme.coral.withValues(alpha: 0.14)
                  : AppTheme.mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank == 1 ? AppTheme.coral : AppTheme.deepTeal,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.destination.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${result.voteCount} voters - ${result.averageWeight.toStringAsFixed(1)} avg weight',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            '${result.totalScore}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
