import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/group.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/app_page_route.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({
    this.embedded = false,
    this.onRequestCreateTab,
    this.onGroupDeleted,
    super.key,
  });

  static const routeName = '/my-groups';

  final bool embedded;
  final VoidCallback? onRequestCreateTab;
  final void Function(CreatedGroup group)? onGroupDeleted;

  @override
  State<MyGroupsScreen> createState() => MyGroupsScreenState();
}

class MyGroupsScreenState extends State<MyGroupsScreen> {
  late Future<List<CreatedGroup>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    _groupsFuture = ApiService.instance.fetchMyGroups();
  }

  Future<void> _refresh() async {
    setState(_loadGroups);
    await _groupsFuture;
  }

  Future<void> refreshGroups() => _refresh();

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group code copied.')),
    );
  }

  void _openGroup(CreatedGroup group) {
    ApiService.instance.setActiveGroup(group);
    pushAppPage(context, GroupDetailsScreen(group: group));
  }

  Future<void> _confirmDeleteGroup(CreatedGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Delete group?'),
          content: Text(
            'Remove "${group.name}" from your groups? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final deleted = await ApiService.instance.deleteGroup(group.id);
    if (!mounted) {
      return;
    }

    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this group.')),
      );
      return;
    }

    widget.onGroupDeleted?.call(group);
    await _refresh();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${group.name}" was deleted.')),
    );
  }

  void _goToCreateTab() {
    if (widget.embedded && widget.onRequestCreateTab != null) {
      widget.onRequestCreateTab!();
      return;
    }
    pushAppPage(context, const CreateGroupScreen());
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: AnimatedReveal(
              child: _Header(
                onBack: () => Navigator.of(context).pop(),
                onCreate: () async {
                  await pushAppPage(context, const CreateGroupScreen());
                  if (mounted) {
                    await _refresh();
                  }
                },
              ),
            ),
          ),
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              'Your private and joined groups',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        SizedBox(height: widget.embedded ? 12 : 16),
              Expanded(
                child: FutureBuilder<List<CreatedGroup>>(
                  future: _groupsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final groups = snapshot.data ?? const <CreatedGroup>[];

                    if (groups.isEmpty) {
                      return AnimatedReveal(
                        delay: const Duration(milliseconds: 100),
                        child: _EmptyState(
                          onCreate: () async {
                            if (widget.embedded) {
                              _goToCreateTab();
                              return;
                            }
                            await pushAppPage(
                              context,
                              const CreateGroupScreen(),
                            );
                            if (mounted) {
                              await _refresh();
                            }
                          },
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
                            delay: Duration(milliseconds: 70 * index),
                            child: _GroupCard(
                              group: group,
                              onOpen: () => _openGroup(group),
                              onCopyCode: () => _copyCode(context, group.code),
                              onDelete: () => _confirmDeleteGroup(group),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.explorerGradient(),
        child: SafeArea(child: content),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onCreate});

  final VoidCallback onBack;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            TextButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, color: AppTheme.coral),
              label: const Text(
                'Create Group',
                style: TextStyle(
                  color: AppTheme.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'My Groups',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'View and manage groups you created or joined.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onOpen,
    required this.onCopyCode,
    required this.onDelete,
  });

  final CreatedGroup group;
  final VoidCallback onOpen;
  final VoidCallback onCopyCode;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  group.privacyMode == PrivacyMode.private
                      ? Icons.lock_rounded
                      : Icons.public_rounded,
                  color: AppTheme.deepTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.privacyMode.label} · ${group.formattedCreatedDate}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.tag_rounded,
            label: 'Group Code',
            value: group.code,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.place_rounded,
            label: 'Destinations',
            value:
                '${group.destinationCount} selected',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Group'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopyCode,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy Code'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete Group'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC0392B),
                side: const BorderSide(color: Color(0xFFF0C4C4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.teal),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.cardDecoration(radius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.paleMint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 38,
                  color: AppTheme.teal,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No groups yet',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'You haven\'t created any groups yet. Tap \'Create Group\' to start!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
