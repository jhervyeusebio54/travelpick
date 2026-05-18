import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/vote.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/app_page_route.dart';
import '../widgets/destination_vote_card.dart';
import '../widgets/statistics_bar.dart';
import 'results_screen.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({this.destinations, super.key});

  static const routeName = '/vote';

  final List<Destination>? destinations;

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  late final Future<List<Destination>> _destinationsFuture;

  /// Weight assigned to each destination (by id). Default = 2.
  final Map<int, int> _weights = {};

  /// Set of destination ids the user has individually voted for.
  final Set<int> _votedIds = {};

  bool _isSubmitting = false;

  // ─── Derived helpers ──────────────────────────────────────────────────────

  /// Compute live stat entries using only user's local votes.
  List<StatEntry> _buildStatEntries(List<Destination> destinations) {
    return destinations.map((destination) {
      final localScore = _votedIds.contains(destination.id)
          ? _weights[destination.id] ?? 2
          : 0;
      return StatEntry(
        destination: destination,
        localScore: localScore,
        groupScore: 0,
      );
    }).toList();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _toggleVote(Destination destination) {
    setState(() {
      if (_votedIds.contains(destination.id)) {
        _votedIds.remove(destination.id);
      } else {
        _votedIds.add(destination.id);
      }
    });
  }

  Future<void> _submitAll(List<Destination> destinations) async {
    setState(() => _isSubmitting = true);

    final user = ApiService.instance.activeUser;
    final votes = destinations
        .where((destination) => _votedIds.contains(destination.id))
        .map(
          (destination) => Vote(
            userId: user.id,
            destinationId: destination.id,
            weight: _weights[destination.id] ?? 2,
          ),
        )
        .toList(growable: false);
    if (votes.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one destination first.')),
      );
      return;
    }

    try {
      // Set the destinations being voted on so results can use them
      ApiService.instance.setVotingDestinations(destinations);
      await ApiService.instance.submitVote(votes);
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votes could not be saved. Check the backend server.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);
    pushAppPage(context, const ResultsScreen());
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.destinations != null && widget.destinations!.isNotEmpty) {
      _destinationsFuture = Future.value(widget.destinations!);
    } else {
      _destinationsFuture = ApiService.instance.fetchDestinations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cast Your Votes')),
      body: DecoratedBox(
        decoration: AppTheme.explorerGradient(),
        child: SafeArea(
          top: false,
          child: FutureBuilder<List<Destination>>(
            future: _destinationsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final destinations = snapshot.data!;

              // Seed weights on first build
              for (final destination in destinations) {
                _weights.putIfAbsent(destination.id, () => 2);
              }

              final statEntries = _buildStatEntries(destinations);
              final votedCount = _votedIds.length;
              final totalCount = destinations.length;

              return CustomScrollView(
                slivers: [
                  // ── Header panel ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: AnimatedReveal(
                        child: _HeaderPanel(
                          votedCount: votedCount,
                          totalCount: totalCount,
                        ),
                      ),
                    ),
                  ),

                  // ── Statistics bar ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: AnimatedReveal(
                        delay: const Duration(milliseconds: 80),
                        child: StatisticsBar(entries: statEntries),
                      ),
                    ),
                  ),

                  // ── Section title ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                      child: AnimatedReveal(
                        delay: const Duration(milliseconds: 130),
                        child: Row(
                          children: [
                            Text(
                              'Your Votes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(width: 10),
                            _CountPill(current: votedCount, total: totalCount),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Destination cards ─────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList.separated(
                      itemCount: destinations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final destination = destinations[index];
                        final isVoted = _votedIds.contains(destination.id);
                        return AnimatedReveal(
                          delay: Duration(milliseconds: 160 + 55 * index),
                          child: DestinationVoteCard(
                            destination: destination,
                            weight: _weights[destination.id] ?? 2,
                            isVoted: isVoted,
                            isSubmitting: _isSubmitting,
                            onWeightChanged: (value) {
                              setState(() => _weights[destination.id] = value);
                            },
                            onVote: () => _toggleVote(destination),
                          ),
                        );
                      },
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
        child: FutureBuilder<List<Destination>>(
          future: _destinationsFuture,
          builder: (context, snapshot) {
            final destinations = snapshot.data;
            return Row(
              children: [
                // ── View Results (outline) ─────────────────────────────────
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting || destinations == null
                        ? null
                        : () => pushAppPage(context, const ResultsScreen()),
                    icon: const Icon(Icons.bar_chart_rounded, size: 20),
                    label: const Text('View Results'),
                  ),
                ),
                const SizedBox(width: 12),
                // ── Submit Votes (filled) ─────────────────────────────────
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting || destinations == null
                        ? null
                        : () => _submitAll(destinations),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: const Text('Submit Votes'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Panel
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.votedCount, required this.totalCount});

  final int votedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0
        ? 0.0
        : (votedCount / totalCount).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.coral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.how_to_vote_rounded,
                  color: AppTheme.coral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cast Your Votes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Vote for your preferred destinations. Your choices are saved temporarily until submitted.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Vote counter (dynamic)
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: AppTheme.teal,
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  key: ValueKey(votedCount),
                  'You\'ve voted for $votedCount of $totalCount destinations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppTheme.line,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Count Pill
// ─────────────────────────────────────────────────────────────────────────────

class _CountPill extends StatelessWidget {
  const _CountPill({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final done = current == total && total > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: done
            ? AppTheme.teal.withValues(alpha: 0.14)
            : AppTheme.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$current/$total',
        style: TextStyle(
          color: done ? AppTheme.teal : AppTheme.coral,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
