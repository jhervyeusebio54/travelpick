import 'package:flutter/material.dart';

import '../models/group.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/app_page_route.dart';
import '../widgets/confirm_action_dialog.dart';
import 'create_group_screen.dart';
import 'destination_list.dart';
import 'my_groups_screen.dart';
import 'public_groups_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _myGroupsKey = GlobalKey<MyGroupsScreenState>();
  final _publicGroupsKey = GlobalKey<PublicGroupsScreenState>();

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _joinGroup() async {
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Join a group'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Enter group code',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
            onSubmitted: (_) =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    if (code == null || code.isEmpty || !mounted) {
      return;
    }

    final groupInfo = await ApiService.instance.fetchGroupByCode(code);
    if (!mounted) {
      return;
    }

    if (groupInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group not found. Check the code and try again.')),
      );
      return;
    }

    final groupName = groupInfo['name'] as String? ?? 'this group';
    final groupCode = groupInfo['code'] as String? ?? code;
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Join group?',
      message: 'Are you sure you want to join "$groupName" ($groupCode)?',
      confirmLabel: 'Join',
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ApiService.instance.joinGroup(code);
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    pushAppPage(context, const DestinationListScreen());
  }

  void _onGroupCreated(CreatedGroup group) {
    setState(() {
      _selectedIndex =
          group.privacyMode == PrivacyMode.public ? 1 : 0;
    });
    _myGroupsKey.currentState?.refreshGroups();
    _publicGroupsKey.currentState?.refreshGroups();

    final message = group.privacyMode == PrivacyMode.public
        ? 'Public group created! It\'s now visible in Public and My Groups.'
        : 'Group created! View it in My Groups.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.explorerGradient(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.isGuest == true
                                ? 'Exploring as guest'
                                : 'Welcome back!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.displayLabel ?? 'Traveler',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (user != null && !user.isGuest)
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          if (user != null && !user.isGuest && user.groups.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            ...user.groups.map((g) {
                              return Text(
                                '• Group ID: ${g.groupId} (${g.role})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              );
                            }),
                          ]
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Join with code',
                      onPressed: _joinGroup,
                      icon: const Icon(Icons.login_rounded),
                    ),
                    IconButton(
                      tooltip: 'Log out',
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    MyGroupsScreen(
                      key: _myGroupsKey,
                      embedded: true,
                      onRequestCreateTab: () {
                        setState(() => _selectedIndex = 2);
                      },
                      onGroupDeleted: (_) {
                        _publicGroupsKey.currentState?.refreshGroups();
                      },
                    ),
                    PublicGroupsScreen(
                      key: _publicGroupsKey,
                      embedded: true,
                    ),
                    CreateGroupScreen(
                      embedded: true,
                      onGroupCreated: _onGroupCreated,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            _publicGroupsKey.currentState?.refreshGroups();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'My Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public_rounded),
            label: 'Public',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Create',
          ),
        ],
      ),
    );
  }
}
