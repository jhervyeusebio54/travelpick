import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/group.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/app_page_route.dart';
import 'group_details_screen.dart';

class PublicGroupsScreen extends StatefulWidget {
  const PublicGroupsScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  State<PublicGroupsScreen> createState() => PublicGroupsScreenState();
}

class PublicGroupsScreenState extends State<PublicGroupsScreen> {
  late Future<List<CreatedGroup>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    _groupsFuture = ApiService.instance.fetchPublicGroups();
  }

  Future<void> _refresh() async {
    setState(_loadGroups);
    await _groupsFuture;
  }

  Future<void> refreshGroups() => _refresh();

  void _openGroup(CreatedGroup group) {
    ApiService.instance.setActiveGroup(group);
    pushAppPage(context, GroupDetailsScreen(group: group));
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group code copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.explorerGradient(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: AnimatedReveal(
                  child: Text(
                    'Public Groups',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            if (!widget.embedded) const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.fromLTRB(20, widget.embedded ? 8 : 0, 20, 0),
              child: Text(
                'Discover open polls from travelers around the world.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: FutureBuilder<List<CreatedGroup>>(
                future: _groupsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final groups = snapshot.data ?? const <CreatedGroup>[];

                  if (groups.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'No public groups yet. Check back soon!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppTheme.teal,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return AnimatedReveal(
                          delay: Duration(milliseconds: 60 * index),
                          child: _PublicGroupCard(
                            group: group,
                            onOpen: () => _openGroup(group),
                            onCopyCode: () => _copyCode(group.code),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicGroupCard extends StatelessWidget {
  const _PublicGroupCard({
    required this.group,
    required this.onOpen,
    required this.onCopyCode,
  });

  final CreatedGroup group;
  final VoidCallback onOpen;
  final VoidCallback onCopyCode;

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
                  color: AppTheme.coral.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.public_rounded, color: AppTheme.coral),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${group.formattedCreatedDate} · ${group.destinationCount} destinations',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Code ${group.code}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.deepTeal,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onOpen,
                  child: const Text('Open Group'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCopyCode,
                  child: const Text('Copy Code'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
