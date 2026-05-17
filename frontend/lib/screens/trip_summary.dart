import 'package:flutter/material.dart';

import '../models/vote.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_reveal.dart';

class TripSummaryScreen extends StatefulWidget {
  const TripSummaryScreen({super.key});

  static const routeName = '/summary';

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  late final Future<ResultsSnapshot> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = ApiService.instance.getResults();
  }

  void _showSharedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip results are ready to share.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Summary')),
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
              if (winner == null) {
                return const Center(child: Text('No results yet.'));
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  AnimatedReveal(
                    child: _HeroSummary(result: winner, results: results),
                  ),
                  const SizedBox(height: 16),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 90),
                    child: _DescriptionCard(result: winner),
                  ),
                  const SizedBox(height: 16),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 150),
                    child: _StatsGrid(result: winner, results: results),
                  ),
                  const SizedBox(height: 16),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 220),
                    child: _NextStepsCard(
                      destinationName: winner.destination.name,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showSharedMessage,
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share Results'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showSharedMessage,
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Plan Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.result, required this.results});

  final DestinationResult result;
  final ResultsSnapshot results;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AspectRatio(
              aspectRatio: 1.55,
              child: Image.network(
                result.destination.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.teal,
                    child: const Icon(
                      Icons.landscape_rounded,
                      color: Colors.white,
                      size: 58,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.destination.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.destination.country} - ${result.destination.bestSeason}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: results.consensusPercentage / 100,
                    minHeight: 10,
                    backgroundColor: AppTheme.line,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.coral,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${results.consensusPercentage.round()}% group consensus',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.deepTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.result});

  final DestinationResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why it won', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            result.destination.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.result, required this.results});

  final DestinationResult result;
  final ResultsSnapshot results;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _StatTile(
          icon: Icons.people_alt_rounded,
          label: 'Voters',
          value: '${results.voterCount}/${results.expectedVoters}',
        ),
        _StatTile(
          icon: Icons.stacked_bar_chart_rounded,
          label: 'Average score',
          value: result.averageWeight.toStringAsFixed(1),
        ),
        _StatTile(
          icon: Icons.savings_rounded,
          label: 'Est. cost',
          value: result.destination.estimatedCost,
        ),
        _StatTile(
          icon: Icons.star_rounded,
          label: 'Travel rating',
          value: result.destination.rating.toStringAsFixed(1),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppTheme.teal),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard({required this.destinationName});

  final String destinationName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.deepTeal,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepTeal.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.route_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Next up: turn $destinationName into dates, budget, lodging, and must-do stops.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
