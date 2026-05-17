import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/app_page_route.dart';
import '../widgets/destination_card.dart';
import 'voting_screen.dart';

class DestinationListScreen extends StatefulWidget {
  const DestinationListScreen({this.group, super.key});

  static const routeName = '/destinations';

  final CreatedGroup? group;

  @override
  State<DestinationListScreen> createState() => _DestinationListScreenState();
}

class _DestinationListScreenState extends State<DestinationListScreen> {
  late final Future<List<Destination>> _destinationsFuture;

  @override
  void initState() {
    super.initState();
    final group = widget.group ?? ApiService.instance.activeGroup;
    if (group != null) {
      ApiService.instance.setActiveGroup(group);
    }
    _destinationsFuture = ApiService.instance.fetchDestinations(group: group);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group ?? ApiService.instance.activeGroup;
    final groupName = group?.name ?? ApiService.instance.activeUser.groupName;
    final groupCode = group?.code ?? ApiService.instance.activeUser.groupCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group != null ? group.name : 'Suggested Destinations',
        ),
      ),
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

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    sliver: SliverToBoxAdapter(
                      child: AnimatedReveal(
                        child: _GroupHeader(
                          groupName: groupName,
                          groupCode: groupCode,
                          destinationCount: destinations.length,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverGrid.builder(
                      itemCount: destinations.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisExtent: 292,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemBuilder: (context, index) {
                        return AnimatedReveal(
                          delay: Duration(milliseconds: 80 * index),
                          child: DestinationCard(
                            destination: destinations[index],
                            onTap: () {
                              pushAppPage(
                                context,
                                VotingScreen(destinations: destinations),
                              );
                            },
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
            return ElevatedButton.icon(
              onPressed: !snapshot.hasData
                  ? null
                  : () {
                      pushAppPage(
                        context,
                        VotingScreen(destinations: snapshot.data!),
                      );
                    },
              icon: const Icon(Icons.how_to_vote_rounded),
              label: const Text('Vote Now'),
            );
          },
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.groupName,
    required this.groupCode,
    required this.destinationCount,
  });

  final String groupName;
  final String groupCode;
  final int destinationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.group_rounded,
                  color: AppTheme.deepTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Group code $groupCode',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$destinationCount destination${destinationCount == 1 ? '' : 's'} in this group. Assign weights: 3 = dream pick, 2 = strong option, 1 = still in the mix.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
