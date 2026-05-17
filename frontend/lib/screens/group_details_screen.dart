import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/group.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/app_page_route.dart';
import '../widgets/destination_card.dart';
import 'destination_list.dart';
import 'home_screen.dart';
import 'results_screen.dart';
import 'voting_screen.dart';

class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({required this.group, super.key});

  static const routeName = '/group-details';

  final CreatedGroup group;

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: group.code));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group code copied.')),
    );
  }

  void _openDestinations(BuildContext context) {
    ApiService.instance.setActiveGroup(group);
    pushAppPage(
      context,
      DestinationListScreen(group: group),
    );
  }

  void _openVoting(BuildContext context) {
    ApiService.instance.setActiveGroup(group);
    pushAppPage(
      context,
      VotingScreen(destinations: group.destinations),
    );
  }

  void _openResults(BuildContext context) {
    ApiService.instance.setActiveGroup(group);
    pushAppPage(context, const ResultsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final votingComplete = group.hasUserVoted;

    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.explorerGradient(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: AnimatedReveal(
                    child: _Header(
                      onBack: () => Navigator.of(context).pop(),
                      onCopyCode: () => _copyCode(context),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: AnimatedReveal(
                    delay: const Duration(milliseconds: 80),
                    child: _GroupSummaryCard(group: group),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: AnimatedReveal(
                    delay: const Duration(milliseconds: 120),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openDestinations(context),
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('Browse Destination Shortlist'),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: AnimatedReveal(
                    delay: const Duration(milliseconds: 140),
                    child: _VotingStatusCard(
                      votingComplete: votingComplete,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: AnimatedReveal(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Selected Destinations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              if (group.destinations.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.paleMint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'No destinations in this group yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverGrid.builder(
                    itemCount: group.destinations.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisExtent: 292,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      final destination = group.destinations[index];
                      return AnimatedReveal(
                        delay: Duration(milliseconds: 60 * index),
                        child: DestinationCard(
                          destination: destination,
                          onTap: () => _openVoting(context),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: votingComplete
                    ? () => _openResults(context)
                    : () => _openVoting(context),
                icon: Icon(
                  votingComplete
                      ? Icons.bar_chart_rounded
                      : Icons.how_to_vote_rounded,
                ),
                label: Text(
                  votingComplete ? 'View Results' : 'Continue Voting',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        AppPageRoute(child: const HomeScreen()),
                        (_) => false,
                      );
                    },
                    child: const Text('My Groups'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        AppPageRoute(child: const HomeScreen()),
                        (_) => false,
                      );
                    },
                    child: const Text('Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onCopyCode});

  final VoidCallback onBack;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.deepTeal,
            fixedSize: const Size(46, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const Spacer(),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.deepTeal,
            fixedSize: const Size(46, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          tooltip: 'Copy code',
          onPressed: onCopyCode,
          icon: const Icon(Icons.copy_rounded),
        ),
      ],
    );
  }
}

class _GroupSummaryCard extends StatelessWidget {
  const _GroupSummaryCard({required this.group});

  final CreatedGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: group.privacyMode == PrivacyMode.private
                    ? Icons.lock_rounded
                    : Icons.public_rounded,
                label: group.privacyMode.label,
              ),
              _Chip(
                icon: Icons.calendar_today_rounded,
                label: group.formattedCreatedDate,
              ),
              _Chip(
                icon: Icons.place_rounded,
                label: '${group.destinationCount} destinations',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.paleMint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.tag_rounded, color: AppTheme.teal, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Group Code',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  group.code,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.deepTeal,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            group.privacyMode.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.mint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.teal),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _VotingStatusCard extends StatelessWidget {
  const _VotingStatusCard({
    required this.votingComplete,
  });

  final bool votingComplete;

  @override
  Widget build(BuildContext context) {
    final progress = votingComplete ? 1.0 : 0.0;

    final statusLabel = votingComplete
        ? 'Your votes are submitted!'
        : 'Cast your votes to help choose';

    final statusIcon = votingComplete
        ? Icons.check_circle_rounded
        : Icons.pending_actions_rounded;

    final statusColor = votingComplete ? AppTheme.teal : AppTheme.coral;

    final description = votingComplete
        ? 'Your choices have been successfully recorded.'
        : 'Assign weights to short-listed destinations.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voting Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppTheme.line,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
